let storageHabit = new LocalStorage();

/**
 * 习惯打卡服务卡片（2×2）：展示第一个习惯的连续天数，一键打卡。
 * 数据由 EntryFormAbility 与 HabitPage 共用 preferences（habits JSON）。
 */
@Entry(storageHabit)
@Component
struct HabitCard {
  @LocalStorageProp('name') name: string = '';
  @LocalStorageProp('emoji') emoji: string = '🌱';
  @LocalStorageProp('streak') streak: number = 0;
  @LocalStorageProp('doneToday') doneToday: boolean = false;

  build() {
    Column({ space: 6 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('🌱')
          .fontSize(12)
        Text('习惯打卡')
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
          params: { targetTool: 'habit' }
        });
      })

      Blank()

      if (this.name.length > 0) {
        Column({ space: 2 }) {
          Text(`${this.emoji} ${this.name}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#EEFFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Row() {
            Text(this.streak.toString())
              .fontSize(36)
              .fontWeight(FontWeight.Bolder)
              .fontColor(Color.White)
            Text(' 天')
              .fontSize(12)
              .fontColor('#CCFFFFFF')
              .margin({ bottom: 6 })
          }
          .alignItems(VerticalAlign.Bottom)
          Text('连续坚持')
            .fontSize(10)
            .fontColor('#B3FFFFFF')
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
      } else {
        Column({ space: 4 }) {
          Text('还没有习惯')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
          Text('点击去添加')
            .fontSize(11)
            .fontColor('#CCFFFFFF')
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { targetTool: 'habit' }
          });
        })
      }

      Blank()

      if (this.name.length > 0) {
        Text(this.doneToday ? '✓ 今日已打卡' : '打卡')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.doneToday ? '#CCFFFFFF' : '#56AB2F')
          .textAlign(TextAlign.Center)
          .width('100%')
          .height(32)
          .borderRadius(16)
          .backgroundColor(this.doneToday ? '#33FFFFFF' : Color.White)
          .onClick(() => {
            if (!this.doneToday) {
              postCardAction(this, {
                action: 'message',
                params: { action: 'habitCheckIn' }
              });
            }
          })
      }
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#56AB2F', 0], ['#A8E063', 1]] })
  }
}
