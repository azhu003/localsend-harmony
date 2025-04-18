import { SizeConstant } from 'common'
import { DeviceIcon, Icon, LoopImage } from './'
import { DeviceModel, NearbyDeviceModel } from '../model'
import { curves } from '@kit.ArkUI'
import { DeviceMapper } from '../db/mapper/DeviceMapper'
import { ClickUtil } from '@pura/harmony-utils'

@Component
export struct DeviceItem {
  @State device: NearbyDeviceModel | DeviceModel | undefined | null = undefined
  @Prop favorDisplay: boolean = true
  @State scaleValue: number = 1

  build() {
    Row() {
      if (this.device) {
        DeviceIcon({ deviceType: this.device.deviceType })
      } else {
        LoopImage({
          images: [
            $r('app.media.ic_mobile'), $r('app.media.ic_computer'),
            $r('app.media.ic_cli'), $r("app.media.ic_storage"), $r("app.media.ic_web")
          ]
        })
      }
      Blank().width(SizeConstant.TEXT_L)
      Column() {
        Text(this.device?.alias || "")
          .fontSize(SizeConstant.TEXT_XL)
          .fontColor($r('app.color.on_container'))
        Blank().height(SizeConstant.TEXT_M)
        Row() {
          Text(this.getDeviceId(this.device) ? `#${this.getDeviceId(this.device)}` : "")
            .fontSize(SizeConstant.TEXT_XL)
            .fontColor($r('app.color.on_container'))
            .padding({ left: SizeConstant.SPACE_M, right: SizeConstant.SPACE_M })
            .backgroundColor($r('app.color.background'))
            .borderRadius(SizeConstant.RADIUS_M)
            .visibility(this.device == undefined ? Visibility.None : Visibility.Visible)
          Blank().width(SizeConstant.TEXT_M)
          Text(this.device?.deviceModel || "")
            .fontSize(SizeConstant.TEXT_XL)
            .fontColor($r('app.color.on_container'))
            .padding({
              left: SizeConstant.SPACE_M,
              top: SizeConstant.SPACE_EXTRA_S,
              right: SizeConstant.SPACE_M,
              bottom: SizeConstant.SPACE_EXTRA_S
            })
            .backgroundColor($r('app.color.background'))
            .borderRadius(SizeConstant.RADIUS_M)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.favorDisplay) {
        Icon({ src: this.isFavorited() ? $r('app.media.ic_favor_filled') : $r('app.media.ic_favor') })
          .align(Alignment.Center)
          .visibility(this.device == undefined ? Visibility.None : Visibility.Visible)
          .onClick(() => ClickUtil.throttle(() => this.onFavoritedClick(), 100))
      }
    }
    .width('100%')
    .height(90)
    // .margin({ top: SizeConstant.SPACE_L, bottom: SizeConstant.SPACE_L })
    .padding(SizeConstant.SPACE_L)
    .scale({
      x: this.scaleValue,
      y: this.scaleValue
    })
    .borderRadius(SizeConstant.RADIUS_L)
    .backgroundColor($r('app.color.container'))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        animateTo({ curve: curves.interpolatingSpring(0, 1, 350, 35) }, () => {
          this.scaleValue = 0.95;
        })
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        animateTo({ curve: curves.interpolatingSpring(0, 1, 350, 35) }, () => {
          this.scaleValue = 1;
        })
      }
    })
  }

  private isFavorited(): boolean {
    if (this.device instanceof NearbyDeviceModel) {
      return this.device.isFavorited === 1
    }
    return false
  }

  private onFavoritedClick() {
    if (this.device instanceof NearbyDeviceModel) {
      this.device.isFavorited = this.device.isFavorited ^ 1
      new DeviceMapper().updateById(this.device)
    }
  }

  private getDeviceId(device: DeviceModel): number | undefined {
    if (device instanceof NearbyDeviceModel) {
      return device.id
    }
    return undefined
  }
}