import { DateUtil } from '@pura/harmony-utils'
import { SizeConstant } from 'common'
import { SingleLineText } from '../../components'
import { ReceiveRecordModel } from '../../model'
import { FileProvider } from '../../utils'
import { TextModifier } from '@kit.ArkUI'

const lineHeight = 22

@Component
export struct FileInfomation {
  @Prop data: ReceiveRecordModel
  @State isLongPress: boolean = false

  build() {
    RelativeContainer() {
      Text($r('app.string.file_name'))
        .fontSize(SizeConstant.TEXT_L)
        .fontColor($r('app.color.on_background'))
        .id('file_name_text')
        .lineHeight(lineHeight)

      SingleLineText({
        text: this.data.fileName,
        textSize: SizeConstant.TEXT_L,
        textColor: $r('app.color.on_background'),
        modifier: new TextModifier().lineHeight(lineHeight)
      })
        .margin({ left: SizeConstant.SPACE_EXTRA_S })
        .alignRules({
          left: { anchor: "file_name_text", align: HorizontalAlign.End },
          right: { anchor: "__container__", align: HorizontalAlign.End }
        })
        .id('file_name_value')

      Text($r('app.string.file_path'))
        .fontSize(SizeConstant.TEXT_L)
        .fontColor($r('app.color.on_background'))
        .id('file_path_text')
        .alignRules({
          left: { anchor: "file_name_text", align: HorizontalAlign.Start },
          top: { anchor: "file_name_text", align: VerticalAlign.Bottom }
        })
        .lineHeight(lineHeight)

      SingleLineText({
        text: this.data.filePath || " ",
        textSize: SizeConstant.TEXT_L,
        textColor: $r('app.color.on_background'),
        overflow: this.isLongPress ? TextOverflow.MARQUEE : TextOverflow.Ellipsis,
        modifier: new TextModifier().lineHeight(lineHeight)
      })
        .id('file_path_value')
        .alignRules({
          top: { anchor: "file_name_value", align: VerticalAlign.Bottom },
          left: { anchor: "file_name_value", align: HorizontalAlign.Start },
          right: { anchor: "__container__", align: HorizontalAlign.End }
        })
        .margin({ left: SizeConstant.SPACE_EXTRA_S })

      Text($r('app.string.file_size'))
        .fontSize(SizeConstant.TEXT_L)
        .fontColor($r('app.color.on_background'))
        .id('file_size_text')
        .alignRules({
          left: { anchor: "file_name_text", align: HorizontalAlign.Start },
          top: { anchor: "file_path_text", align: VerticalAlign.Bottom }
        })
        .lineHeight(lineHeight)
      Text(FileProvider.formatBytes(this.data.size))
        .fontSize(SizeConstant.TEXT_L)
        .fontColor($r('app.color.on_background'))
        .margin({ left: SizeConstant.SPACE_EXTRA_S })
        .id('file_size_value')
        .alignRules({
          top: { anchor: "file_path_value", align: VerticalAlign.Bottom },
          left: { anchor: "file_name_value", align: HorizontalAlign.Start },
        })
        .lineHeight(lineHeight)

      Text($r('app.string.sender'))
        .fontSize(SizeConstant.TEXT_L)
        .fontColor($r('app.color.on_background'))
        .id('sender_text')
        .alignRules({
          left: { anchor: "file_name_text", align: HorizontalAlign.Start },
          top: { anchor: "file_size_text", align: VerticalAlign.Bottom }
        })
        .lineHeight(lineHeight)
      SingleLineText({
        text: this.data.sender,
        textSize: SizeConstant.TEXT_L,
        textColor: $r('app.color.on_background'),
        modifier: new TextModifier().lineHeight(lineHeight)
      })
        .id('sender_value')
        .alignRules({
          top: { anchor: "file_size_value", align: VerticalAlign.Bottom },
          left: { anchor: "file_name_value", align: HorizontalAlign.Start },
          right: { anchor: "__container__", align: HorizontalAlign.End }
        })
        .margin({ left: SizeConstant.SPACE_EXTRA_S })

      Text($r('app.string.time'))
        .fontSize(SizeConstant.TEXT_L)
        .fontColor($r('app.color.on_background'))
        .id('time_text')
        .alignRules({
          left: { anchor: "file_name_text", align: HorizontalAlign.Start },
          top: { anchor: "sender_text", align: VerticalAlign.Bottom }
        })
        .lineHeight(lineHeight)
      Text(DateUtil.getFormatDateStr(this.data.sendAt))
        .fontSize(SizeConstant.TEXT_L)
        .fontColor($r('app.color.on_background'))
        .margin({ left: SizeConstant.SPACE_EXTRA_S })
        .id('time_value')
        .alignRules({
          top: { anchor: "sender_value", align: VerticalAlign.Bottom },
          left: { anchor: "file_name_value", align: HorizontalAlign.Start },
        })
        .lineHeight(lineHeight)
    }
    .width('100%')
    .height('auto')
    .gesture(LongPressGesture()
      .onAction(() => {
        this.isLongPress = true
      })
      .onActionEnd(() => {
        this.isLongPress = false
      })
    )
  }
}