let storageLedger = new LocalStorage();

/**
 * 极简记账服务卡片（2×2）：本月支出/收入一目了然，点击进 App 记一笔。
 * 数据由 EntryFormAbility 从 preferences（ledger JSON）汇总下发，每日刷新。
 */
@Entry(storageLedger)
@Component
struct LedgerCard {
  @LocalStorageProp('expense') expense: string = '0';
  @LocalStorageProp('income') income: string = '0';
  @LocalStorageProp('monthText') monthText: string = '';

  build() {
    Column({ space: 6 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('📒')
          .fontSize(12)
        Text('极简记账')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
        Blank()
        Text(this.monthText)
          .fontSize(10)
          .fontColor('#B3FFFFFF')
      }
      .width('100%')

      Blank()

      Column({ space: 2 }) {
        Text('本月支出')
          .fontSize(10)
          .fontColor('#B3FFFFFF')
        Row() {
          Text('¥')
            .fontSize(14)
            .fontColor(Color.White)
            .margin({ bottom: 4 })
          Text(this.expense)
            .fontSize(30)
            .fontWeight(FontWeight.Bolder)
            .fontColor(Color.White)
            .maxLines(1)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')

      Row({ space: 4 }) {
        Text('收入')
          .fontSize(10)
          .fontColor('#B3FFFFFF')
        Text(`¥${this.income}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#7FFFD4')
      }
      .justifyContent(FlexAlign.Center)
      .width('100%')

      Blank()

      Text('+ 记一笔')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4286F4')
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(30)
        .borderRadius(15)
        .backgroundColor(Color.White)
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#373B44', 0], ['#4286F4', 1]] })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetTool: 'ledger' }
      });
    })
  }
}
