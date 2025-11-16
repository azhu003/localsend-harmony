import resmgr from '@ohos.resourceManager';
import { Errors, logger, Objects, Strings } from 'common';
import { DeviceModel } from '../model/DeviceModel';
import { util } from '@kit.ArkTS';
import { Keys } from '../constant';
import { MulticastModel, NearbyDeviceModel } from '../model';
import wifiManager from '@ohos.wifiManager';
import { RandomUtil } from '@pura/harmony-utils';
import { DeviceMapper } from '../db/mapper/DeviceMapper';
import { deviceInfo } from '@kit.BasicServicesKit';

export class DeviceProvider {
  static REGISTERED_DEVICE_LIST_KEY = "REGISTERED_DEVICE_LIST_KEY"

  static getDeviceFingerprint(): string {
    return AppStorage.get(Keys.FINGERPRINT) || util.generateRandomUUID()
  }

  static getRandomAlias(resource: resmgr.ResourceManager): string {
    try {
      let adjectives = resource.getStringArrayValueSync($r('app.strarray.alias_adjectives').id)
      let fruits = resource.getStringArrayValueSync($r('app.strarray.alias_fruits').id)

      let adjective = adjectives[RandomUtil.getRandomInt(0, adjectives.length)]
      let fruit = fruits[RandomUtil.getRandomInt(0, fruits.length)]

      let alias = resource.getStringSync($r('app.string.alias_combination').id)
      return Strings.formatString(alias, adjective, fruit)
    } catch (e) {
      logger.warn('DeviceProvider', `随机生成设备名称失败: ${Errors.getErrorMessage(e)}`)
      return 'Oh, oh'
    }
  }

  static async addOrReplaceDevice(device: DeviceModel) {
    const allDevice: NearbyDeviceModel[] = DeviceProvider.getAllDevice()
    const nearby: NearbyDeviceModel = NearbyDeviceModel.create(device)
    await new DeviceMapper().insertOrUpdate(nearby)
    let findIndex = allDevice.findIndex((item: NearbyDeviceModel) => item.key === nearby.key)
    if (findIndex > -1) {
      allDevice[findIndex] = Objects.clone(allDevice[findIndex], device)
    } else {
      allDevice.push(nearby)
    }
    AppStorage.setOrCreate(DeviceProvider.REGISTERED_DEVICE_LIST_KEY, allDevice)
  }

  static getDevice(hostname: string): DeviceModel | undefined {
    const key = `device_${hostname}`
    const allDevice: NearbyDeviceModel[] | undefined = AppStorage.get(DeviceProvider.REGISTERED_DEVICE_LIST_KEY)
    if (allDevice) {
      const findIndex = allDevice.findIndex((value: NearbyDeviceModel) => value.key === key)
      if (findIndex > -1) {
        return allDevice[findIndex]
      }
    }
    return undefined
  }

  static getAllDevice(): Array<NearbyDeviceModel> {
    return AppStorage.get(DeviceProvider.REGISTERED_DEVICE_LIST_KEY) || []
  }

  static getCurrentDevice(): DeviceModel {
    return new MulticastModel()
  }

  static getIpv4Address(): string {
    const ipNumber = wifiManager.getIpInfo().ipAddress
    if (ipNumber <= 0) {
      return ""
    }
    const ip3 = (ipNumber << 0) >>> 24;
    const ip2 = (ipNumber << 8) >>> 24;
    const ip1 = (ipNumber << 16) >>> 24;
    const ip0 = (ipNumber << 24) >>> 24
    return ip3 + "." + ip2 + "." + ip1 + "." + ip0
  }
}
