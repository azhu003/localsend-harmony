import { DialogAction, DialogHelper, SpinKit, SpinType } from '@pura/harmony-dialog';
import { Errors, logger, Screens, SizeConstant, Strings, toast } from 'common';
import { IconButton, NavigationTitle } from '../../components';
import {
  DeviceModel,
  FileInfoModel,
  FileTransferInfo,
  FileTransferStatus,
  IMoveFile,
  TransferPageParam,
  TransferProgressChangedAction
} from '../../model';
import { WebClient } from '../../service';
import { Dates, FileProvider, Routers } from '../../utils';
import { FileItem } from './FileItem';
import { EventBus, EventType } from '../../eventbus';
import { emitter } from '@kit.BasicServicesKit';
import { Keys } from '../../constant';
import { ReceivedRecordMapper } from '../../db/mapper/ReceiveRecordMapper';
import { Wapper } from 'rdbplus';

@Builder
export function TransferPageBuilder() {
  TransferPage()
}

@Component
export struct TransferPage {
  @Consume('pages') pages: NavPathStack;
  @State topPadding: Length = 0
  @State bottomPadding: Length = 0
  //总大小
  @State total: number = 0
  //总进度
  @State totalProgress: number = 0
  //当前文件传输进度
  @State progress: number = 0
  //总进度(百分比)
  @State percentage: number = 0
  //上传速度
  @State speed: number = 0
  //已完成数量
  @State completed: number = 0
  @State param: TransferPageParam = new TransferPageParam(false, [])
  @State status: Map<string, FileTransferInfo> = new Map()
  @State allCompleted: boolean = false
  //高级面板高度
  @State mTransferInfoHeight: Length = 0
  //高级面板展开/折叠中
  @State isTransferInfoChanging: boolean = false
  //高级面板是否显示
  @State isTransferInfoDisplay: boolean = false
  //高级面板动画
  mTransferInfoAnim: AnimateParam = {
    duration: 200,
    curve: Curve.Linear,
    iterations: 1,
    playMode: PlayMode.Normal,
    onFinish: () => {
      this.isTransferInfoChanging = false
    }
  }
  mMoveFileAuthorizeDialogId: string | undefined
  @State isMovingFile: boolean = false

  build() {
    NavDestination() {
      Stack() {
        NavigationTitle({
          title: this.param.isSent ? $r('app.string.sending_files') : $r('app.string.receiving_files'),
          isHideBackButton: true
        }) {
          RelativeContainer() {
            List({ space: SizeConstant.SPACE_M }) {
              ForEach(this.param.files, (item: FileInfoModel) => {
                ListItem() {
                  FileItem({ file: item, status: this.status[item.id]})
                }
              }, (item: FileInfoModel, index: number) => `${item.id}_${index}`)
              ListItem().height(this.bottomPadding)
            }
            .width('100%')
            .height('100%')
            .padding({
              left: SizeConstant.SPACE_L,
              top: this.topPadding,
              right: SizeConstant.SPACE_L,
            })
            .backgroundColor($r('app.color.background'))
            .listDirection(Axis.Vertical)

            // Text($r('app.string.save_directory', FileProvider.getDefaultFileDir(getContext(this))))
            Text($r('app.string.save_directory', '/Download/LocalSend'))
              .width('100%')
              .fontColor($r('app.color.on_background'))
              .fontSize(SizeConstant.TEXT_XL)
              .textAlign(TextAlign.Start)
              .alignRules({
                top: { anchor: "__container__", align: VerticalAlign.Top },
                start: { anchor: "__container__", align: HorizontalAlign.Start }
              })
              .margin({ left: SizeConstant.SPACE_L, right: SizeConstant.SPACE_L })
              .padding({ top: SizeConstant.SPACE_L, bottom: SizeConstant.SPACE_L })
              .visibility(this.param.isSent ? Visibility.None : Visibility.Visible)
              .onAreaChange((_: Area, newValue: Area) => {
                this.topPadding = newValue.height
              })

            // 底部传输进度
            Column() {
              Column() {
                Text(this.getTotalEstimatedTimeText())
                  .fontSize(SizeConstant.TEXT_XXL)
                  .fontColor($r('app.color.on_background'))
                  .width('100%')
                  .textAlign(TextAlign.Start)
                Blank().height(SizeConstant.SPACE_M)
                Progress({ value: this.percentage, total: 100, type: ProgressType.Linear })
                  .style({ strokeWidth: 10, enableSmoothEffect: true })
                  .color($r('app.color.primary'))

                //高级信息
                Column() {
                  Column() {
                    Blank().height(SizeConstant.SPACE_M)
                    Text($r('app.string.file_of_numbers', `${this.completed}/${this.param.files.length}`))
                      .fontSize(SizeConstant.TEXT_L)
                    Text($r('app.string.size_text',
                      `${FileProvider.formatBytes(this.totalProgress + this.progress)} / ${FileProvider.formatBytes(this.total)}`))
                      .fontSize(SizeConstant.TEXT_L)
                    Text($r('app.string.speed_text', `${FileProvider.formatBytes(this.speed)}/s`))
                      .fontSize(SizeConstant.TEXT_L)
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                  .visibility(this.isTransferInfoChanging ? Visibility.Hidden : Visibility.Visible)
                }
                .width('100%')
                .height(this.mTransferInfoHeight)
                .animation(this.mTransferInfoAnim)

                Blank().height(SizeConstant.SPACE_M)
                //高级 - 取消
                Row() {
                  IconButton({
                    icon: $r('app.media.ic_detail'),
                    text: this.isTransferInfoDisplay ? $r('app.string.hide') : $r('app.string.advanced'),
                    iconColor: $r('app.color.on_container'),
                    iconSize: SizeConstant.ICON_L,
                    arrangement: FlexDirection.Row
                  }).onClick(() => {
                    this.onTransferInfoDisplayClick()
                  })
                  Blank().width(SizeConstant.SPACE_XXL)
                  IconButton({
                    icon: this.allCompleted ? $r('app.media.ic_ok_filled') : $r('app.media.ic_cancel_filled'),
                    text: this.allCompleted ? $r('app.string.complete') : $r('app.string.cancel'),
                    iconColor: $r('app.color.on_container'),
                    iconSize: SizeConstant.ICON_L,
                    arrangement: FlexDirection.Row
                  }).onClick(() => {
                    if (this.allCompleted) {
                      FileProvider.setTransferComplete()
                      if (this.param.isSent) {
                        FileProvider.clearMediaCache(getContext(this))
                      }
                      this.pages.pop()
                    } else {
                      this.showCancelDialog()
                    }
                  })
                }
                .width('100%')
                .justifyContent(FlexAlign.End)
              }
              .margin({ left: SizeConstant.SPACE_L, right: SizeConstant.SPACE_L })
              .padding(SizeConstant.SPACE_L)
              .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN, {})
              .borderRadius(SizeConstant.RADIUS_L)
            }
            .alignRules({
              bottom: { anchor: "__container__", align: VerticalAlign.Bottom }
            })
            .padding({ bottom: Screens.getNavigationBarHeight() })
            .onAreaChange((_: Area, newValue: Area) => {
              this.bottomPadding = newValue.height
            })
          }
          .height('100%')
          .width('100%')
          .backgroundColor($r('app.color.container'))
        }

        if (this.isMovingFile) {
          Stack()
            .size({ width: '100%', height: '100%' })
            .backgroundColor($r('app.color.mask_background'))
          Column() {
            SpinKit({ spinType: SpinType.spinZ, spinColor: $r('app.color.on_container') }).align(Alignment.Center)
          }
          .padding(SizeConstant.SPACE_L)
          .borderRadius(SizeConstant.RADIUS_M)
          .backgroundColor($r('app.color.container'))
        }
      }
    }
    .height('100%')
    .width('100%')
    .hideTitleBar(true)
    .onBackPressed(() => {
      if (this.allCompleted) {
        return false
      } else {
        this.showCancelDialog()
        return true
      }
    })
  }

  aboutToAppear(): void {
    //设置正在处理文件发送请求，屏蔽掉其他文件发送请求
    FileProvider.setTransferringNow(true)
    const params: Array<TransferPageParam> = this.pages.getParamByName(Routers.TRANSFER_PAGE) as Array<TransferPageParam>
    if (params && params.length != 0) {
      this.param = params[0]
      for (const temp of this.param.files) {
        this.total += temp.size
        this.status[temp.id] = new FileTransferInfo()
        this.status[temp.id].fileId = temp.id
        this.status[temp.id].status = FileTransferStatus.QUEUE
      }
    }
    this.setTransferProgressChangedObserver()
    this.startTransfer()
  }

  aboutToDisappear(): void {
    EventBus.getInstance().unregister(EventType.TRANSFER_PROGRESS_CHANGED_ACTION)
    this.status.clear()
  }

  getTotalEstimatedTimeText(): ResourceStr {
    if (this.allCompleted) {
      this.percentage = 100
      return $r('app.string.completed')
    }
    if (!this.percentage) {
      return $r('app.string.total_progress', '-')
    } else {
      //预计剩余时间
      const estimated = Number.parseFloat(((this.total - this.totalProgress - this.progress) / this.speed).toFixed(2))
      return $r('app.string.total_progress', `${Dates.getSecondsToTime(estimated)}`)
    }
  }

  //取消提示
  showCancelDialog() {
    DialogHelper.showAlertDialog({
      title: $r('app.string.cancel_file_transfer_title'),
      content: $r('app.string.cancel_file_transfer_tips'),
      autoCancel: false,
      backCancel: false,
      alignment: DialogAlignment.Bottom,
      offset: {
        dx: 0,
        dy: -Screens.getNavigationBarHeight()
      },
      primaryButton: {
        value: $r('app.string.cancel'),
        fontColor: $r('app.color.on_container_secondary'),
      },
      secondaryButton: $r('app.string.positive'),
      onAction: (action) => {
        if (action == DialogAction.TWO) {
          EventBus.getInstance().post(EventType.UPLOAD_FILE_CANCELED)
          FileProvider.setTransferComplete()
          if (this.param.isSent) {
            FileProvider.clearMediaCache(getContext(this))
          }
          this.pages.pop()
        }
      }
    })
  }

  //上传文件
  startTransfer() {
    if (this.param.sessionId && (this.param.target || []).length > 0 && this.param.fileToken) {
      const target: DeviceModel = this.param.target!![0]
      WebClient.upload(this.param.sessionId, target, this.param.files, this.param.fileToken)
        .then(() => {
          EventBus.getInstance().post(EventType.UPLOAD_FILE_COMPLETED)
          if (this.param.isSent) {
            FileProvider.clearMediaCache(getContext(this))
          }
        })
    }
  }

  /**
   * 监听传输进度
   */
  setTransferProgressChangedObserver() {
    EventBus.getInstance().on(EventType.TRANSFER_PROGRESS_CHANGED_ACTION, (data: emitter.EventData) => {
      const action = data.data as TransferProgressChangedAction
      if (action) {
        if (action.status == FileTransferStatus.TRANSFERRING) {
          this.progress = action.progress
          this.percentage = Number.parseFloat((((this.totalProgress + action.progress) / this.total) * 100).toFixed(2))
        } else if (action.status == FileTransferStatus.COMPLETED) {
          this.progress = 0
          this.totalProgress += action.progress
        }
        if (action.speed > 0) {
          this.speed = action.speed
        }
        if (action.status != FileTransferStatus.QUEUE && action.status != FileTransferStatus.TRANSFERRING) {
          this.progress = 0
          if (this.completed < this.param.files.length) {
            this.completed += 1
          }
          if (!this.allCompleted && this.completed === this.param.files.length) {
            this.allCompleted = true
            // if (!this.param.isSent && action.status === FileTransferStatus.COMPLETED) {
            //   this.onReceiveComplete()
            // }
          }
        }
        const index = this.param.files.findIndex((info: FileInfoModel) => info.id === action.fileId)
        if (index >= 0) {
          this.status[action.fileId].status = action.status.valueOf()
          if (action.status == FileTransferStatus.TRANSFERRING) {
            this.status[action.fileId].progress = Number.parseFloat(((action.progress / action.total) * 100).toFixed(2))
          } else if (action.status == FileTransferStatus.COMPLETED) {
            this.status[action.fileId].status = action.status
            this.status[action.fileId].filePath = action.filePath
          }
        }
      }
    })
  }

  /**
   * 显示/关闭 文件传输信息
   */
  onTransferInfoDisplayClick() {
    if (this.isTransferInfoChanging) {
      return
    }
    this.isTransferInfoChanging = true
    this.isTransferInfoDisplay = !this.isTransferInfoDisplay
    if (this.isTransferInfoDisplay) {
      this.mTransferInfoHeight = 'auto'
    } else {
      this.mTransferInfoHeight = 0
    }
  }

  /**
   * 接收完成，弹窗提示移动文件到Download应用文件夹
   */
  // onReceiveComplete() {
  //   this.mMoveFileAuthorizeDialogId = DialogHelper.showCustomDialog<MoveFileDialogOptions>(
  //     wrapBuilder(MoveFileDialogBuilder),
  //     {
  //       uiContext: this.getUIContext(),
  //       onAction: (action: DialogAction) => {
  //         if (action === DialogAction.ONE && this.mMoveFileAuthorizeDialogId != null) {
  //           DialogHelper.closeDialog(this.mMoveFileAuthorizeDialogId)
  //           this.mMoveFileAuthorizeDialogId = null
  //         }
  //       },
  //       context: getContext(this),
  //       onMovementAuthorized: async () => {
  //         if (this.mMoveFileAuthorizeDialogId != null) {
  //           DialogHelper.closeDialog(this.mMoveFileAuthorizeDialogId)
  //           this.mMoveFileAuthorizeDialogId = null
  //         }
  //         this.doMoveReceiveFiles()
  //       },
  //     }
  //   )
  // }
  //
  // private async doMoveReceiveFiles() {
  //   //picker.DocumentViewPicker(context).save(options) 导致了loading不显示?
  //   // DialogHelper.showLoadingDialog({
  //   //   loadType: SpinType.spinZ,
  //   //   loadColor: $r('app.color.on_container'),
  //   //   backgroundColor: $r('app.color.container'),
  //   //   autoCancel: false,
  //   //   isModal: false
  //   // })
  //   /**
  //    * DocumentViewPicker会导致Dialog无法正常显示
  //    * @link https://developer.huawei.com/consumer/cn/doc/harmonyos-releases-V5/changelogs-ux-b071-V5#%E6%A8%A1%E6%80%81uiextension%E5%88%9B%E5%BB%BA%E9%BB%98%E8%AE%A4%E8%A1%8C%E4%B8%BA%E5%8F%98%E6%9B%B4
  //    */
  //   this.isMovingFile = true
  //   try {
  //     const completeFileInfos: FileTransferInfo[] = []
  //     const keys: string[] = Object.keys(this.status)
  //     for (let i = 0; i < keys.length; i++) {
  //       const element: FileTransferInfo = this.status[keys[i]]
  //       if (element.status === FileTransferStatus.COMPLETED && element.filePath) {
  //         completeFileInfos.push(element)
  //       }
  //     }
  //     let succeed = 0
  //     if (completeFileInfos.length > 0) {
  //       succeed = await FileProvider.moveFilesToDownload(getContext(this), completeFileInfos, (moved: IMoveFile) => {
  //         this.onMovedFileComplete(moved)
  //       })
  //       if (succeed === 0) {
  //         toast.show($r('app.string.file_move_failed'))
  //       } else if (succeed === completeFileInfos.length) {
  //         toast.show($r('app.string.file_move_complete'))
  //       } else {
  //         toast.show($r('app.string.some_file_move_failed'))
  //       }
  //     }
  //   } catch (e) {
  //     logger.warn('TransferPage', `移动文件出错: ${Errors.getErrorMessage(e)}`)
  //   } finally {
  //     // DialogHelper.closeLoading()
  //     this.isMovingFile = false
  //   }
  // }
  //
  // private onMovedFileComplete(moved: IMoveFile) {
  //   if (this.param.isSent || !AppStorage.get<boolean>(Keys.SAVE_RECEIVE_RECORD) ||
  //     !(moved instanceof FileTransferInfo) || Strings.isEmpty(moved.getFilepath())) {
  //     logger.debug('TransferPage', `更新接收记录 已跳过`)
  //     return
  //   }
  //   new ReceivedRecordMapper().update(new Wapper().set('filePath', moved.getFilepath()).eq('fileId', moved.fileId))
  //     .then(() => {
  //       logger.debug('TransferPage', `更新接收记录成功 => fileId: ${moved.fileId} newFilePath: ${moved.getFilepath()}`)
  //     })
  //     .catch((reason: object) => {
  //       logger.warn(
  //         'TransferPage',
  //         `更新接收记录失败 => fileId: ${moved.fileId} newFilePath: ${moved.getFilepath()} Error: ${Errors.getErrorMessage(reason)}`
  //       )
  //     })
  // }
}