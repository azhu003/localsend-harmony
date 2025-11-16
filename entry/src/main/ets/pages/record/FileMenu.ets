import { ReceiveRecordModel } from '../../model'
import { FileInfomation } from './FileInfomation'
import { DialogHelper } from '@pura/harmony-dialog'
import { ClickUtil } from '@pura/harmony-utils'
import { Apps } from '../../utils/Apps'
import { common } from '@kit.AbilityKit'

@Component
export struct FileMenu {
  @Prop data: ReceiveRecordModel
  onRemoveRecordClick?: (id: number) => void

  @Builder
  FileInfomationContent() {
    FileInfomation({ data: this.data })
  }

  build() {
    Menu() {
      MenuItem({ content: $r('app.string.open_file') }).onClick(() => {
        Apps.useOtherAppOpenFile(getContext(this) as common.UIAbilityContext, this.data.filePath)
      })
      MenuItem({ content: $r('app.string.open_in_fm') }).onClick(() => {
        Apps.toAppDownloadFolder(getContext(this) as common.UIAbilityContext)
      })
      MenuItem({ content: $r('app.string.information') }).onClick(() => this.onInformationClick())
      MenuItem({ content: $r('app.string.delete_from_history') }).onClick(() => ClickUtil.throttle(() => this.onDeleteRecordClick()))
    }
    .fontColor($r('app.color.on_container'))
  }

  onInformationClick() {
    DialogHelper.showCustomContentDialog({
      title: $r('app.string.file_information'),
      buttons: [{ value: $r('app.string.close'), }],
      contentBuilder: () => {
        this.FileInfomationContent()
      }
    })
  }

  onDeleteRecordClick() {
    if (this.onRemoveRecordClick) {
      this.onRemoveRecordClick(this.data.id)
    }
  }
}