const ANSWERS: string[] = [
  '是的', '不', '也许吧', '毫无疑问', '再想想', '放手去做', '时机未到', '相信直觉',
  '问问你的心', '别犹豫了', '这不值得', '答案就在眼前', '需要等待', '换个角度看',
  '当然可以', '很难说', '命运掌握在你手中', '顺其自然', '再坚持一下', '立刻行动',
  '不要回头', '值得一试', '风险很大', '你已经知道答案了', '找人聊聊', '睡一觉再说',
  '会有转机', '别想太多', '这是个好主意', '保持耐心'
];

@Component
export struct AnswerPage {
  @State answer: string = '';
  @State shaking: boolean = false;

  ask(): void {
    if (this.shaking) {
      return;
    }
    this.shaking = true;
    this.answer = '';
    setTimeout(() => {
      this.answer = ANSWERS[Math.floor(Math.random() * ANSWERS.length)];
      this.shaking = false;
    }, 800);
  }

  build() {
    NavDestination() {
      Column({ space: 30 }) {
        Blank()

        Text('🔮')
          .fontSize(90)
          .rotate({ angle: this.shaking ? 15 : 0 })
          .animation({ duration: 100, curve: Curve.Sharp, iterations: this.shaking ? -1 : 1 })

        Column({ space: 10 }) {
          Text('心中默念你的问题')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Text(this.shaking ? '……' : (this.answer.length > 0 ? `「 ${this.answer} 」` : '然后点击下方按钮'))
            .fontSize(this.answer.length > 0 ? 30 : 16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .textAlign(TextAlign.Center)
            .animation({ duration: 300, curve: Curve.EaseOut })
        }
        .height(110)

        Button(this.shaking ? '正在寻找答案…' : '寻求答案')
          .width(200)
          .height(54)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .linearGradient({ angle: 135, colors: [['#5B247A', 0], ['#1BCEDF', 1]] })
          .enabled(!this.shaking)
          .onClick(() => this.ask())

        Blank()
        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('答案之书')
    .backgroundColor($r('app.color.bg_page'))
  }
}
