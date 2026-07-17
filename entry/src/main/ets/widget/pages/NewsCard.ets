let storageNews = new LocalStorage();

/**
 * 60 秒早报服务卡片（2×4）：今日 4 条要闻标题。
 * 数据由 EntryFormAbility 拉取 60s API（每天早晨定时刷新）。
 */
@Entry(storageNews)
@Component
struct NewsCard {
  @LocalStorageProp('date') date: string = '';
  @LocalStorageProp('n0') n0: string = '';
  @LocalStorageProp('n1') n1: string = '';
  @LocalStorageProp('n2') n2: string = '';
  @LocalStorageProp('n3') n3: string = '';

  private itemAt(i: number): string {
    if (i === 0) { return this.n0; }
    if (i === 1) { return this.n1; }
    if (i === 2) { return this.n2; }
    return this.n3;
  }

  @Builder
  newsRow(i: number) {
    Row({ space: 6 }) {
      Text('')
        .width(4)
        .height(4)
        .borderRadius(2)
        .backgroundColor('#FF512F')
        .margin({ top: 6 })
      Text(this.itemAt(i))
        .fontSize(11)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 3, bottom: 3 })
  }

  build() {
    Column({ space: 4 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('📰')
          .fontSize(12)
        Text('60 秒早报')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        if (this.date.length > 0) {
          Text(this.date)
            .fontSize(9)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .width('100%')

      if (this.n0.length === 0) {
        Blank()
        Column({ space: 4 }) {
          Text('📰')
            .fontSize(26)
          Text('等待今日早报…')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text('点击进 App 立即查看')
            .fontSize(10)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        Blank()
      } else {
        Column({ space: 0 }) {
          this.newsRow(0)
          if (this.n1.length > 0) {
            this.newsRow(1)
          }
          if (this.n2.length > 0) {
            this.newsRow(2)
          }
          if (this.n3.length > 0) {
            this.newsRow(3)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
      }
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetTool: 'dailynews' }
      });
    })
  }
}
