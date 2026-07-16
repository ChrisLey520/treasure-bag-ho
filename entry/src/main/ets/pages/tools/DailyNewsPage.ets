import { HttpUtil } from '../../utils/HttpUtil';

interface NewsData {
  news?: string[];
  tip?: string;
  date?: string;
}

interface NewsResponse {
  code?: number;
  data?: NewsData;
}

@Component
export struct DailyNewsPage {
  @State news: string[] = [];
  @State tip: string = '';
  @State date: string = '';
  @State loading: boolean = false;
  @State error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    if (this.loading) {
      return;
    }
    this.loading = true;
    this.error = '';
    // 60s API（开源项目 vikiboss/60s，免 key）
    const text = await HttpUtil.getText('https://60s.viki.moe/v2/60s');
    if (text === undefined) {
      this.error = '获取早报失败，请检查网络后下拉重试';
      this.loading = false;
      return;
    }
    try {
      const parsed = JSON.parse(text) as NewsResponse;
      if (parsed.data !== undefined) {
        this.news = parsed.data.news ?? [];
        this.tip = parsed.data.tip ?? '';
        this.date = parsed.data.date ?? '';
      } else {
        this.error = '数据格式异常';
      }
    } catch (err) {
      this.error = '数据解析失败';
    }
    this.loading = false;
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        if (this.loading && this.news.length === 0) {
          Column({ space: 12 }) {
            LoadingProgress().width(40).height(40).color($r('app.color.accent'))
            Text('正在获取今日早报…')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .margin({ top: 150 })
        } else if (this.error.length > 0 && this.news.length === 0) {
          Column({ space: 14 }) {
            Text('😵').fontSize(48)
            Text(this.error)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            Button('重试')
              .backgroundColor($r('app.color.accent'))
              .onClick(() => this.load())
          }
          .margin({ top: 130 })
        } else {
          Column({ space: 6 }) {
            Text('📰 每天 60 秒读懂世界')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text(this.date)
              .fontSize(13)
              .fontColor('#CCFFFFFF')
          }
          .width('100%')
          .padding(20)
          .borderRadius(20)
          .linearGradient({ angle: 135, colors: [['#FF512F', 0], ['#F09819', 1]] })
          .alignItems(HorizontalAlign.Start)

          List({ space: 8 }) {
            ForEach(this.news, (item: string, i: number) => {
              ListItem() {
                Row({ space: 10 }) {
                  Text(`${i + 1}`)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.accent'))
                    .width(22)
                  Text(item)
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                    .lineHeight(22)
                    .layoutWeight(1)
                    .copyOption(CopyOptions.LocalDevice)
                }
                .alignItems(VerticalAlign.Top)
                .width('100%')
                .padding(14)
                .borderRadius(12)
                .backgroundColor($r('app.color.bg_card'))
              }
            }, (item: string, i: number) => `${i}`)

            if (this.tip.length > 0) {
              ListItem() {
                Text(`💡 ${this.tip}`)
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                  .padding(14)
                  .borderRadius(12)
                  .backgroundColor('#1A5B6BF5')
              }
            }
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('60 秒早报')
    .backgroundColor($r('app.color.bg_page'))
  }
}
