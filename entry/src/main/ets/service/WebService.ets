import {
  DeviceModel,
  ErrorMessage,
  MulticastModel,
  PrepareTransferModel,
  PrepareUploadModel,
  ReceiveResultAction,
  ReceiveResultActionType
} from '../model';
import { socket } from '@kit.NetworkKit';
import { Errors, logger, Strings } from 'common';
import { JSON } from '@kit.ArkTS';
import { BusinessError, emitter } from '@kit.BasicServicesKit';
import { Keys } from '../constant';
import { WebClient } from './WebClient';
import { DeviceProvider } from '../utils';
import { EventBus, EventType, PrepareUploadEvent } from '../eventbus';
import { FileProvider } from '../utils/FileProvider';
import { FileReceptionService } from './FileReceptionService';
import { createHttpServer, HttpError, HttpExchange, HttpServer } from 'serve';
import { FlushService } from './flush/FlushService';

const TAG: string = "WebService"


export class WebService {
  udp: socket.MulticastSocket = socket.constructMulticastSocketInstance();
  server: HttpServer = createHttpServer()

  isRunning: boolean = false
  filesDir: string = ''
  alias: string = ''
  port: number = 53317
  multicast: string = '224.0.0.167'

  constructor(alias: string) {
    this.alias = alias
  }

  setFilesSaveDir(filesDir: string) {
    this.filesDir = filesDir
  }

  async start(): Promise<void> {
    try {
      this.port = AppStorage.get(Keys.PORT) || 53317
      this.multicast = AppStorage.get(Keys.MULTICAST_ADDRESS) || '224.0.0.167'

      await this.udp.addMembership({ address: this.multicast, port: this.port })
      logger.info(TAG, `>>>--- UDP 组播已添加 -> Running: ${this.multicast}:${this.port}`)
      this.udp.on("listening", () => {
        logger.info(TAG, `---<<< UDP  -> listening`);
      })
      this.udp.on('close', () => {
        logger.info(TAG, `---<<< UDP  -> close`);
      })
      this.udp.on('message', (info: socket.SocketMessageInfo) => {
        let message = Strings.buf2String(info.message)
        let device: DeviceModel = JSON.parse(message) as DeviceModel
        if (device && device.fingerprint != DeviceProvider.getDeviceFingerprint() && device.announce == true) {
          device.hostname = info.remoteInfo.address
          DeviceProvider.addOrReplaceDevice(device)
          logger.info(TAG, '<<<---UDP received message: ' + JSON.stringify(device));
          WebClient.register(device)
        }
      })
      const isRunning = await this.server.bind({ address: '0.0.0.0', port: this.port })
        .get('/', this.index)
        .get('/api/localsend/v1/info', this.info)
        .post('/api/localsend/v2/register', this.register)
        .post('/api/localsend/v2/prepare-upload', this.prepareUpload)
        .post('/api/localsend/v2/upload', async (exchange: HttpExchange) => {
          await this.upload(exchange)
        })
        .post('/api/localsend/v2/cancel', this.cancel)
        .post('/api/localsend/v2/download', this.download)
        .start()
      AppStorage.setOrCreate(Keys.SERVICE_IS_ONLINE, isRunning)
      this.isRunning = isRunning
      this.scanOtherDevice()
      logger.info(TAG, `WebService start. isRunning: ${isRunning}`)
    } catch (e) {
      logger.error(TAG, `Web服务启动失败: ${Errors.getErrorMessage(e)}`)
      return Promise.reject(HttpError.error(500, 'Server startup failed'))
    }
  }

  async stop(): Promise<void> {
    this.isRunning = false
    try {
      this.udp.off("message")
      await this.server.stop()
      await this.udp.dropMembership({ address: this.multicast, port: this.port })
      await this.udp.close()
      logger.info(TAG, `WebService stoped!`)
    } catch (e) {
      logger.warn(TAG, `WebService stop error: ${Errors.getErrorMessage(e)}`)
    } finally {
      AppStorage.set(Keys.SERVICE_IS_ONLINE, false)
    }
  }

  scanOtherDevice() {
    const address: socket.NetAddress = { address: this.multicast, port: this.port }
    let options: socket.UDPSendOptions = {
      data: JSON.stringify(new MulticastModel(true)),
      address: address
    }
    this.udp.send(options, (err: BusinessError) => {
      if (err) {
        logger.error(TAG, "--->>> UDP 组播失败 %s", JSON.stringify(err))
      } else {
        logger.error(TAG, "--->>> UDP 组播已发送 %s", JSON.stringify(options))
      }
    })
  }

  private index(exchange: HttpExchange) {
    const headers: Map<string, string> = exchange.getRequestHeaders().getAllHeaders()
    logger.info(TAG, `request headers: ${JSON.stringify([headers.entries()])}`)
    exchange.end('HelloWorld')
  }

  private info(exchange: HttpExchange) {
    if (exchange.isEnd) {
      logger.info(TAG, "<<<--- info")
      exchange.writeJson(new MulticastModel(false))
    }
  }

  private register(exchange: HttpExchange) {
    logger.info(TAG, "<<<--- register isEnd: " + exchange.isEnd)
    if (exchange.isEnd) {
      const device: DeviceModel = exchange.getRequestJsonBody() as DeviceModel
      device.hostname = exchange.getRemoteAddress()?.address || ''
      logger.info(TAG, "<<<--- register: " + JSON.stringify(device))
      DeviceProvider.addOrReplaceDevice(device)
      exchange.writeJson(new MulticastModel())
    }
  }

  private prepareUpload(exchange: HttpExchange) {
    if (FileProvider.isTransferringNow()) {
      exchange.setStatusCode(409).writeJson(new ErrorMessage("Blocked by another session"))
      return
    }
    const userPin: string | undefined = AppStorage.get(Keys.USE_PIN_WHEN_RECEIVE)
    if (userPin) {
      const pin: string = exchange.getQueryParams('pin')
      if (pin != userPin) {
        exchange.setStatusCode(401).writeJson(new ErrorMessage("PIN required / Invalid PIN"))
        return
      }
    }
    if (exchange.isEnd) {
      const body: PrepareUploadModel = exchange.getRequestJsonBody<PrepareUploadModel>()
      logger.info(TAG, `<<<--- prepare-upload ${exchange.getRequestURI()} body:${JSON.stringify(body)}`)
      if (!body) {
        exchange.setStatusCode(400).writeJson(new ErrorMessage('Invalid body'))
        return
      }
      if (Object.keys(body.files).length == 0) {
        exchange.setStatusCode(400).writeJson(new ErrorMessage('Request must contain at least one file'))
        return
      }
      EventBus.getInstance().once(EventType.RECEIVE_SEND_REQUEST_ACTION, (eventData: emitter.EventData) => {
        const data = eventData.data as ReceiveResultAction
        if (data) {
          if (data.action == ReceiveResultActionType.ACCEPT) {
            new Promise<PrepareTransferModel>((resolve, reject) => {
              try {
                const prepare: PrepareUploadModel = exchange.getRequestJsonBody() as PrepareUploadModel
                const result: PrepareTransferModel = FileReceptionService.getPrepareReceptionData(prepare)
                FileProvider.addFilesToReceiveQueue(prepare, result, exchange.getRemoteAddress()?.address || '')
                FileProvider.setTransferringNowSessionId(result.sessionId)
                resolve(result)
              } catch (e) {
                reject(e)
              }
            }).then((result) => exchange.writeJson(result))
              .catch(() => {
                exchange.setStatusCode(data.code || 500).writeJson(new ErrorMessage("Unknown error by receiver"))
                FileProvider.clearFilesReceiveQueue()
              })
          } else if (data.action == ReceiveResultActionType.REJECT) {
            exchange.setStatusCode(403).writeJson(new ErrorMessage("File request declined by recipient"))
          } else if (data.action == ReceiveResultActionType.COMPLETE) {
            exchange.setStatusCode(204).writeJson(new ErrorMessage())
          } else {
            exchange.setStatusCode(data.code || 500).writeJson(new ErrorMessage("Unknown error by receiver"))
          }
        } else {
          logger.error('WebService', `prepareUpload: event data is null ${JSON.stringify(eventData.data)}`)
          exchange.setStatusCode(500).writeJson(new ErrorMessage("Unknown error by receiver"))
        }
        EventBus.getInstance().unregister(EventType.RECEIVE_SEND_REQUEST_ACTION)
      })
      EventBus.getInstance().post(EventType.RECEIVE_SEND_REQUEST, PrepareUploadEvent(body))
    }
  }

  private async upload(exchange: HttpExchange) {
    logger.info(TAG, `<<<--- upload isEnd: ${exchange.isEnd} headers: ${exchange.getRequestHeaders().toJson()}`)
    const isReceivingFiles = FileProvider.isTransferringNow()
    //当前位处于接收文件状态，直接调用了upload接口
    if (!isReceivingFiles) {
      exchange.setStatusCode(403).writeJson(new ErrorMessage("Invalid token or IP address"))
      return
    }
    const sessionId = exchange.getQueryParams('sessionId')
    //sessionId未传
    if (!sessionId) {
      exchange.setStatusCode(400).writeJson(new ErrorMessage("Missing parameters"))
      return
    }
    //当前正在接收文件但不是发送请求的这台设备
    if (isReceivingFiles && FileProvider.getTransferringNowSessionId() !== sessionId) {
      exchange.setStatusCode(409).writeJson(new ErrorMessage("Blocked by another session"))
      return
    }
    const token = exchange.getQueryParams('token')
    if (!token) {
      exchange.setStatusCode(403).writeJson(new ErrorMessage("Invalid token or IP address"))
      return
    }
    const info = FileProvider.getReceiveFileInfo(token)
    //未找到队列指定token的文件接收信息，或当前请求IP与该token文件信息中IP不一致
    if (!info || info.remoteIp != exchange.getRemoteAddress()?.address) {
      exchange.setStatusCode(403).writeJson(new ErrorMessage('Invalid token or IP address'))
      return
    }

    if (!exchange.isEnd) {
      const flush: FlushService = new FlushService(exchange, info.file)
      EventBus.getInstance().once(EventType.UPLOAD_FILE_CANCELED, () => {
        flush.cancel()
        const target = DeviceProvider.getDevice(exchange.getRemoteAddress()?.address || '')
        if (target) {
          WebClient.cancel(target, exchange.getQueryParams('sessionId'))
          exchange.setStatusCode(409).end("Sender cancels file sending")
        }
        EventBus.getInstance().unregister(EventType.UPLOAD_FILE_CANCELED)
      })
      if (exchange.getAttribute('on-data') === undefined) {
        try {
          exchange.setAttribute('on-data', (buffer: ArrayBuffer, index: number) => {
            flush.flush({ buffer: buffer, index: index })
          })
          exchange.setAttribute('on-end', () => {
            flush.end()
          })
        } catch (e) {
          exchange.writeError((e instanceof HttpError) ? e : HttpError.error(500))
          return
        }
      }
    }
  }

  private cancel(exchange: HttpExchange) {
    if (exchange.isEnd) {
      logger.info(TAG, `<<<--- cancel sessionId: ${exchange.getQueryParams('sessionId')}`)
      EventBus.getInstance().post(EventType.UPLOAD_FILE_CANCELED)
      exchange.end()
    }
  }

  private download(exchange: HttpExchange) {
    if (exchange.isEnd) {
      logger.info(TAG, `<<<--- download: ${exchange.originalUrl}`)
      exchange.end()
    }
  }
}

