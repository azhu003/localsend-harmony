import { logger, Screens, SizeConstant } from 'common';
import { WebService } from '../../../../service';
import { FileProvider, Routers } from '../../../../utils';
import { EventBus, EventType, NumberEventData } from '../../../../eventbus';
import { Icon } from '../../../../components';
import { Keys } from '../../../../constant';
import { AutoSaveModel, ServiceActionType } from '../../../../model';
import { ServiceInfo } from './ServiceInfo';
import { DialogProvider } from '../../../../utils/DialogProvider';
import { emitter } from '@kit.BasicServicesKit';

const service = new WebService(AppStorage.get<string>(Keys.ALIAS) || "Unknown Name")

@Component
export struct Receive {
  @Consume('pages') pages: NavPathStack
  @StorageProp(Keys.ALIAS) alias: string = ""
  @StorageLink(Keys.AUTO_SAVE_MODEL) autoSaveModel: AutoSaveModel = AutoSaveModel.CLOSE
  @State isShowingServiceInfo: boolean = false
  @StorageProp(Keys.SERVICE_IS_ONLINE) @Watch('onServiceOnlineChanged') isOnline: boolean | undefined = undefined
  @State logoAnim: RotateOptions = { angle: '0deg' }

  @Builder
  ServiceInfoPop() {
    ServiceInfo()
  }

  build() {
    Column() {
      Row() {
        Icon({ src: $r('app.media.ic_history'), iconColor: $r('app.color.on_container'), spacing: 2.5, })
          .onClick(() => {
            this.pages.pushDestination({ name: Routers.HISTORY_PAGE })
          })
        Blank().width(SizeConstant.SPACE_L)
        Icon({ src: $r('app.media.ic_detail'), iconColor: $r('app.color.on_container'), spacing: 2, })
          .onClick(() => {
            this.isShowingServiceInfo = true
          })
          .bindPopup(this.isShowingServiceInfo, {
            builder: this.ServiceInfoPop,
            mask: true,
            radius: SizeConstant.RADIUS_M,
            enableArrow: false,
            onStateChange: (e) => {
              if (!e.isVisible) {
                this.isShowingServiceInfo = false
              }
            }
          })
      }
      .width('100%')
      .padding({
        left: SizeConstant.SPACE_L,
        top: Screens.statusBarHeight + SizeConstant.SPACE_L,
        right: SizeConstant.SPACE_L,
        bottom: SizeConstant.SPACE_L,
      })
      .justifyContent(FlexAlign.End)

      Blank().height(SizeConstant.SPACE_L)

      Icon({ src: $r("app.media.logo"), dimension: 200, spacing: SizeConstant.SPACE_XXL }).rotate(this.logoAnim)
      Text(this.alias || "")
        .fontSize(36)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.on_container'))
        .padding({ left: SizeConstant.SPACE_M, right: SizeConstant.SPACE_M })
      if (this.isOnline === false) {
        Text($r('app.string.offline'))
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.on_container'))
          .margin({ top: SizeConstant.SPACE_L })
      }
      Blank().layoutWeight(1)

      Text($r('app.string.auto_save'))
        .fontSize(SizeConstant.TEXT_L)
        .fontColor($r('app.color.on_container'))

      Blank().height(SizeConstant.SPACE_L)

      Row() {
        Text($r('app.string.closed'))
          .fontSize(SizeConstant.TEXT_L)
          .padding({
            left: SizeConstant.SPACE_XXL,
            top: SizeConstant.SPACE_M,
            right: SizeConstant.SPACE_L,
            bottom: SizeConstant.SPACE_M
          })
          .borderRadius({ topLeft: 50, bottomLeft: 50 })
          .borderWidth(0.2)
          .fontColor(this.autoSaveModel == AutoSaveModel.CLOSE ? Color.White : $r('app.color.on_container'))
          .borderColor(this.autoSaveModel == AutoSaveModel.CLOSE ? $r('app.color.primary') :
          $r('app.color.on_container_secondary'))
          .backgroundColor(this.autoSaveModel == AutoSaveModel.CLOSE ? $r('app.color.primary') : Color.Transparent)
          .onClick(() => {
            this.autoSaveModel = AutoSaveModel.CLOSE
          })
        Text($r('app.string.favorites'))
          .fontSize(SizeConstant.TEXT_L)
          .padding({
            left: SizeConstant.SPACE_L,
            top: SizeConstant.SPACE_M,
            right: SizeConstant.SPACE_L,
            bottom: SizeConstant.SPACE_M
          })
          .borderWidth({
            left: 0,
            top: 0.2,
            right: 0,
            bottom: 0.2
          })
          .fontColor(this.autoSaveModel == AutoSaveModel.FAVORITES ? Color.White : $r('app.color.on_container'))
          .borderColor(this.autoSaveModel == AutoSaveModel.FAVORITES ? $r('app.color.primary') :
          $r('app.color.on_container_secondary'))
          .backgroundColor(this.autoSaveModel == AutoSaveModel.FAVORITES ? $r('app.color.primary') : Color.Transparent)
          .onClick(() => {
            DialogProvider.setAutoSaveTips(AutoSaveModel.FAVORITES)
          })
        Text($r('app.string.opened'))
          .fontSize(SizeConstant.TEXT_L)
          .padding({
            left: SizeConstant.SPACE_L,
            top: SizeConstant.SPACE_M,
            right: SizeConstant.SPACE_XXL,
            bottom: SizeConstant.SPACE_M
          })
          .borderRadius({ topRight: 50, bottomRight: 50 })
          .borderWidth(0.2)
          .fontColor(this.autoSaveModel == AutoSaveModel.ALL ? Color.White : $r('app.color.on_container'))
          .borderColor(this.autoSaveModel == AutoSaveModel.ALL ? $r('app.color.primary') :
          $r('app.color.on_container_secondary'))
          .backgroundColor(this.autoSaveModel == AutoSaveModel.ALL ? $r('app.color.primary') : Color.Transparent)
          .onClick(() => {
            DialogProvider.setAutoSaveTips(AutoSaveModel.ALL)
          })
      }

      Blank().height(SizeConstant.SPACE_XXL)
      Blank().height(SizeConstant.SPACE_XL)
    }
    .size({ width: '100%', height: '100%' })
    .padding({ left: SizeConstant.SPACE_L, right: SizeConstant.SPACE_L })
    .backgroundColor($r('app.color.background'))
  }

  aboutToAppear(): void {
    service.setFilesSaveDir(FileProvider.getDefaultFileDir(getContext(this)))
    service.start()
    EventBus.getInstance().on(EventType.SCAN_DEVICE, () => {
      logger.info('ReceivePage', 'receive event: scanning device')
      service.scanOtherDevice()
    })
    EventBus.getInstance().on(EventType.SERVICE_ACTION, (event: emitter.EventData) => {
      const data: NumberEventData = event.data as NumberEventData
      switch (data.value) {
        case ServiceActionType.Start:
          service.start()
          break
        case ServiceActionType.Stop:
          service.stop()
          break
        case ServiceActionType.Restart:
          service.stop().then(() => {
            service.start()
          })
          break
      }
    })
  }

  onServiceOnlineChanged() {
    if (this.isOnline) {
      this.getUIContext().animateTo({ duration: 15000, iterations: -1, curve: Curve.Linear }, () => {
        this.logoAnim = { angle: '360deg' }
      })
    } else {
      this.getUIContext().animateTo({ duration: 0, iterations: 1, curve: Curve.Linear }, () => {
        this.logoAnim = { angle: '0deg' }
      })
    }
  }

  aboutToDisappear(): void {
    service.stop()
    EventBus.getInstance().unregister(EventType.SCAN_DEVICE)
    EventBus.getInstance().unregister(EventType.SERVICE_ACTION)
  }
}