import i18n from '@ohos.i18n';
import { Errors, logger } from 'common';
import { Keys } from '../constant';
import { deviceInfo } from '@kit.BasicServicesKit';

export class LocaleProvider {

  static setSpecifiedLocal(lang: string, isFromAuto: boolean = false): boolean {
    const app = i18n.System.getAppPreferredLanguage()
    if (lang.toString() == app) {
      logger.info("LocaleProvider", `和当前App语言一致，不修改 ${lang}`)
      return true
    }
    logger.info("LocaleProvider", `设置语言  ${app} -> ${lang}`)
    try {
      i18n.System.setAppPreferredLanguage(lang)
      logger.info('LocaleProvider', `语言已设置: ${i18n.System.getAppPreferredLanguage()}`)
      if (!isFromAuto) {
        AppStorage.set(Keys.LANGUAGE_IS_AUTO, false)
      }
      return true
    } catch (e) {
      logger.warn('LocaleProvider', `语言设置失败: ${Errors.getErrorMessage(e)}`)
      return false
    }
  }

  static setAutoLocale(): boolean {
    let lang = LocaleProvider.getSystemLanguage()
    if (LocaleProvider.setSpecifiedLocal(lang, true)) {
      AppStorage.set(Keys.LANGUAGE_IS_AUTO, true)
      return true
    }
    return false
  }

  static getLocalText(): Resource {
    if (AppStorage.get(Keys.LANGUAGE_IS_AUTO) === true) {
      console.log("显示跟随系统")
      return $r('app.string.flow_system')
    } else {
      console.log("显示指定语言")
      return $r('app.string.locale')
    }
  }

  static getSystemLanguage(): string {
    if (deviceInfo.sdkApiVersion < 20) {
      return i18n.getSystemLanguage()
    } else {
      return i18n.System.getSystemLanguage()
    }
  }
}