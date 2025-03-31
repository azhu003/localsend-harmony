import { DeviceProvider } from '.';
import { Keys } from '../constant';
import { util } from '@kit.ArkTS';
import { AutoSaveModel, DeviceType } from '../model';
import { ConfigurationConstant } from '@kit.AbilityKit';

/**
 * 用于初始化所有需要持久化保存的数据
 */
export class PersistentStorageProvider {
  static init(context: Context) {
    //主题：默认跟随系统
    PersistentStorage.persistProp(Keys.COLOR_MODE, ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    //PIN：默认不开启PIN
    PersistentStorage.persistProp(Keys.USE_PIN_WHEN_RECEIVE, undefined)
    //保存接收记录
    PersistentStorage.persistProp(Keys.SAVE_RECEIVE_RECORD, true)
    //随机生成一个别名
    PersistentStorage.persistProp(Keys.ALIAS, DeviceProvider.getRandomAlias(context.resourceManager))
    //设备类型
    PersistentStorage.persistProp<DeviceType>(Keys.DEVICE_TYPE, 'mobile')
    //设备型号
    PersistentStorage.persistProp(Keys.DEVICE_MODE, 'HarmonyOS')
    //组播地址
    PersistentStorage.persistProp(Keys.MULTICAST_ADDRESS, '224.0.0.167')
    //指纹
    PersistentStorage.persistProp(Keys.FINGERPRINT, util.generateRandomUUID())
    //自动保存模: 默认关闭
    PersistentStorage.persistProp(Keys.AUTO_SAVE_MODEL, AutoSaveModel.CLOSE)
    //Web服务监听端口
    PersistentStorage.persistProp(Keys.PORT, 53317)
    //开发者模式: 默认关闭
    PersistentStorage.persistProp(Keys.IS_DEV_MODE, false)
  }
}