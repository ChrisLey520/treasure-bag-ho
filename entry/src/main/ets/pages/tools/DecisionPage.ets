@Component
export struct DecisionPage {
  @State optionsText: string = '吃火锅\n吃烧烤\n吃日料\n减肥不吃';
  @State result: string = '';
  @State rolling: boolean = false;
  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
    }
  }

  options(): string[] {
    return this.optionsText.split('\n').map(s => s.trim()).filter(s => s.length > 0);
  }

  roll(): void {
    const opts = this.options();
    if (opts.length < 2 || this.rolling) {
      return;
    }
    this.rolling = true;
    let count = 0;
    this.timerId = setInterval(() => {
      this.result = opts[Math.floor(Math.random() * opts.length)];
      count += 1;
      if (count >= 20) {
        clearInterval(this.timerId);
        this.timerId = -1;
        this.rolling = false;
      }
    }, 80);
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Column({ space: 8 }) {
          Text(this.result.length > 0 ? this.result : '❓')
            .fontSize(this.result.length > 0 ? 36 : 50)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .maxLines(1)
          Text(this.rolling ? '命运的齿轮正在转动…' : (this.result.length > 0 ? '就它了！' : '添加选项后点击开始'))
            .fontSize(13)
            .fontColor('#CCFFFFFF')
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(160)
        .borderRadius(24)
        .linearGradient({ angle: 135, colors: [['#FC466B', 0], ['#3F5EFB', 1]] })
        .shadow({ radius: 16, color: '#FC466B55', offsetY: 6 })

        Column({ space: 8 }) {
          Text('选项（每行一个）')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .alignSelf(ItemAlign.Start)
          TextArea({ text: this.optionsText })
            .layoutWeight(1)
            .borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onChange((v: string) => { this.optionsText = v; })
        }
        .layoutWeight(1)

        Button(this.rolling ? '选择中…' : '🎯 帮我决定')
          .width('100%').height(54)
          .fontSize(17).fontWeight(FontWeight.Bold)
          .linearGradient({ angle: 135, colors: [['#FC466B', 0], ['#3F5EFB', 1]] })
          .enabled(!this.rolling && this.options().length >= 2)
          .onClick(() => this.roll())
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('随机决定')
    .backgroundColor($r('app.color.bg_page'))
  }
}
