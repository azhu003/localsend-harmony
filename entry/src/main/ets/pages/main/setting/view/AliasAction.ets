import { DialogHelper } from '@pura/harmony-dialog'
import { SizeConstant } from 'common'
import { Icon } from '../../../../components'
import { Keys } from '../../../../constant'
import { DeviceProvider } from '../../../../utils'

@Component
export struct AliasAction {
  @StorageLink(Keys.ALIAS) alias: string = ''
  @State value: string = this.alias
  onChanged?: VoidCallback

  @Builder
  InputContent() {
    Column() {
      Icon({ src: $r('app.media.ic_random') })
        .onClick(() => {
          const rm = this.getUIContext().getHostContext()?.resourceManager
          if (rm != null) {
            this.value = DeviceProvider.getRandomAlias(rm)
          }
        })
      Blank().height(SizeConstant.SPACE_M)
      TextInput({ text: $$this.value })
        .fontSize(SizeConstant.TEXT_XL)
        .fontColor($r('app.color.on_background'))
        .maxLines(1)
        .maxLength(50)
        .defaultFocus(true)
        .textAlign(TextAlign.Center)
        .backgroundColor($r('app.color.container'))
        .borderRadius(SizeConstant.RADIUS_M)
      Blank().height(SizeConstant.SPACE_M)
    }
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Text(this.alias)
      .backgroundColor($r('app.color.background'))
      .borderRadius(SizeConstant.RADIUS_M)
      .width(150)
      .height(48)
      .textAlign(TextAlign.Center)
      .onClick(() => {
        DialogHelper.showCustomContentDialog({
          title: $r("app.string.alias"),
          contentBuilder: () => {
            this.InputContent()
          },
          buttons: [{
            value: $r('app.string.cancel'),
            buttonStyle: ButtonStyleMode.TEXTUAL,
            fontColor: $r('app.color.on_container_secondary')
          }, {
            value: $r('app.string.positive'),
            buttonStyle: ButtonStyleMode.TEXTUAL,
            action: () => {
              if (this.alias != this.value) {
                this.alias = this.value
                if (this.onChanged) {
                  this.onChanged()
                }
              }
            }
          }]
        })
      })
  }
}