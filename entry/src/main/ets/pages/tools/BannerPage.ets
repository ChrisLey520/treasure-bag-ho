const BG_COLORS: string[] = ['#000000', '#F5576C', '#5B6BF5', '#43E97B', '#FEE140', '#FFFFFF'];
const TEXT_COLORS: string[] = ['#FFFFFF', '#FFD700', '#00F2FE', '#FF512F', '#1A1D26'];

@Component
export struct BannerPage {
  @State text: string = '前面的朋友你好！';
  @State bgIndex: number = 0;
  @State textIndex: number = 0;
  @State fontSize: number = 120;
  @State speed: number = 5;
  @State playing: boolean = false;
  @State offsetX: number = 0;
  private timerId: number = -1;
  private screenW: number = 720;

  aboutToDisappear(): void {
    this.stop();
  }

  start(): void {
    this.playing = true;
    this.offsetX = this.screenW;
    // 简易滚动：定时平移
    this.timerId = setInterval(() => {
      this.offsetX -= this.speed * 3;
      if (this.offsetX < -this.text.length * this.fontSize) {
        this.offsetX = this.screenW;
      }
    }, 16);
  }

  stop(): void {
    this.playing = false;
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    NavDestination() {
      if (this.playing) {
        // ── 全屏弹幕模式（横向文字滚动，点击退出）──
        Stack() {
          Text(this.text)
            .fontSize(this.fontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(TEXT_COLORS[this.textIndex])
            .maxLines(1)
            .translate({ x: this.offsetX })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(BG_COLORS[this.bgIndex])
        .alignContent(Alignment.Start)
        .onClick(() => this.stop())
      } else {
        // ── 编辑模式 ──
        Column({ space: 16 }) {
          TextInput({ placeholder: '输入弹幕内容', text: this.text })
            .height(50).borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onChange((v: string) => { this.text = v; })

          Column({ space: 8 }) {
            Text('背景色').fontSize(13).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
            Row({ space: 10 }) {
              ForEach(BG_COLORS, (c: string, i: number) => {
                Column()
                  .width(36).height(36).borderRadius(18)
                  .backgroundColor(c)
                  .border({ width: this.bgIndex === i ? 3 : 1, color: this.bgIndex === i ? $r('app.color.accent') : '#33888888' })
                  .onClick(() => { this.bgIndex = i; })
              }, (c: string) => 'bg' + c)
            }.alignSelf(ItemAlign.Start)
          }
          .width('100%').padding(16).borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
          .alignItems(HorizontalAlign.Start)

          Column({ space: 8 }) {
            Text('文字色').fontSize(13).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
            Row({ space: 10 }) {
              ForEach(TEXT_COLORS, (c: string, i: number) => {
                Column()
                  .width(36).height(36).borderRadius(18)
                  .backgroundColor(c)
                  .border({ width: this.textIndex === i ? 3 : 1, color: this.textIndex === i ? $r('app.color.accent') : '#33888888' })
                  .onClick(() => { this.textIndex = i; })
              }, (c: string) => 'tx' + c)
            }.alignSelf(ItemAlign.Start)
          }
          .width('100%').padding(16).borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
          .alignItems(HorizontalAlign.Start)

          Column({ space: 6 }) {
            Row() {
              Text('滚动速度').fontSize(14).fontColor($r('app.color.text_secondary'))
              Blank()
              Text(this.speed.toFixed(0)).fontSize(14).fontColor($r('app.color.text_primary'))
            }.width('100%')
            Slider({ value: this.speed, min: 1, max: 10, step: 1 })
              .onChange((v: number) => { this.speed = v; })
          }
          .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))

          Button('▶ 开始播放（横屏效果最佳）')
            .width('100%').height(54)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .linearGradient({ angle: 135, colors: [['#1A1D26', 0], ['#5B6BF5', 1]] })
            .onClick(() => this.start())

          Text('播放中点击屏幕即可退出')
            .fontSize(12).fontColor($r('app.color.text_secondary'))
        }
        .padding(20)
        .width('100%')
        .height('100%')
      }
    }
    .title(this.playing ? '' : '手持弹幕')
    .hideTitleBar(this.playing)
    .backgroundColor($r('app.color.bg_page'))
  }
}
