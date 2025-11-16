import { common, OpenLinkOptions, Want, wantConstant } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { mime } from './mime';
import { fileUri } from '@kit.CoreFileKit';

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

  static async useOtherAppOpenFile(context: common.UIAbilityContext, filepath: string): Promise<void> {
    try {
      console.log(`打开文件 格式 -> ${mime.getType(filepath)} path: ${filepath}`)
      let uri = fileUri.getUriFromPath(filepath);
      // 构造请求数据
      let want: Want = {
        action: 'ohos.want.action.viewData', // 表示查看数据的操作，文件打开场景固定为此值
        uri: uri,
        type: mime.getType(filepath) || '*/*', // 表示待打开文件的类型
        // 配置被分享文件的读写权限，例如对文件打开应用进行读写授权
        flags: wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION
      };
      return await context.startAbility(want)
    } catch (error) {
      console.error(`Open file failed: ${JSON.stringify(error)}`);
      return Promise.reject(error)
    }
  }
}