import { HttpUtil } from '../../utils/HttpUtil';

interface IpInfo {
  success?: boolean;
  ip?: string;
  country?: string;
  region?: string;
  city?: string;
  isp?: string;
  timezone_id?: string;
  latitude?: number;
  longitude?: number;
  connection?: IpConnection;
}

interface IpConnection {
  isp?: string;
  org?: string;
}

@Component
export struct IpLookupPage {
  @State input: string = '';
  @State info?: IpInfo = undefined;
  @State loading: boolean = false;
  @State error: string = '';

  async query(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    this.error = '';
    this.info = undefined;
    const target = this.input.trim();
    // 空输入查本机出口 IP
    const url = target.length > 0
      ? `https://ipwho.is/${encodeURIComponent(target)}?lang=zh-CN`
      : 'https://ipwho.is/?lang=zh-CN';
    const text = await HttpUtil.getText(url);
    if (text === undefined) {
      this.error = '网络请求失败，请检查网络';
      this.loading = false;
      return;
    }
    try {
      const parsed = JSON.parse(text) as IpInfo;
      if (parsed.success === false) {
        this.error = 'IP / 域名无效或查询失败';
      } else {
        this.info = parsed;
      }
    } catch (err) {
      this.error = '数据解析失败';
    }
    this.loading = false;
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor($r('app.color.text_secondary')).width(80)
      Text(value)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .textAlign(TextAlign.End)
        .maxLines(2)
        .copyOption(CopyOptions.LocalDevice)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Row({ space: 10 }) {
          TextInput({ placeholder: '输入 IP（留空查本机）', text: this.input })
            .layoutWeight(1)
            .height(46)
            .borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onChange((v: string) => { this.input = v; })
            .onSubmit(() => this.query())
          Button(this.loading ? '…' : '查询')
            .height(46)
            .backgroundColor($r('app.color.accent'))
            .enabled(!this.loading)
            .onClick(() => this.query())
        }
        .width('100%')

        if (this.error.length > 0) {
          Text(this.error)
            .fontSize(13).fontColor('#F5576C')
            .width('100%').padding(12)
            .borderRadius(10).backgroundColor('#1AF5576C')
        }

        if (this.info !== undefined) {
          Column({ space: 4 }) {
            Text(this.info.ip ?? '')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .copyOption(CopyOptions.LocalDevice)
            Text(`${this.info.country ?? ''} ${this.info.region ?? ''} ${this.info.city ?? ''}`)
              .fontSize(15)
              .fontColor('#CCFFFFFF')
          }
          .width('100%')
          .padding(24)
          .borderRadius(20)
          .linearGradient({ angle: 135, colors: [['#1A2980', 0], ['#26D0CE', 1]] })

          Column() {
            this.infoRow('运营商', this.info.connection?.isp ?? this.info.isp ?? '—')
            Divider().margin({ left: 16, right: 16 })
            this.infoRow('组织', this.info.connection?.org ?? '—')
            Divider().margin({ left: 16, right: 16 })
            this.infoRow('时区', this.info.timezone_id ?? '—')
            Divider().margin({ left: 16, right: 16 })
            this.infoRow('经纬度', this.info.latitude !== undefined
              ? `${this.info.latitude?.toFixed(4)}, ${this.info.longitude?.toFixed(4)}`
              : '—')
          }
          .width('100%')
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
        }

        if (this.info === undefined && this.error.length === 0) {
          Column({ space: 8 }) {
            Text('🌐').fontSize(56)
            Text('查询 IP 归属地、运营商、时区\n留空直接查询本机出口 IP')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
              .lineHeight(22)
          }
          .margin({ top: 80 })
        }

        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('IP 定位')
    .backgroundColor($r('app.color.bg_page'))
  }
}
