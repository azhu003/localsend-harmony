import { SizeConstant } from "common"

@Component
export struct CardColumn {
  @Prop title: ResourceStr

  @Builder
  doNothingBuilder() {
  }

  @BuilderParam content: VoidCallback = this.doNothingBuilder

  build() {
    Column() {
      if (this.title) {
        Row() {
          Text(this.title)
            .fontColor($r('app.color.on_container'))
            .fontSize(SizeConstant.TEXT_XL)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        Blank().height(SizeConstant.SPACE_M)
      }
      this.content()
    }
    .width('100%')
    .padding(SizeConstant.SPACE_M)
    .margin({ top: SizeConstant.SPACE_S, bottom: SizeConstant.SPACE_S })
    .borderRadius(SizeConstant.RADIUS_M)
    .backgroundColor($r('app.color.container'))
  }
}