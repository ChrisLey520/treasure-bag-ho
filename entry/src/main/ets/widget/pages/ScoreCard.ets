let storageScore = new LocalStorage();

/**
 * 记分牌服务卡片（2×2）：红蓝两队并排，点上半 +1、点 − 减 1，长按重置进 App。
 * 卡片内状态本地保存（卡片存续期内有效）。
 */
@Entry(storageScore)
@Component
struct ScoreCard {
  @State scoreA: number = 0;
  @State scoreB: number = 0;

  @Builder
  panel(team: number) {
    Column({ space: 2 }) {
      Text(team === 0 ? '红队' : '蓝队')
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CCFFFFFF')
      Text((team === 0 ? this.scoreA : this.scoreB).toString())
        .fontSize(34)
        .fontWeight(FontWeight.Bolder)
        .fontColor(Color.White)
        .layoutWeight(1)
      Text('−')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(24)
        .borderRadius(8)
        .backgroundColor('#33000000')
        .onClick(() => {
          if (team === 0) {
            this.scoreA = Math.max(0, this.scoreA - 1);
          } else {
            this.scoreB = Math.max(0, this.scoreB - 1);
          }
        })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(8)
    .layoutWeight(1)
    .height('100%')
    .borderRadius(14)
    .linearGradient({
      angle: 135,
      colors: team === 0 ? [['#F5576C', 0], ['#F093FB', 1]] : [['#4FACFE', 0], ['#00F2FE', 1]]
    })
    .onClick(() => {
      // 点面板（除 − 按钮外）+1
      if (team === 0) {
        this.scoreA += 1;
      } else {
        this.scoreB += 1;
      }
    })
  }

  build() {
    Column({ space: 6 }) {
      // 品牌行：点击进 App；右侧重置
      Row({ space: 5 }) {
        Text('🏆')
          .fontSize(12)
        Text('记分牌')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text('归零')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
          .backgroundColor($r('app.color.bg_card'))
          .onClick(() => {
            this.scoreA = 0;
            this.scoreB = 0;
          })
      }
      .width('100%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetTool: 'scoreboard' }
        });
      })

      // 两队并排
      Row({ space: 6 }) {
        this.panel(0)
        this.panel(1)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .padding(10)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
