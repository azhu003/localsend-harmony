import { SizeConstant, Strings, toast } from 'common';
import { NavigationTitle, SpinnerButton, ToggleButton, ToggleSwitchedEvent } from '../../../../components';
import { SettingItem } from './SettingItem';
import { Keys } from '../../../../constant';
import { ThemeProvider } from '../../../../theme/ThemeProvider';
import { ThemeMenu } from './ThemeMenu';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { AutoSaveModel } from '../../../../model';
import { Dates, DialogProvider, Routers } from '../../../../utils';
import { ServiceAction } from './ServiceAction';
import { AliasAction } from './AliasAction';
import { InputAction } from './InputAction';
import { DeviceTypeAction } from './DeviceTypeAction';
import { inputMethod } from '@kit.IMEKit';
import { DialogHelper } from '@pura/harmony-dialog';
import { DialogAction } from '@pura/harmony-utils/src/main/ets/entity/constraint';

@Component
export struct Setting {
  @State uuid: string = ''
  @Consume('pages') pages: NavPathStack;
  @State isShowingServiceInfo: boolean = false
  @StorageProp(Keys.COLOR_MODE)
  colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  @StorageLink(Keys.AUTO_SAVE_MODEL) autoSaveModel: AutoSaveModel = AutoSaveModel.CLOSE
  @StorageLink(Keys.USE_PIN_WHEN_RECEIVE) pin: string | undefined = undefined
  @StorageLink(Keys.SERVICE_IS_ONLINE) @Watch('onLineChanged') isOnline: boolean = true
  @State networkTips: ResourceStr | null = null
  @StorageLink(Keys.DEVICE_MODE) deviceMode: string = ''
  @State port: string = `${AppStorage.get(Keys.PORT)}`
  @StorageLink(Keys.MULTICAST_ADDRESS) multicast: string = ''
  @State isInputFocused: boolean = false
  @StorageLink(Keys.SAVE_RECEIVE_RECORD) isSaveReceiveRecord: boolean = false
  @StorageLink(Keys.IS_DEV_MODE) isDevMode: boolean = false
  aboutClicks: number = 0
  aboutClickTime: number = 0

  build() {
    // 卡片折叠态，展开态的共同父组件
    Stack() {
      NavigationTitle({ title: $r('app.string.setting'), isHideBackButton: true }) {
        Scroll() {
          Column() {
            //通用设置
            Column() {
              Text($r('app.string.universal'))
                .fontSize(SizeConstant.TEXT_XXL)
                .fontColor($r('app.color.on_background'))
                .padding(SizeConstant.SPACE_M)
              SettingItem({ text: $r('app.string.theme') }) {
                SpinnerButton({ text: ThemeProvider.getThemeModelText(this.colorMode) }).bindMenu(ThemeMenu)
              }
            }
            .alignItems(HorizontalAlign.Start)
            .padding(SizeConstant.SPACE_M)
            .backgroundColor($r('app.color.container'))
            .borderRadius(SizeConstant.RADIUS_L)

            Blank().height(SizeConstant.SPACE_L)

            //接收
            Column() {
              Text($r('app.string.receive'))
                .fontSize(SizeConstant.TEXT_XXL)
                .fontColor($r('app.color.on_background'))
                .padding(SizeConstant.SPACE_M)
              SettingItem({ text: $r('app.string.auto_save') }) {
                ToggleButton({
                  isOn: this.autoSaveModel === AutoSaveModel.ALL,
                  onToggleSwitched: (event: ToggleSwitchedEvent, isFromUser: boolean) => {
                    if (event.isOn && isFromUser) {
                      DialogProvider.setAutoSaveTips(AutoSaveModel.ALL, () => {
                        event.off()
                      })
                    }
                  }
                })
              }

              SettingItem({ text: $r('app.string.auto_save_favorites_title') }) {
                ToggleButton({
                  isOn: this.autoSaveModel === AutoSaveModel.FAVORITES,
                  onToggleSwitched: (event: ToggleSwitchedEvent, isFromUser: boolean) => {
                    if (event.isOn && isFromUser) {
                      DialogProvider.setAutoSaveTips(AutoSaveModel.FAVORITES, () => {
                        event.off()
                      })
                    }
                  }
                })
              }

              SettingItem({ text: $r('app.string.use_pin') }) {
                ToggleButton({
                  isOn: Strings.isNotEmpty(this.pin),
                  onToggleSwitched: (event: ToggleSwitchedEvent, isFromUser: boolean) => {
                    if (isFromUser) {
                      if (event.isOn) {
                        DialogHelper.showTextInputDialog({
                          title: $r('app.string.enter_pin'),
                          text: this.pin,
                          inputBorder: { radius: SizeConstant.RADIUS_M },
                          onAction: (action: DialogAction, _: string, content: string) => {
                            if (action === DialogAction.TWO) {
                              if (this.pin != content) {
                                this.pin = content
                              }
                            }
                          },
                          onDidDisappear: () => {
                            if (!this.pin) {
                              event.off()
                            }
                          }
                        })
                      } else {
                        this.pin = undefined
                      }
                    }
                  }
                })
              }

              SettingItem({ text: $r('app.string.aut_complete') }) {
                ToggleButton({
                  isOn: false,
                  onToggleSwitched: (event: ToggleSwitchedEvent, isFromUser: boolean) => {
                    if (event.isOn && isFromUser) {
                      toast.show('待实现')
                      event.off()
                    }
                  }
                })
              }

              SettingItem({ text: $r('app.string.save_to_history') }) {
                ToggleButton({
                  isOn: this.isSaveReceiveRecord,
                  onToggleSwitched: (event: ToggleSwitchedEvent, isFromUser: boolean) => {
                    if (event.isOn && isFromUser) {
                      this.isSaveReceiveRecord = event.isOn
                    }
                  }
                })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .padding(SizeConstant.SPACE_M)
            .backgroundColor($r('app.color.container'))
            .borderRadius(SizeConstant.RADIUS_L)

            Blank().height(SizeConstant.SPACE_L)

            //发送
            Column() {
              Text($r('app.string.send'))
                .fontSize(SizeConstant.TEXT_XXL)
                .fontColor($r('app.color.on_background'))
                .padding(SizeConstant.SPACE_M)
              SettingItem({ text: $r('app.string.auto_receive_link_sharing') }) {
                ToggleButton({
                  isOn: false,
                  onToggleSwitched: (event: ToggleSwitchedEvent, isFromUser: boolean) => {
                    if (event.isOn && isFromUser) {
                      toast.show('待实现')
                      event.off()
                    }
                  }
                })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .padding(SizeConstant.SPACE_M)
            .backgroundColor($r('app.color.container'))
            .borderRadius(SizeConstant.RADIUS_L)

            Blank().height(SizeConstant.SPACE_L)

            //网络
            Column() {
              Text($r('app.string.network'))
                .fontSize(SizeConstant.TEXT_XXL)
                .fontColor($r('app.color.on_background'))
                .padding(SizeConstant.SPACE_M)
              if (this.networkTips) {
                Text(this.networkTips)
                  .fontSize(SizeConstant.TEXT_L)
                  .fontColor($r('app.color.warn'))
                  .padding(SizeConstant.SPACE_M)
              }
              SettingItem({ text: this.isOnline ? $r('app.string.service') : $r('app.string.service_offline') }) {
                ServiceAction()
              }

              SettingItem({ text: $r("app.string.alias") }) {
                AliasAction({
                  onChanged: () => {
                    this.onServiceConfigChanged()
                  }
                })
              }

              SettingItem({ text: $r("app.string.device_type") }) {
                DeviceTypeAction({
                  onDeviceTypeChanged: () => {
                    this.onServiceConfigChanged()
                  }
                })
              }

              SettingItem({ text: $r("app.string.device_model") }) {
                InputAction({
                  value: this.deviceMode,
                  onChanged: () => {
                    this.onServiceConfigChanged()
                  }
                })
              }

              SettingItem({ text: $r("app.string.port") }) {
                InputAction({
                  value: this.port,
                  inputType: InputType.Number,
                  onChanged: () => {
                    AppStorage.set(Keys.PORT, Number.parseInt(this.port))
                    this.onServiceConfigChanged()
                  }
                })
              }

              SettingItem({ text: $r("app.string.multicast") }) {
                InputAction({
                  value: this.multicast,
                  onChanged: () => {
                    this.onServiceConfigChanged()
                  }
                })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .padding(SizeConstant.SPACE_M)
            .backgroundColor($r('app.color.container'))
            .borderRadius(SizeConstant.RADIUS_L)

            Blank().height(SizeConstant.SPACE_L)

            //其他
            Column() {
              Text($r('app.string.other'))
                .fontSize(SizeConstant.TEXT_XXL)
                .fontColor($r('app.color.on_background'))
                .padding(SizeConstant.SPACE_M)
              SettingItem({ text: $r('app.string.about') })
                .onClick(() => {
                  this.pages.pushDestination({ name: Routers.ABOUT_PAGE })
                })

              if (this.isDevMode) {
                SettingItem({ text: '开发者工具' }) {
                  Button('打开', { buttonStyle: ButtonStyleMode.TEXTUAL })
                    .onClick(() => {
                      this.pages.pushDestination({ name: Routers.DEVELOPER_TOOLS })
                    })
                }
              }
            }
            .alignItems(HorizontalAlign.Start)
            .padding(SizeConstant.SPACE_M)
            .backgroundColor($r('app.color.container'))
            .borderRadius(SizeConstant.RADIUS_L)


            Column() {

              Blank().height(56)

              Image($r("app.media.logo_text"))
                .width(120)
                .onClick(() => {
                  const now = Dates.now()
                  if (now - this.aboutClickTime > 1000) {
                    this.aboutClicks = 1
                    this.aboutClickTime = now
                  } else if (this.aboutClicks >= 7) {
                    if (this.isDevMode === true) {
                      toast.show('已经是开发者模式了')
                      return
                    }
                    this.isDevMode = true
                    this.aboutClicks = 0
                    this.aboutClickTime = 0
                    toast.show('已开启开发者模式')
                  } else {
                    this.aboutClicks += 1
                    this.aboutClickTime = now
                  }
                })

              Blank().height(56)
            }
            .alignItems(HorizontalAlign.Center)
          }
          .padding({ left: SizeConstant.SPACE_L, right: SizeConstant.SPACE_L })
          .constraintSize({ minHeight: '100%' })
          .onFocus(() => {
            this.isInputFocused = true
          })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down && this.isInputFocused) {
              this.isInputFocused = false
              inputMethod.getController().stopInputSession()
            }
          })
        }
        .width('100%')
        .height('100%')
      }
    }
  }

  onLineChanged() {
    if (this.networkTips != null) {
      this.networkTips = null
    }
  }

  onServiceConfigChanged() {
    this.networkTips = $r('app.string.network_changed_tips')
  }
}