import { pasteboard } from '@kit.BasicServicesKit';
import { HttpUtil } from '../../utils/HttpUtil';

@Component
export struct WebSourcePage {
  @State url: string = '';
  @State source: string = '';
  @State loading: boolean = false;
  @State error: string = '';

  async fetchSource(): Promise<void> {
    let target = this.url.trim();
    if (target.length === 0 || this.loading) {
      return;
    }
    if (!target.startsWith('http://') && !target.startsWith('https://')) {
      target = 'https://' + target;
    }
    this.loading = true;
    this.error = '';
    this.source = '';
    const text = await HttpUtil.getText(target, 15000);
    if (text === undefined) {
      this.error = '请求失败：网络错误或该网站拒绝访问';
    } else {
      // 防止超长文本卡 UI
      this.source = text.length > 100000 ? text.substring(0, 100000) + '\n\n…（已截断，仅显示前 100K 字符）' : text;
    }
    this.loading = false;
  }

  copyAll(): void {
    if (this.source.length === 0) {
      return;
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.source);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: '已复制源码', duration: 1200 });
    }).catch((err: Error) => {
      console.error('copy failed:', err.message);
    });
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        Row({ space: 10 }) {
          TextInput({ placeholder: '输入网址，如 example.com', text: this.url })
            .layoutWeight(1)
            .height(46)
            .borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onChange((v: string) => { this.url = v; })
            .onSubmit(() => this.fetchSource())
          Button(this.loading ? '…' : '获取')
            .height(46)
            .backgroundColor($r('app.color.accent'))
            .enabled(!this.loading)
            .onClick(() => this.fetchSource())
        }
        .width('100%')

        if (this.error.length > 0) {
          Text(this.error)
            .fontSize(13).fontColor('#F5576C')
            .width('100%').padding(12)
            .borderRadius(10).backgroundColor('#1AF5576C')
        }

        Row() {
          Text(this.source.length > 0 ? `${this.source.length} 字符` : '')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Blank()
          if (this.source.length > 0) {
            Text('复制全部')
              .fontSize(13)
              .fontColor($r('app.color.accent'))
              .onClick(() => this.copyAll())
          }
        }
        .width('100%')

        Scroll() {
          Text(this.source.length > 0 ? this.source : (this.loading ? '获取中…' : '网页 HTML 源码将显示在这里'))
            .fontSize(12)
            .fontColor(this.source.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
            .fontFamily('monospace')
            .width('100%')
            .copyOption(CopyOptions.LocalDevice)
        }
        .layoutWeight(1)
        .width('100%')
        .padding(14)
        .borderRadius(14)
        .backgroundColor($r('app.color.bg_card'))
        .align(Alignment.TopStart)
        .scrollable(ScrollDirection.Vertical)
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('网页源码')
    .backgroundColor($r('app.color.bg_page'))
  }
}
