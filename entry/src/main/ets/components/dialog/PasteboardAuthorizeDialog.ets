import { BaseDialogOptions, DialogAction } from "@pura/harmony-dialog"
import { SizeConstant, toast } from "common"

export interface PasteboardAuthorizeDialogOptions extends BaseDialogOptions {
  onAuthorized: VoidCallback
}

@Builder
export function PasteboardAuthorizeDialog(options: PasteboardAuthorizeDialogOptions) {
  Column() {
    Blank().height(SizeConstant.SPACE_L)
    Text($r('app.string.clipboard'))
      .fontColor($r('app.color.on_container'))
      .fontSize(SizeConstant.TEXT_XXL)
      .fontWeight(500)
    Blank().height(SizeConstant.SPACE_L)
    Text($r('app.string.clipboard_permission_tips'))
      .fontColor($r('app.color.on_container'))
      .fontSize(SizeConstant.TEXT_L)
    Blank().height(SizeConstant.SPACE_L)
    PasteButton()
      // .backgroundColor($r('app.color.primary'))
      .fontColor(Color.White)
      .onClick((_: ClickEvent, result: PasteButtonOnClickResult) => {
        if (result === PasteButtonOnClickResult.SUCCESS) {
          options.onAuthorized()
        } else {
          toast.show($r('app.string.clipboard_permission_failed'))
        }
      })
    Blank().height(SizeConstant.SPACE_L)
    Button($r('app.string.cancel'), { buttonStyle: ButtonStyleMode.TEXTUAL })
      .width('100%')
      .fontColor($r('app.color.on_container_secondary'))
      .onClick(() => {
        if (options.onAction) {
          options.onAction(DialogAction.ONE, '', '')
        }
      })
  }
  .width(350)
  .padding(SizeConstant.SPACE_L)
  .backgroundColor($r('app.color.container'))
  .borderRadius(SizeConstant.RADIUS_L)
}