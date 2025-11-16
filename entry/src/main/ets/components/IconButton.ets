import { SizeConstant } from 'common'
import { LengthMetrics, MeasureText, MeasureUtils } from '@kit.ArkUI'
import { resourceManager } from '@kit.LocalizationKit'

@Component
export struct IconButton {
  @Prop text: string | Resource
  @Prop icon: PixelMap | ResourceStr | DrawableDescriptor
  @Prop textSize: number = SizeConstant.TEXT_L
  @Prop iconSize: number = SizeConstant.ICON_M
  @Prop arrangement: FlexDirection = FlexDirection.Row
  @Prop space: number = SizeConstant.SPACE_S
  @Prop horizontalPadding: number = 0
  @Prop verticalPadding: number = 0
  @Prop textColor: ResourceColor = $r('app.color.on_background')
  @Prop iconColor: ResourceColor = $r('app.color.icon')
  @Prop clickable: boolean = true

  build() {
    Stack() {
      Flex({
        direction: this.arrangement,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center,
        space: {
          main: LengthMetrics.vp(this.space),
          cross: LengthMetrics.vp(this.space)
        }
      }) {
        Image(this.icon)
          .size({ width: this.iconSize, height: this.iconSize })
          .fillColor(this.iconColor)
        Text(this.text)
          .fontSize(this.textSize)
          .fontColor(this.clickable ? this.textColor : $r('app.color.on_container_secondary'))
      }
      .align(Alignment.Center)
    }
    .size({
      width: this.calcWidth(),
      height: this.calcHeight()
    })
  }

  calcWidth(): number {
    const context = this.getUIContext()
    let text = ''
    if (typeof this.text === 'string') {
      text = this.text as string
    } else {
      text = context.getHostContext()?.resourceManager.getStringSync((this.text as Resource).id) || ""
    }
    const textWidth = this.getUIContext().getMeasureUtils().measureText({
      textContent: text,
      fontSize: `${this.textSize}px`,
      maxLines: 1
    })
    return textWidth + this.iconSize + this.space + (this.horizontalPadding * 2)

  }

  calcHeight(): number {
    const isVertical = this.arrangement == FlexDirection.Column
    return this.iconSize + (isVertical ? this.space : 0) + this.textSize + (this.verticalPadding * 2)
  }
}