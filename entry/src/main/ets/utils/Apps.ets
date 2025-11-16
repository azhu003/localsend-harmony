import { common, OpenLinkOptions, Want } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';

export class Apps {
  /**
   * 跳转至Download文件夹
   * @param context
   * @returns
   */
  static toAppDownloadFolder(context: common.UIAbilityContext): Promise<void> {
    if (deviceInfo.sdkApiVersion < 12) {
      let want: Want = {
        bundleName: 'com.huawei.hmos.filemanager',
        abilityName: 'MainAbility'
      };
      return context.startAbility(want);
    } else {
      let link: string = 'filemanager://openDirectory';
      let openLinkOptions: OpenLinkOptions = {
        parameters: {
          fileUri: 'file:///storage/Users/currentUser/Download/' + context.applicationInfo.name + '/'
        }
      };
      return context.openLink(link, openLinkOptions)
    }
  }


}