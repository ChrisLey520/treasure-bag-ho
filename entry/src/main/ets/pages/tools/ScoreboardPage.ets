@Component
export struct ScoreboardPage {
  @State scoreA: number = 0;
  @State scoreB: number = 0;
  @State nameA: string = '红队';
  @State nameB: string = '蓝队';

  @Builder
  scorePanel(name: string, score: number, colors: [string, string], add: () => void, minus: () => void) {
    Column({ space: 14 }) {
      Text(name)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)

      Text(score.toString())
        .fontSize(80)
        .fontWeight(FontWeight.Bolder)
        .fontColor(Color.White)

      Row({ space: 14 }) {
        Button('−')
          .width(56).height(56)
          .fontSize(26)
          .backgroundColor('#33FFFFFF')
          .onClick(() => minus())
        Button('+')
          .width(56).height(56)
          .fontSize(26)
          .backgroundColor('#4DFFFFFF')
          .onClick(() => add())
      }
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .layoutWeight(1)
    .borderRadius(24)
    .linearGradient({ angle: 135, colors: [[colors[0], 0], [colors[1], 1]] })
    .onClick(() => add())
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        this.scorePanel(this.nameA, this.scoreA, ['#F5576C', '#F093FB'],
          () => { this.scoreA += 1; },
          () => { this.scoreA = Math.max(0, this.scoreA - 1); })

        this.scorePanel(this.nameB, this.scoreB, ['#4FACFE', '#00F2FE'],
          () => { this.scoreB += 1; },
          () => { this.scoreB = Math.max(0, this.scoreB - 1); })

        Button('重置比分')
          .width('100%').height(48)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .onClick(() => {
            this.scoreA = 0;
            this.scoreB = 0;
          })
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('记分牌')
    .backgroundColor($r('app.color.bg_page'))
  }
}
