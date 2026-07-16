const TEST_COLORS: string[] = ['#FF0000', '#00FF00', '#0000FF', '#FFFFFF', '#000000', '#808080'];
const COLOR_NAMES: string[] = ['红', '绿', '蓝', '白', '黑', '灰'];

@Component
export struct DeadPixelPage {
  @State testing: boolean = false;
  @State index: number = 0;

  build() {
    NavDestination() {
      if (this.testing) {
        // 全屏纯色，点击切换，最后一屏点击退出
        Column() {
          Text(`${COLOR_NAMES[this.index]} (${this.index + 1}/${TEST_COLORS.length}) · 点击继续`)
            .fontSize(13)
            .fontColor(this.index === 3 ? '#66000000' : '#66FFFFFF')
            .margin({ top: 80 })
          Blank()
        }
        .width('100%')
        .height('100%')
        .backgroundColor(TEST_COLORS[this.index])
        .onClick(() => {
          if (this.index < TEST_COLORS.length - 1) {
            this.index += 1;
          } else {
            this.testing = false;
            this.index = 0;
          }
        })
      } else {
        Column({ space: 20 }) {
          Text('🔍')
            .fontSize(70)
            .margin({ top: 60 })

          Text('屏幕坏点检测')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))

          Text('将依次全屏显示红、绿、蓝、白、黑、灰 6 种纯色。\n仔细观察屏幕，若某处颜色异常或不亮，\n则该处可能存在坏点。')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .lineHeight(24)

          Row({ space: 8 }) {
            ForEach(TEST_COLORS, (c: string) => {
              Column()
                .width(32).height(32).borderRadius(8)
                .backgroundColor(c)
                .border({ width: 1, color: '#33888888' })
            }, (c: string) => c)
          }

          Button('开始检测')
            .width(200).height(54)
            .fontSize(17).fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => {
              this.testing = true;
            })
        }
        .padding(20)
        .width('100%')
        .height('100%')
      }
    }
    .title(this.testing ? '' : '屏幕坏点检测')
    .hideTitleBar(this.testing)
    .backgroundColor($r('app.color.bg_page'))
  }
}
