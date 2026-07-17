let storageWater = new LocalStorage();

/**
 * 喝水提醒服务卡片（2×2）：桌面直接打卡 +1，与 App 内共用 preferences 数据。
 * 打卡走 message 事件由 EntryFormAbility 落库并回推新数据。
 */
@Entry(storageWater)
@Component
struct WaterCard {
  @LocalStorageProp('cups') cups: number = 0;
  @LocalStorageProp('goal') goal: number = 8;

  build() {
    Column({ space: 6 }) {
      // 品牌行：点击进 App
      Row({ space: 5 }) {
        Text('💧')
          .fontSize(12)
        Text('喝水提醒')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
        Blank()
      }
      .width('100%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetTool: 'water' }
        });
      })

      Blank()

      // 进度：今日杯数 / 目标
      Column({ space: 2 }) {
        Row() {
          Text(this.cups.toString())
            .fontSize(40)
            .fontWeight(FontWeight.Bolder)
            .fontColor(Color.White)
          Text(` / ${this.goal} 杯`)
            .fontSize(13)
            .fontColor('#CCFFFFFF')
            .margin({ bottom: 7 })
        }
        .alignItems(VerticalAlign.Bottom)

        // 进度条
        Row() {
          Text('')
            .width(`${Math.min(100, this.cups / this.goal * 100)}%`)
            .height(6)
            .borderRadius(3)
            .backgroundColor(Color.White)
        }
        .width('100%')
        .height(6)
        .borderRadius(3)
        .backgroundColor('#33FFFFFF')
        .justifyContent(FlexAlign.Start)
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')

      Blank()

      Text(this.cups >= this.goal ? '🎉 目标达成' : '+1 杯')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4FACFE')
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(32)
        .borderRadius(16)
        .backgroundColor(Color.White)
        .onClick(() => {
          postCardAction(this, {
            action: 'message',
            params: { action: 'drink' }
          });
        })
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#4FACFE', 0], ['#00F2FE', 1]] })
  }
}
