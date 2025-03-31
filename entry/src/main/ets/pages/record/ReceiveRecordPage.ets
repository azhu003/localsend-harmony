import { SizeConstant } from 'common/src/main/ets/constant/SizeConstant'
import { IconButton, NavigationTitle } from '../../components'
import { ReceivedFileModel, ReceiveRecordModel } from '../../model'
import { RecordItem } from './RecordItem'
import { JSON } from '@kit.ArkTS'
import { ObservedArray } from '../../utils'
import { Errors, logger, Screens, toast } from 'common'
import { Page, Wapper } from 'rdbplus'
import { ReceivedRecordMapper } from '../../db/mapper/ReceiveRecordMapper'
import { DialogAction, DialogHelper, SpinKit, SpinType } from '@pura/harmony-dialog'
import { common, Want } from '@kit.AbilityKit'

@Builder
export function ReceiveRecordPageBuilder() {
  ReceiveRecordPage()
}

@Component
export struct ReceiveRecordPage {
  @State current: number = 1
  @State total: number = 0
  @State records: ObservedArray<ReceiveRecordModel> = []
  @State isMovingFile: boolean = false
  menus: Array<NavigationMenuItem> = [{
    value: 'item1',
    icon: 'resources/base/media/ic_public_more.svg',
    action: () => {
      toast.show('多选')
    }
  }]

  build() {
    NavDestination() {
      Stack() {
        NavigationTitle({ title: $r('app.string.history'), /*menus: this.menus*/ }) {
          List({ space: SizeConstant.SPACE_L }) {
            ListItem() {
              Row() {
                IconButton({
                  icon: $r('app.media.ic_folder_filled'),
                  iconSize: SizeConstant.ICON_L,
                  text: $r('app.string.open_folder'),
                  textSize: SizeConstant.TEXT_L,
                  arrangement: FlexDirection.Row
                })
                  .borderRadius(SizeConstant.RADIUS_L)
                  .backgroundColor($r('app.color.container'))
                  .padding({ left: SizeConstant.SPACE_M, right: SizeConstant.SPACE_M })
                  .onClick(() => {
                    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
                    let want: Want = {
                      bundleName: 'com.huawei.hmos.filemanager',
                      abilityName: 'MainAbility'
                    };
                    context.startAbility(want);
                  })

                Blank().width(SizeConstant.SPACE_XL)

                IconButton({
                  icon: $r('app.media.ic_delete_filled'),
                  iconSize: SizeConstant.ICON_L,
                  text: $r('app.string.delete_record'),
                  textSize: SizeConstant.TEXT_L,
                  arrangement: FlexDirection.Row,
                  clickable: this.records.length !== 0
                })
                  .borderRadius(SizeConstant.RADIUS_L)
                  .backgroundColor($r('app.color.container'))
                  .padding({ left: SizeConstant.SPACE_M, right: SizeConstant.SPACE_M })
                  .enabled(this.records.length !== 0)
                  .onClick(() => this.onDeleteAllRecordClick())
              }
            }

            if (this.total !== 0) {
              ForEach(this.records, (item: ReceiveRecordModel, index: number) => {
                ListItem() {
                  RecordItem({
                    data: item,
                    index: index,
                    onRemoveRecordClick: (id: number) => {
                      this.onRemoveRecordClick(index, id)
                    },
                    onFileMoving: (isMoving: boolean) => {
                      this.isMovingFile = isMoving
                    }
                  })
                }
              }, (item: ReceivedFileModel, index: number) => `${item.id}_${index}`)
            } else {
              ListItem() {
                Column() {
                  Blank().height(130)
                  IconButton({
                    icon: $r('app.media.ic_no_data'),
                    iconSize: SizeConstant.ICON_XXL,
                    text: $r('app.string.no_data'),
                    textSize: SizeConstant.TEXT_XL,
                    textColor: $r('app.color.on_container_secondary'),
                    arrangement: FlexDirection.Column,
                    space: SizeConstant.SPACE_L
                  })
                }
                .width('100%')
                .alignItems(HorizontalAlign.Center)
              }
            }
            ListItem().height(Screens.getNavigationBarHeight())
          }
          .width('100%')
          .height('100%')
          .padding(SizeConstant.SPACE_L)
          .listDirection(Axis.Vertical)
        }

        if (this.isMovingFile) {
          Stack()
            .size({ width: '100%', height: '100%' })
            .backgroundColor($r('app.color.mask_background'))
          Column() {
            SpinKit({ spinType: SpinType.spinZ, spinColor: $r('app.color.on_container') }).align(Alignment.Center)
          }
          .padding(SizeConstant.SPACE_L)
          .borderRadius(SizeConstant.RADIUS_M)
          .backgroundColor($r('app.color.container'))
        }
      }
    }
    .hideTitleBar(true)
  }

  aboutToAppear(): void {
    new ReceivedRecordMapper().getPage(this.current, 1000, new Wapper().orderByDesc('id'))
      .then((page: Page<ReceiveRecordModel>) => {
        console.info(`接收记录: ${JSON.stringify(page)}`)
        this.current = page.current
        this.total = page.total
        this.records.push(...page.record)
        logger.debug('ReceiveRecordPage',`record: ${this.records}`)
      })
      .catch((reason: object) => {
        console.error(`获取接收记录出错: ${Errors.getErrorMessage(reason)}`)
      })
  }

  private onRemoveRecordClick(index: number, id: number) {
    new ReceivedRecordMapper().deleteById(id)
      .then(() => {
        logger.debug('ReceiveRecordPage', `接收记录已删除 index: ${index} id: ${id} file name: ${this.records[index].fileName}`)
        this.records.splice(index, 1)
        if (this.records.length === 0) {
          this.total = 0
        }
      })
      .catch((e: object) => {
        logger.warn('ReceiveRecordPage', `删除记录出错: ${Errors.getErrorMessage(e)}`)
      })
  }

  private onDeleteAllRecordClick() {
    DialogHelper.showAlertDialog({
      title: $r('app.string.clear_record_tips'),
      content: $r('app.string.clear_record_tips_text'),
      primaryButton: $r('app.string.cancel'),
      secondaryButton: $r('app.string.delete'),
      onAction: (action) => {
        if (action == DialogAction.TWO) {
          new ReceivedRecordMapper().delete(new Wapper())
            .then(() => {
              this.current = 1
              this.total = 0
              this.records.splice(0, this.records.length)
            })
            .catch((e: object) => {
              logger.warn('ReceiveRecordPage', `清空历史记录失败: ${Errors.getErrorMessage(e)}`)
              toast.show($r('app.string.error'))
            })
        }
      },
    })
  }
}