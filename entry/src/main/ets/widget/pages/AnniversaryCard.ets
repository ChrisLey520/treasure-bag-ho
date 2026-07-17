let storageAnni = new LocalStorage();

/**
 * 纪念日/倒数日服务卡片（2×2）：展示最近的一条纪念日倒计时。
 * 数据由 EntryFormAbility 从 preferences 读取推送；onUpdateForm 每日刷新天数。
 */
@Entry(storageAnni)
@Component
struct AnniversaryCard {
  @LocalStorageProp('name') name: string = '';
  @LocalStorageProp('dayText') dayText: string = '';
  @LocalStorageProp('dateText') dateText: string = '';

  build() {
    Column({ space: 6 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('💝')
          .fontSize(12)
        Text('纪念日')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
        Blank()
      }
      .width('100%')

      Blank()

      if (this.name.length > 0) {
        Column({ space: 4 }) {
          Text(this.name)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#EEFFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.dayText)
            .fontSize(24)
            .fontWeight(FontWeight.Bolder)
            .fontColor(Color.White)
            .maxLines(1)
          Text(this.dateText)
            .fontSize(10)
            .fontColor('#B3FFFFFF')
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
      } else {
        Column({ space: 4 }) {
          Text('还没有纪念日')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
          Text('点击添加倒数日')
            .fontSize(11)
            .fontColor('#CCFFFFFF')
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
      }

      Blank()
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#EC008C', 0], ['#FC6767', 1]] })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetTool: 'anniversary' }
      });
    })
  }
}
