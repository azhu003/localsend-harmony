import { buffer, JSON, uri } from '@kit.ArkTS';
import { HttpError } from '../../../../Index';
import { getLogger, Logger } from '../utils';
import { HttpExchangeImpl } from '../http/impl';

const HTTP_VERSION_V1 = 'HTTP/1.1'
const EMPTY_DATA: object = Object

const logger: Logger = getLogger('Parser')

export class Parser {
  static parseHeader(header: string, exchange: HttpExchangeImpl) {
    if (exchange.isEnd) {
      return
    }
    // 把socket字符串按照换行符分割成多行，并取出第一行
    const lines: string[] = header.split(/[\r\n]+/);
    let line: string | undefined = lines.shift();

    // 把第一行按照空格分割，得到请求行数据 {POST /index HTTP/1.1}
    let status: string[] = line?.split(' ') || []
    if (status.length != 3) {
      logger.error(`--- parse http protocol error: ${line}`)
      throw HttpError.error(400, "Bad Request")
    }

    exchange.setRequestMethod(status[0].toUpperCase())
    try {
      //获取URL请求路径和URL参数
      let original = status[1]
      const result: uri.URI = new uri.URI(original)
      const queryNames = result.getQueryNames()
      for (let name of queryNames) {
        exchange.query.set(name, result.getQueryValue(name))
      }
      exchange.originalUrl = original
      exchange.path = result.path
      exchange.protocol = status[2]
    } catch (e) {
      logger.error(`--- parse header error: ${JSON.stringify(e)} message: ${e?.message} stack:\n ${e?.stack}`)
      throw HttpError.error(400, "Bad Request")
    }

    // 请求头
    line = lines.shift();
    while (line) {
      const index: number = line.indexOf(':');
      if (index > 0) {
        exchange.getRequestHeaders().setHeader(line.substring(0, index), line.substring(index + 1).trim())
      }
      line = lines.shift()
    }

    const connection = exchange.getRequestHeaders().getHeader('connection')
    if (HTTP_VERSION_V1 === exchange.protocol && (connection === undefined || !(/close/ig.test(connection)))) {
      exchange.setKeepLive()
    }
  }

  static parseJson<T>(body: buffer.Buffer): T {
    const data = body.toString()
    if (!data) {
      return EMPTY_DATA as T
    }
    return JSON.parse(data) as T
  }
}