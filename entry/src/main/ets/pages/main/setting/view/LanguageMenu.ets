import { LocaleProvider, LocaleType } from '../../../../locale'

@Builder
export function LanguageMenu() {
  Menu() {
    MenuItem({ content: $r('app.string.flow_system') }).onClick(() => LocaleProvider.setAutoLocale())
    MenuItem({ content: '简体中文' }).onClick(() => LocaleProvider.setSpecifiedLocal(LocaleType.CHINESE_HANS_CN))
    MenuItem({ content: 'English' }).onClick(() => LocaleProvider.setSpecifiedLocal(LocaleType.ENGLISH_US))
  }
  .fontColor($r('app.color.on_container'))
}