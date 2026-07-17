let storageWoodfish = new LocalStorage();

/**
 * 电子木鱼服务卡片（2×2）：点木鱼功德 +1。
 * 计数走 message 事件由 EntryFormAbility 落库（与 WoodFishPage 同一 woodfish key）。
 */
@Entry(storageWoodfish)
@Component
struct WoodfishCard {
  @LocalStorageProp('today') today: number = 0;
  @LocalStorageProp('total') total: number = 0;
  @State knockKey: number = 0;   // 敲击缩放动效

  private knock(): void {
    this.knockKey += 1;
    postCardAction(this, {
      action: 'message',
      params: { action: 'knock' }
    });
  }

  build() {
    Column({ space: 4 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('🪵')
          .fontSize(12)
        Text('电子木鱼')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
        Blank()
        Text(`共 ${this.total}`)
          .fontSize(10)
          .fontColor('#B3FFFFFF')
      }
      .width('100%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetTool: 'woodfish' }
        });
      })

      Blank()

      // 木鱼本体：点击敲击
      Text('🪵')
        .fontSize(52)
        .scale({
          x: this.knockKey % 2 === 0 ? 1 : 0.88,
          y: this.knockKey % 2 === 0 ? 1 : 0.88
        })
        .animation({ duration: 110, curve: Curve.EaseOut })
        .onClick(() => this.knock())

      Text(`今日功德 ${this.today}`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)

      Text('点击木鱼 · 功德 +1')
        .fontSize(9)
        .fontColor('#B3FFFFFF')

      Blank()
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#B79891', 0], ['#94716B', 1]] })
    .onClick(() => this.knock())
  }
}
