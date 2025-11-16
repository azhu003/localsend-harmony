import {
  BaseResponse,
  FileInfoKeyMap,
  FileInfoModel,
  FileTransferStatus,
  PrepareTransferModel,
  PrepareUploadModel,
  StringPair,
  TransferProgressChangedAction
} from '../model';
import { ContentType, HttpRequest, Terminator } from '../http';
import { Dates, DeviceProvider, FileProvider } from '../utils';
import { ApiConstant } from '../constant/ApiConstant';
import { Errors, logger, Objects } from 'common';
import { JSON } from '@kit.ArkTS';
import { DeviceModel } from '../model/DeviceModel';
import { UploaderServer } from './upload/UploadServer';
import { EventBus, EventType, TransferFileProgressEvent } from '../eventbus';
import { TransferException } from './upload/TransferException';

const TAG = 'WebClient'

export class WebClient {
  private static getCombinedURL(hostname: string, port: number, path: string) {
    return `http://${hostname}:${port}${path}`
  }

  /**
   * 像其他设备发送当前设备信息
   * @param alias
   * @param port
   */
  static register(target: DeviceModel) {
    if (!target.hostname) {
      logger.warn('WebClient', 'invalid hostname')
      return
    }
    const device: DeviceModel = DeviceProvider.getCurrentDevice()
    const url = WebClient.getCombinedURL(target.hostname, target.port, ApiConstant.REGISTER)
    HttpRequest.post<DeviceModel>(url, device)
      .then(resolve => {
        resolve.hostname = target.hostname
        resolve.port = target.port
        resolve.deviceType = target.deviceType
        logger.info(TAG, '--->>> 当前设备信息已发送 response: ' + JSON.stringify(resolve))
        const device = resolve as DeviceModel
        DeviceProvider.addOrReplaceDevice(device)
      }, (reason: Error) => {
        logger.info(TAG, '--->>> 发送当前设备信息失败: ' + JSON.stringify(reason) + " url: " + url)
      })
  }

  static async prepareUpload(target: DeviceModel, files: Array<FileInfoModel>, pin: string | undefined,
    callback: (term: Terminator) => void): Promise<PrepareTransferModel> {
    if (!target.hostname) {
      return Promise.reject('invalid hostname')
    }
    const filesMap: FileInfoKeyMap = {}
    for (const file of files) {
      filesMap[file.id] = Objects.clone({}, file)
      filesMap[file.id].metadata = undefined
    }
    const body: PrepareUploadModel = {
      info: DeviceProvider.getCurrentDevice(),
      files: filesMap
    }
    logger.info(TAG, `--->>> prepare-upload: ${JSON.stringify(body)}`)
    const url: string = `${WebClient.getCombinedURL(target.hostname, target.port, ApiConstant.PREPARE_UPLOAD)}${(pin) ? '?pin=' + pin : ''}`
    return await HttpRequest.post<PrepareTransferModel>(url, body, ContentType.APPLICATION_JSON, callback)
  }

  static async cancel(target: DeviceModel, sessionId: string) :Promise<void>{
    if (!target.hostname) {
      logger.info(TAG, `通知对方取消传输失败 hostname 无效, session: ${sessionId}`)
      return
    }
    try {
      const url = `${WebClient.getCombinedURL(target.hostname, target.port, ApiConstant.CANCEL)}?sessionId=${sessionId}`
      await HttpRequest.post<BaseResponse>(url, null)
      logger.info(TAG, `通知对方取消传输 OK -> session: ${sessionId}`)
    } catch (e) {
      logger.info(TAG, `通知对方取消传输失败 error: ${Errors.getErrorMessage(e)}`)
    }
  }

  static async upload(sessionId: string, target: DeviceModel, files: FileInfoModel[], fileTokens: StringPair): Promise<void> {
    if (!target.hostname) {
      throw new TransferException('invalid hostname')
    }
    const server = new UploaderServer(target.hostname, target.port, WebClient.onUploadProgressChanged)
    let isCanceled: boolean = false
    EventBus.getInstance().once(EventType.UPLOAD_FILE_CANCELED, () => {
      isCanceled = true
      server.terminate()
    })
    try {
      // let index: number = 0
      // let testPartsStart: number = 1250
      for (const pending of files) {
        if (isCanceled) {
          logger.info(TAG, `文件发送取消 id: ${pending.id}`)
          break
        }
        //接收方未选择接收该文件
        if (!fileTokens[pending.id]) {
          WebClient.onUploadProgressChanged({
            fileId: pending.id,
            status: FileTransferStatus.SKIPPED,
            progress: 0,
            total: pending.size,
            speed: 0
          })
          continue
        }
        const url = `${ApiConstant.UPLOAD}?sessionId=${sessionId}&fileId=${pending.id}&token=${fileTokens[pending.id]}`
        const parts = FileProvider.getFilePortLength(pending.size)
        // const parts = (testPartsStart + 25 * index) * 1024
        // index += 1
        // logger.info(TAG, `开始上传文件 -> 分片长度: ${partsStr} 文件大小: ${fileSize} => ${FileProvider.formatBytes(pending.size)}`)
        const start = Dates.now()
        await server.upload(parts, url, pending)
        if (!isCanceled) {
          const consumed: number = Dates.consumed(start)
          const speed = ((pending.size / (1024 * 1024)) / (consumed / 1000)).toFixed(2) //单位: MB/s
          const partsStr = `${parts / 1024} KB`
          const fileSize = FileProvider.formatBytes(pending.size)
          logger.info(TAG,
            `文件上传完成 分片长度: ${partsStr} 文件大小: ${pending.size} => ${fileSize} 上传耗时: ${consumed}ms 平均上传速度: ${speed}`)
        }
      }
    } catch (e) {
      logger.warn(TAG, `上传文件出错: ${Errors.getErrorMessage(e)}`)
    } finally {
      //延迟10ms后关闭链接，防止LocalSend接收端出现接收未完成时链接被关闭报错
      await Dates.delay(50)
      server.disconnection()
      EventBus.getInstance().unregister(EventType.UPLOAD_FILE_CANCELED)
    }
  }

  static onUploadProgressChanged(event: TransferProgressChangedAction) {
    EventBus.getInstance().post(EventType.TRANSFER_PROGRESS_CHANGED_ACTION, TransferFileProgressEvent(event))
  }
}