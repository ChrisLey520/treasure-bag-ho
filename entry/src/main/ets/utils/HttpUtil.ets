import { http } from '@kit.NetworkKit';

export class HttpUtil {
  /** GET 请求返回文本，失败返回 undefined */
  static async getText(url: string, timeoutMs: number = 10000): Promise<string | undefined> {
    const req = http.createHttp();
    try {
      const resp = await req.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs,
        expectDataType: http.HttpDataType.STRING,
        header: { 'User-Agent': 'TreasureBag/1.0' }
      });
      if (resp.responseCode >= 200 && resp.responseCode < 300) {
        return resp.result as string;
      }
      console.error(`http ${resp.responseCode}: ${url}`);
      return undefined;
    } catch (err) {
      console.error('http failed:', JSON.stringify(err));
      return undefined;
    } finally {
      req.destroy();
    }
  }
}
