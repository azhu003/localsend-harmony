import { fileUri, fileIo as fs, picker } from '@kit.CoreFileKit';
import { Errors, logger } from 'common';
import { HttpError, HttpExchange } from 'serve';
import { ErrorMessage, FileInfoModel, FileTransferStatus, ReceiveRecordModel, TransferProgressChangedAction } from '../../model';
import { EventBus, EventType, TransferFileProgressEvent } from '../../eventbus';
import { ArkTSUtils } from '@kit.ArkTS';
import { Dates, DeviceProvider, FileProvider } from '../../utils';
import { FlushTask } from './FlushTask';
import { Keys } from '../../constant';
import { ReceivedRecordMapper } from '../../db/mapper/ReceiveRecordMapper';

const TAG = 'FlushService'

/**
 * 文件写入服务
 */
export class FlushService {
  private exchange: HttpExchange | null
  private writeFile: fs.File | undefined
  private isFlushing: boolean = false
  private isFinished: boolean = false
  private progress: number = 0
  private fileInfo: FileInfoModel
  private filePath: string = ''
  private queue: FlushTask[] = []
  private lock_: ArkTSUtils.locks.AsyncLock = new ArkTSUtils.locks.AsyncLock();
  private startMilli: number = 0
  private lastNoticeMilli: number = 0
  private isCanceled: boolean = false

  constructor(exchange: HttpExchange, fileInfo: FileInfoModel) {
    this.exchange = exchange
    this.fileInfo = fileInfo
    this.startMilli = Dates.now()
  }

  /**
   * 添加到文件写入队列
   * @param flush
   */
  flush(flush: FlushTask) {
    this.add(flush)
  }

  /**
   * 文件写入结束
   */
  end() {
    //因为onStream是异步执行的调用onFinish时onStream可以还未执行结束
    //这里用isFinished标记下
    this.isFinished = true
  }

  /**
   * 取消文件写入
   */
  cancel() {
    this.isCanceled = true
  }

  private async add(flush: FlushTask) {
    await this.lock_.lockAsync(() => this.queue.push(flush), ArkTSUtils.locks.AsyncLockMode.EXCLUSIVE)
    if (this.checkCancel()) {
      return
    }
    if (!this.isFlushing && !this.isCanceled) {
      this.isFlushing = true;
      this.process(this.lastNoticeMilli);
    }
  }

  private async process(lastNotice: number): Promise<void> {
    try {
      let flush: FlushTask | undefined
      await this.lock_.lockAsync(() => flush = this.queue.shift(), ArkTSUtils.locks.AsyncLockMode.EXCLUSIVE)
      if (flush) {
        //向磁盘写入
        await this.flushToDisk(flush);
        if (this.checkCancel()) {
          return
        }
        //发送文件写入进度信息
        const elapsed = Dates.consumed(lastNotice)
        if (elapsed > 200) {
          const duration = Dates.consumed(this.startMilli)
          const speed = FileProvider.getTransferSpeed(this.progress, duration)
          console.info(`speed: ${speed} duration: ${duration}`)
          this.postEvent({
            fileId: this.fileInfo.id,
            status: FileTransferStatus.TRANSFERRING,
            progress: this.progress,
            total: this.fileInfo.size,
            speed: speed
          })
          this.lastNoticeMilli = Dates.now()
        }
        //当前buffer写完成后再次检查队列
        if (this.queue.length > 0) {
          await this.process(this.lastNoticeMilli)
          return
        }
      }
    } catch (e) {
      logger.debug(TAG, `文件写入出错: ${Errors.getErrorMessage(e)}`)
      this.exchange!!.writeError(HttpError.error(500))
      this.postEvent({
        fileId: this.fileInfo.id,
        status: FileTransferStatus.ERROR,
        progress: 0,
        total: this.fileInfo.size,
        speed: 0,
        error: e
      })
      FileProvider.deleteFile(this.filePath)
    }
    this.isFlushing = false; // 任务处理完成
    if (this.isFinished) {
      this.close()
      this.exchange!!.writeJson(new ErrorMessage())
      this.postEvent({
        fileId: this.fileInfo.id,
        status: FileTransferStatus.COMPLETED,
        progress: this.fileInfo.size,
        total: this.fileInfo.size,
        speed: 0,
        filePath: this.filePath
      })
      this.toHistory()
    }
  }

  private async create(): Promise<void> {
    try {
      const documentViewPicker = new picker.DocumentViewPicker();
      const documentSaveOptions = new picker.DocumentSaveOptions();
      documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;

      const saved = await documentViewPicker.save(documentSaveOptions)
      let uri = saved[0]
      if (this.fileInfo.fileName.includes("/")) {
        let fileDirs = new fileUri.FileUri(uri + "/" + this.fileInfo.fileName.slice(0, this.fileInfo.fileName.lastIndexOf("/"))).path;
        if (!await fs.access(fileDirs, fs.AccessModeType.EXIST)) {
          console.log(`--- 文件夹不存在 准备创建文件夹: ${fileDirs}`)
          fs.mkdir(fileDirs, true)
          console.log(`--- 文件夹创建完成: ${fileDirs}`)
        }
      }
      this.filePath = new fileUri.FileUri(uri + "/" + this.fileInfo.fileName).path;
      this.writeFile = fs.openSync(this.filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      console.log(`--- 文件创建成功: ${this.filePath}`)
    } catch (e) {
      this.close()
      console.log(`--- 文件创建失败: ${this.filePath} ${Errors.getErrorMessage(e)}`)
      throw HttpError.error(500)
    }
  }


  private async flushToDisk(flush: FlushTask): Promise<number> {
    if (!this.writeFile) {
      await this.create()
    }
    let length: number = 0;
    length = fs.writeSync(this.writeFile!!.fd, flush.buffer);
    // this.stream!!.write(flush.buffer)
    if (this.checkCancel()) {
      return 0
    }
    this.progress += length
    // logger.debug(TAG, '文件写入长度: ' + flush.buffer.byteLength +
    //   ` index: ${flush.index} progress: ${flush.buffer.byteLength} 进度: ${((this.progress / this.fileInfo.size) * 100).toFixed(2)}%`)
    return length
  }

  private postEvent(event: TransferProgressChangedAction) {
    EventBus.getInstance().post(EventType.TRANSFER_PROGRESS_CHANGED_ACTION, TransferFileProgressEvent(event))
  }

  private checkCancel(): boolean {
    if (this.isCanceled) {
      this.postEvent({
        fileId: this.fileInfo.id,
        status: FileTransferStatus.CANCELED,
        progress: 0,
        total: this.fileInfo.size,
        speed: 0
      })
      FileProvider.deleteFile(this.filePath)
      return true
    }
    return false
  }

  private close() {
    if (this.writeFile) {
      try {
        fs.closeSync(this.writeFile.fd)
      } catch (e) {
        logger.warn(TAG, "closing writeFile error. " + Errors.getErrorMessage(e))
      } finally {
        this.writeFile = undefined
      }
    }
  }

  private toHistory() {
    if (AppStorage.get<boolean>(Keys.SAVE_RECEIVE_RECORD) === true) {
      const sender = DeviceProvider.getDevice(this.exchange?.getRemoteAddress()?.address || '')
      const record = new ReceiveRecordModel()
      record.fileId = this.fileInfo.id
      record.fileName = this.fileInfo.fileName
      record.fileType = this.fileInfo.fileType
      record.filePath = this.filePath
      record.size = this.fileInfo.size
      record.sender = sender?.alias || 'unknown'
      record.sendAt = Dates.now()
      const mapper = new ReceivedRecordMapper()
      mapper.insert(record)
    } else {
      console.info('当前未开启保存接收记录')
    }
  }
}