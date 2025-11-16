import { Screens } from 'common';
import { AbilityConstant, ConfigurationConstant, EnvironmentCallback, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Configuration } from '@ohos.app.ability.Configuration';
import { DialogProvider } from '../utils/DialogProvider';
import { Keys } from '../constant';
import { PersistentStorageProvider } from '../utils';
import { ThemeProvider } from '../theme/ThemeProvider';
import { WindowUtils } from '../transaction/WindowUtils';
import { LocaleProvider } from '../locale';

export default class EntryAbility extends UIAbility {
  environmentCallbackId = -1
  environmentCallback: EnvironmentCallback = {

    onConfigurationUpdated(_: Configuration) {
      // 在此处理语言切换逻辑（如更新界面）
      if (AppStorage.get(Keys.LANGUAGE_IS_AUTO) === true) {
        // 获取当前系统语言
        const lang = LocaleProvider.getSystemLanguage()
        LocaleProvider.setSpecifiedLocal(lang, true)
      }
    },

    onMemoryLevel(_: AbilityConstant.MemoryLevel) {

    }
  }

  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    const applicationContext = this.context.getApplicationContext();
    this.environmentCallbackId = applicationContext.on('environment', this.environmentCallback);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    AppStorage.setOrCreate(Keys.WINDOW_STAGE, windowStage)

    WindowUtils.onWindowStageCreate(windowStage)

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        return
      }
      PersistentStorageProvider.init(this.context)

      //系统是否是深色模式
      let mode = this.context.config.colorMode
      ThemeProvider.setSystemColorModeUpdate(mode)
      this.context.getApplicationContext().setColorMode(ThemeProvider.getThemeModel());

      DialogProvider.init(this.context)

      let win: window.Window = windowStage.getMainWindowSync() // 获取应用主窗口
      win.setWindowLayoutFullScreen(true)
      AppStorage.setOrCreate('MainWindow', win)
      Screens.init(win)
    })
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    let newColorMode = newConfig.colorMode;
    let currentColorMode = AppStorage.get<ConfigurationConstant.ColorMode>(Keys.SYSTEM_COLOR_MODE);
    if (newColorMode == currentColorMode) {
      return
    }
    ThemeProvider.setSystemColorModeUpdate(newColorMode)
  }

  onWindowStageDestroy(): void {
  }

  onForeground(): void {
  }

  onBackground(): void {
  }

  onDestroy(): void {
    this.context.getApplicationContext().off('environment', this.environmentCallbackId)
  }
}
