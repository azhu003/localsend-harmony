import { logger, SizeConstant, Strings, toast } from 'common';
import { Icon, NavigationTitle, PasteboardAuthorizeDialog, PasteboardAuthorizeDialogOptions } from '../../../../components';
import { DeviceProvider } from '../../../../utils/DeviceProvider';
import { EventBus, EventType } from '../../../../eventbus';
import { SelectorButton } from './SelectorButton';
import { DeviceItem } from '../../../../components/DeviceItem';
import { SelectedFiles } from './SelctedFiles';
import { FileProvider, ObservedArray, Routers } from '../../../../utils';
import { NearbyDeviceModel, PendingSendFile } from '../../../../model';
import { DialogAction, DialogHelper } from '@pura/harmony-dialog';
import { pasteboard } from '@kit.BasicServicesKit';
import { Footer } from './Footer';
import { SendRequestParams } from '../../../send';
import { CardUtil } from '../../../../transaction/CardUtil';
import { componentSnapshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { SnapShotImage } from '../../../../transaction/SnapShotImage';
import { ClickUtil } from '@pura/harmony-utils';

@Component
export struct Send {
  @Consume('pages') pages: NavPathStack
  @StorageLink(DeviceProvider.REGISTERED_DEVICE_LIST_KEY) allDevice: NearbyDeviceModel[] = []
  @State selectedFiles: ObservedArray<PendingSendFile> = []
  // @State toDevice: DeviceModel | null = null
  // mSendFileRequestDialog: CustomDialogController | null = new CustomDialogController({
  //   width: '100%',
  //   height: '100%',
  //   offset: {
  //     dx: 0,
  //     dy: 0
  //   },
  //   builder: SendRequestDialog({
  //     files: this.selectedFiles,
  //     target: this.toDevice,
  //   }),
  // })
  mPasteboardAuthorizeDialogId: string | null = null
  @State mTouchedDeviceIndex: number = -1
  @State mDeviceItemScale: number = 1
  @State clickDeviceIndex: number = -1

  build() {
    NavigationTitle({ title: $r('app.string.select'), isHideBackButton: true }) {
      Column() {
        if (this.selectedFiles && this.selectedFiles.length > 0) {
          SelectedFiles({
            files: this.selectedFiles,
            onAppendClick: () => {
              this.addSelectFile(getContext(this))
            }
          })
        } else {
          Row() {
            SelectorButton({ text: $r('app.string.file'), icon: $r('app.media.ic_file') })
              .layoutWeight(1)
              .onClick(() => ClickUtil.throttle(() => this.addSelectFile(getContext(this))))
            Blank().width(SizeConstant.SPACE_M)
            // if (canIUse('SystemCapability.FileManagement.UserFileService.FolderSelection')) {
            //   SelectorButton({ text: $r('app.string.folder'), icon: $r('app.media.ic_folder_filled') })
            //     .layoutWeight(1)
            //     .onClick(() => {
            //       this.addSelectFile(getContext(this),picker.DocumentSelectMode.FOLDER)
            //     })
            //   Blank().width(SizeConstant.SPACE_M)
            // }
            SelectorButton({ text: $r('app.string.media'), icon: $r('app.media.ic_picture') })
              .layoutWeight(1)
              .onClick(() => ClickUtil.throttle(() => {
                this.addMediaClick(getContext(this))
              }))
            Blank().width(SizeConstant.SPACE_M)
            SelectorButton({ text: $r('app.string.text'), icon: $r('app.media.ic_text_filled') })
              .layoutWeight(1)
              .onClick(() => ClickUtil.throttle(() => {
                this.onSendTextMessageClick()
              }))
            Blank().width(SizeConstant.SPACE_M)
            SelectorButton({ text: $r('app.string.clipboard'), icon: $r('app.media.ic_clipboard') })
              .layoutWeight(1)
              .onClick(() => ClickUtil.throttle(() => {
                this.onSendFromPasteboard()
              }))
          }
          .width('100%')
          .height('auto')
        }

        //附近设备
        Row() {
          Text($r('app.string.nearby_devices'))
            .fontSize(SizeConstant.TEXT_XXL)
            .fontColor($r('app.color.on_container'))
          Blank().width(SizeConstant.SPACE_L)
          Icon({
            src: $r('app.media.ic_rotate'),
            spacing: SizeConstant.SPACE_EXTRA_S,
          }).onClick(() => ClickUtil.throttle(() => {
            this.allDevice = []
            EventBus.getInstance().post(EventType.SCAN_DEVICE)
          }))
          Blank().width(SizeConstant.SPACE_L)
          Icon({
            src: $r('app.media.ic_quickstart'),
            spacing: SizeConstant.SPACE_EXTRA_S,
          }).onClick(() => ClickUtil.throttle(() => {
            toast.show("手动发送")
          }))
          Blank().width(SizeConstant.SPACE_L)
          Icon({
            src: $r('app.media.ic_favor'), spacing: SizeConstant.SPACE_EXTRA_S,
          }).onClick(() => ClickUtil.throttle(() => {
            toast.show("收藏夹")
          }))
          Blank().width(SizeConstant.SPACE_L)
          Icon({
            src: $r('app.media.ic_settings'), spacing: SizeConstant.SPACE_EXTRA_S,
          }).onClick(() => ClickUtil.throttle(() => {
            toast.show("发送模式")
          }))
        }
        .margin({ top: SizeConstant.SPACE_XL })

        //设备列表
        if (this.allDevice.length > 0) {
          List({ space: SizeConstant.SPACE_L }) {
            ForEach(this.allDevice, (item: NearbyDeviceModel, index: number) => {
              ListItem() {
                DeviceItem({ device: item })
                  .id(CardUtil.getPostPageImageId(index.toString()))
                  .onClick(() => {
                    this.onSendToDeviceClick(item, index)
                  })
              }
            }, (item: NearbyDeviceModel, index: number) => `${item.key}_${index}`)
            ListItem() {
              Footer()
            }
          }
          .padding({
            top: SizeConstant.SPACE_L,
            bottom: SizeConstant.SPACE_L
          })
          .listDirection(Axis.Vertical)
          .width('100%')
          .layoutWeight(1)
        } else {
          Blank().height(SizeConstant.SPACE_L)
          DeviceItem()
          Footer()
        }
      }
      .alignItems(HorizontalAlign.Start)
      .size({ width: '100%', height: '100%' })
      .padding({
        right: SizeConstant.SPACE_L,
        left: SizeConstant.SPACE_L
      })
    }
  }

  aboutToAppear(): void {
    EventBus.getInstance().on(EventType.UPLOAD_FILE_COMPLETED, () => {
      this.selectedFiles = []
    })
  }

  addSelectFile(context: Context) {
    FileProvider.selectFile(context, this.selectedFiles)
      .then((files: PendingSendFile[]) => {
        this.selectedFiles.push(...files)
      })
      .catch((e: Error) => {
        logger.info('Send', `selected files error => ${e.message}\n${e.stack}`)
      })
  }

  addMediaClick(context: Context) {
    FileProvider.getMedia(context, this.selectedFiles)
      .then((files: PendingSendFile[]) => {
        this.selectedFiles.push(...files)
      })
      .catch((e: Error) => {
        logger.info('Send', `selected files error => ${e.message}\n${e.stack}`)
      })
  }

  onSendTextMessageClick() {
    DialogHelper.showTextAreaDialog({
      title: $r('app.string.enter_message'),
      text: '',
      inputBorder: {
        radius: SizeConstant.RADIUS_M
      },
      onAction: (action: DialogAction, _: string, content: string) => {
        if (action == DialogAction.TWO) {
          this.selectedFiles.push(...FileProvider.createTextMessages(content))
        }
      }
    })
  }

  onSendFromPasteboard() {
    this.mPasteboardAuthorizeDialogId = DialogHelper.showCustomDialog<PasteboardAuthorizeDialogOptions>(
      wrapBuilder(PasteboardAuthorizeDialog),
      {
        uiContext: this.getUIContext(),
        onAction: (action: DialogAction) => {
          if (action === DialogAction.ONE && this.mPasteboardAuthorizeDialogId != null) {
            DialogHelper.closeDialog(this.mPasteboardAuthorizeDialogId)
            this.mPasteboardAuthorizeDialogId = null
          }
        },
        onAuthorized: () => {
          if (this.mPasteboardAuthorizeDialogId != null) {
            DialogHelper.closeDialog(this.mPasteboardAuthorizeDialogId)
            this.mPasteboardAuthorizeDialogId = null
          }
          let clipboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
          clipboard.getData()
            .then((pasteData: pasteboard.PasteData) => {
              let text: string = pasteData.getPrimaryText();
              if (Strings.isEmpty(text)) {
                toast.show($r('app.string.clipboard_nodata'))
                return
              }
              this.selectedFiles.push(...FileProvider.createTextMessages(text))
            })
        },
      }
    )
  }

  onSendToDeviceClick(item: NearbyDeviceModel, index: number) {
    if (!this.selectedFiles || this.selectedFiles.length == 0) {
      DialogHelper.showAlertDialog({
        title: $r('app.string.unselected_file'),
        content: $r('app.string.unselected_file_text'),
        secondaryButton: $r('app.string.close'),
        onAction: () => {
        },
      })
    } else {
      if (item.protocol === 'https') {
        toast.show('对方开启了加密，当前客户端暂不支持加密传输')
        return
      }
      componentSnapshot.get(CardUtil.getPostPageImageId(index.toString()), (error: Error, pixelMap: image.PixelMap) => {
        if (error) {
          // logger.info('Send', 'CardLongTakePageOne componentSnapshot.get error, reason: ' + JSON.stringify(error));
          // If the screenshot fails, go to the default left/right transition. In this case, the pop-up page will not receive clickedComponentId parameter, and the registration process will not proceed.
          // At that time from and to the animation are undefined, will go in customNavContentTransition transitions by default.
          this.pages.pushPath({ name: Routers.SEND_REQUEST_PAGE, param: new SendRequestParams(this.selectedFiles, item) })
          return;
        } else {
          // logger.info('Send', 'CardLongTakePageOne componentSnapshot.get success!');
          // If the screenshot is successful, then go to a custom mirror in the end transition.
          this.clickDeviceIndex = index
          SnapShotImage.pixelMap = pixelMap;
          this.pages.pushPath({
            name: Routers.SEND_REQUEST_PAGE,
            param: new SendRequestParams(this.selectedFiles, item, CardUtil.getPostPageImageId(index.toString()), () => {
              this.doFinishTransition();
            })
          })
          //hide item
        }
      })
    }
  }

  private doFinishTransition(): void {
    //display item
  }

  aboutToDisappear(): void {
    EventBus.getInstance().unregister(EventType.UPLOAD_FILE_COMPLETED)
  }
}