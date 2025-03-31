import { DateUtil } from '@pura/harmony-utils'
import { Errors, logger, toast } from 'common'
import { SizeConstant } from 'common/src/main/ets/constant/SizeConstant'
import { Wapper } from 'rdbplus/src/main/ets/Wapper'
import { FileIcon, Icon, SingleLineText } from '../../components'
import { ReceivedRecordMapper } from '../../db'
import { IMoveFile, ReceiveRecordModel } from '../../model'
import { FileProvider } from '../../utils'
import { FileMenu } from './FileMenu'

@Component
export struct RecordItem {
  @Prop data: ReceiveRecordModel
  @Prop index: number
  @State isLongPress: boolean = false
  onRemoveRecordClick?: (id: number) => void
  onFileMoving?: (isMoving: boolean) => void

  @Builder
  BindMenus() {
    FileMenu({
      data: this.data, onRemoveRecordClick: this.onRemoveRecordClick
    })
  }

  build() {
    Row() {
      FileIcon({ fileType: this.data.fileType })
      Blank().width(SizeConstant.SPACE_M)
      Column() {
        SingleLineText({ text: this.data.fileName, overflow: this.isLongPress ? TextOverflow.MARQUEE : TextOverflow.Ellipsis })
          .width('100%')
        Blank().height(SizeConstant.SPACE_S)
        SingleLineText({
          text: this.getFileInfo(),
          textSize: SizeConstant.TEXT_L,
          overflow: this.isLongPress ? TextOverflow.MARQUEE : TextOverflow.Ellipsis
        }).width('100%')
      }
      .layoutWeight(1)

      if (this.data.isSandbox()) {
        SaveButton({ icon: SaveIconStyle.FULL_FILLED, buttonType: ButtonType.Circle })
          .size({ width: SizeConstant.ICON_XL, height: SizeConstant.ICON_XL })
          .onClick(async (_, result: SaveButtonOnClickResult) => {
            if (result == SaveButtonOnClickResult.SUCCESS) {
              // this.doMoveReceiveFiles()
            } else {
              toast.show($r('app.string.file_move_to_download_error'))
            }
          })
      }
      Icon({ src: $r('app.media.ic_more') })
        .bindMenu(this.BindMenus)
    }
    .gesture(LongPressGesture()
      .onAction(() => {
        this.isLongPress = true
      })
      .onActionEnd(() => {
        this.isLongPress = false
      })
    )
  }

  getFileInfo(): string {
    return `${DateUtil.getFormatDateStr(this.data.sendAt)} - ${FileProvider.formatBytes(this.data.size)} - ${this.data.sender}`
  }

//   private async doMoveReceiveFiles() {
//     try {
//       this.onFileMoving?.(true)
//       const files: SimpleMoveFile[] = [new SimpleMoveFile(this.data.filePath)]
//       await FileProvider.moveFilesToDownload(getContext(this), files, (moved: IMoveFile) => {
//         this.data.filePath = moved.getFilepath()
//         //修改数据库该文件存放目录
//         new ReceivedRecordMapper().update(new Wapper().set('filePath', moved.getFilepath()).eq('id', this.data.id))
//         toast.show($r('app.string.file_move_complete'))
//         this.onFileMoving?.(false)
//       })
//     } catch (e) {
//       logger.warn('TransferPage', `移动文件出错: ${Errors.getErrorMessage(e)}`)
//       toast.show($r('app.string.file_move_failed'))
//     } finally {
//       // DialogHelper.closeLoading()
//     }
//   }
}