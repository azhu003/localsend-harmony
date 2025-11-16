import { SizeConstant } from 'common'
import { FileIcon, IconButton, SingleLineText } from '../../components'
import { FileInfoModel, FileTransferInfo, FileTransferStatus } from '../../model'
import { FileProvider } from '../../utils'

@Component
export struct FileItem {
  @Prop file: FileInfoModel
  @Prop status: FileTransferInfo
  @State isLongPress: boolean = false

  build() {
    Row() {
      FileIcon({
        fileName: this.file.fileName,
        fileType: this.file.fileType,
        bgColor: $r('app.color.container'),
        filePath: this.status.filePath
      })

      Blank().width(SizeConstant.SPACE_M)
      Column() {
        SingleLineText({ text: this.file.fileName, overflow: this.isLongPress ? TextOverflow.MARQUEE : TextOverflow.Ellipsis })
          .width('100%')
        Blank().height(SizeConstant.SPACE_EXTRA_S)
        if (this.status?.status === FileTransferStatus.TRANSFERRING) {
          Text(`${FileProvider.formatBytes(this.status.speed)}/s`)
            .fontSize(SizeConstant.TEXT_S)
            .fontColor($r('app.color.highlights'))
          Blank().height(SizeConstant.SPACE_EXTRA_S)
          Progress({
            value: this.status.progress || 0,
            total: 100,
            type: ProgressType.Linear
          }).style({ strokeWidth: 10, enableSmoothEffect: true })
            .color($r('app.color.primary'))
        } else if (this.status?.status === FileTransferStatus.ERROR) {
          IconButton({
            icon: $r('app.media.ic_detail'),
            iconColor: $r('app.color.warn'),
            text: $r('app.string.error'),
            textColor: $r('app.color.warn'),
            arrangement: FlexDirection.RowReverse
          })
        } else {
          Text(this.getStatusText())
            .fontSize(SizeConstant.TEXT_L)
            .fontColor(this.isComplete() ? $r('app.color.highlights') : $r('app.color.on_container_secondary'))
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Blank().width(SizeConstant.SPACE_S)
      Text(FileProvider.formatBytes(this.file.size))
        .fontSize(SizeConstant.TEXT_XL)
        .fontColor($r('app.color.on_container'))
    }
    .alignItems(VerticalAlign.Center)
    .gesture(LongPressGesture()
      .onAction(() => {
        this.isLongPress = true
      })
      .onActionEnd(() => {
        this.isLongPress = false
      })
    )
  }

  getStatusText(): Resource {
    let text: Resource
    switch (this.status.status) {
      case FileTransferStatus.QUEUE:
        text = $r('app.string.queue')
        break;
      case FileTransferStatus.TRANSFERRING:
        text = $r('app.string.transferring')
        break;
      case FileTransferStatus.ERROR:
        text = $r('app.string.incorrect')
        break;
      case FileTransferStatus.SKIPPED:
        text = $r('app.string.skiped')
        break;
      case FileTransferStatus.COMPLETED:
        text = $r('app.string.completed')
        break;
      case FileTransferStatus.CANCELED:
        text = $r('app.string.cancel')
        break;
      default:
        text = $r('app.string.cancel')
    }
    return text
  }

  isComplete(): boolean {
    return this.status?.status === FileTransferStatus.COMPLETED
  }
}