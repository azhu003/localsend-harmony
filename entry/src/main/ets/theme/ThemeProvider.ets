import { Keys } from '../constant';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { ThemeControl, window } from '@kit.ArkUI';
import { DefaultThemes } from './DefaultColors';
import { Errors, logger } from 'common';

export class ThemeProvider {
  static setThemeModel(model: ConfigurationConstant.ColorMode) {
    AppStorage.set(Keys.COLOR_MODE, model)
  }

  /**
   * 当前APP设置的颜色模式
   * @returns
   */
  static getThemeModel(): ConfigurationConstant.ColorMode {
    const mode: ConfigurationConstant.ColorMode | undefined = AppStorage.get<ConfigurationConstant.ColorMode>(Keys.COLOR_MODE)
    if (mode == undefined) {
      return ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
    } else {
      return mode
    }
  }

  static setSystemColorModeUpdate(system: ConfigurationConstant.ColorMode | undefined) {
    if (system == undefined) {
      system = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
    }
    AppStorage.setOrCreate(Keys.SYSTEM_COLOR_MODE, system)
    //若当前用户设置为跟随系统则切换
    ThemeProvider.setSystemStatusBarColor()
  }

  static setSystemStatusBarColor() {
    const colorMode: ConfigurationConstant.ColorMode = ThemeProvider.getThemeModel()
    let windowStage: window.WindowStage | undefined = AppStorage.get(Keys.WINDOW_STAGE);
    if (windowStage != undefined) {
      const mainWin: window.Window = windowStage.getMainWindowSync();
      let isDark: boolean
      //若当前设置为跟随系统，续再次检查系统是否为深色模式
      if (colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
        const system: ConfigurationConstant.ColorMode | undefined = AppStorage.get(Keys.SYSTEM_COLOR_MODE)
        isDark = system === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      } else {
        isDark = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
      }
      const props: window.SystemBarProperties = {
        statusBarContentColor: isDark ? "#D1D1D1" : "#171717",
      };
      mainWin.setWindowSystemBarProperties(props)
        .catch((e: Error) => {
          logger.warn("ThemeProvider", `设置系统状态栏失败 ${Errors.getErrorMessage(e)} `)
        });
      ThemeControl.setDefaultTheme(new DefaultThemes())
    }
  }

  static getThemeModelText(model: ConfigurationConstant.ColorMode): Resource {
    switch (model) {
      case ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET:
        return $r('app.string.flow_system')
      case ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT:
        return $r('app.string.light')
      case ConfigurationConstant.ColorMode.COLOR_MODE_DARK:
        return $r('app.string.dark')
    }
  }
}