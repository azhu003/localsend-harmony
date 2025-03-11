/**
 * AppStorage KEY
 */
export class Keys {
  private constructor() {
  }

  static WINDOW_STAGE = 'WINDOW_STAGE'
  /**
   * 系统颜色模式
   */
  static SYSTEM_COLOR_MODE = 'SYSTEM_COLOR_MODE'
  /**
   * 当前APP设置的颜色模式
   */
  static COLOR_MODE = 'COLOR_MODE'
  /**
   * 接收时开启PIN码 string
   */
  static USE_PIN_WHEN_RECEIVE = 'USE_PIN_WHEN_RECEIVE'
  /**
   * 保存到历史记录 bool
   */
  static SAVE_RECEIVE_RECORD = 'SAVE_RECEIVE_RECORD'
  /**
   * WebService已开启 bool
   */
  static SERVICE_IS_ONLINE = 'SERVICE_IS_ONLINE'
  /**
   * 设备类型
   */
  static DEVICE_TYPE = 'DEVICE_TYPE'
  /**
   * 设备型号
   */
  static DEVICE_MODE = 'DEVICE_MODE'
  /**
   * UDP组播地址
   */
  static MULTICAST_ADDRESS = 'MULTICAST_ADDRESS'
  /**
   * 当前是否正处于文件传输状态
   * value = [boolean]
   */
  static CURRENTLY_TRANSFERRING_STATUS = 'CURRENTLY_TRANSFERRING_STATUS'
  /**
   * 当前设备别名
   * value = [string]
   */
  static ALIAS = 'alias'
  /**
   * HttpService监听端口
   * value = [string]
   */
  static PORT = 'PORT'
  /**
   * 当前设备指纹
   * value = [string]
   */
  static FINGERPRINT = 'fingerprint'
  /**
   * 当前设置的自动保存类型
   * value = [AutoSaveModel]
   */
  static AUTO_SAVE_MODEL = 'AUTO_SAVE_MODEL'
  /**
   * 当前正在接收的请求sessionId
   * value = [string]
   */
  static CURRENTLY_RECEIVING_SESSION = 'CURRENTLY_RECEIVING_SESSION'
  /**
   * 开发者模式
   */
  static IS_DEV_MODE = 'IS_DEV_MODE'
}