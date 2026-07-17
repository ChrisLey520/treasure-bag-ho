@Component
export struct ScoreboardPage {
  @State scoreA: number = 0;
  @State scoreB: number = 0;
  @State nameA: string = '红队';
  @State nameB: string = '蓝队';

  /**
   * 记分面板。注意：@Builder 值参数不参与状态观察（传 score 数字进来
   * 状态变了界面不刷新——曾导致"点击不加分"），必须在 Builder 内直接读 @State
   */
  @Builder
  scorePanel(team: number) {
    Column({ space: 14 }) {
      Text(team === 0 ? this.nameA : this.nameB)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)

      Text((team === 0 ? this.scoreA : this.scoreB).toString())
        .fontSize(80)
        .fontWeight(FontWeight.Bolder)
        .fontColor(Color.White)

      Row({ space: 14 }) {
        Button('−')
          .width(56).height(56)
          .fontSize(26)
          .backgroundColor('#33FFFFFF')
          .onClick(() => {
            if (team === 0) {
              this.scoreA = Math.max(0, this.scoreA - 1);
            } else {
              this.scoreB = Math.max(0, this.scoreB - 1);
            }
          })
        Button('+')
          .width(56).height(56)
          .fontSize(26)
          .backgroundColor('#4DFFFFFF')
          .onClick(() => {
            if (team === 0) {
              this.scoreA += 1;
            } else {
              this.scoreB += 1;
            }
          })
      }
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .layoutWeight(1)
    .borderRadius(24)
    .linearGradient({
      angle: 135,
      colors: team === 0 ? [['#F5576C', 0], ['#F093FB', 1]] : [['#4FACFE', 0], ['#00F2FE', 1]]
    })
    .onClick(() => {
      // 点面板任意处 +1（按钮点击不会冒泡到这里）
      if (team === 0) {
        this.scoreA += 1;
      } else {
        this.scoreB += 1;
      }
    })
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        this.scorePanel(0)
        this.scorePanel(1)

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
