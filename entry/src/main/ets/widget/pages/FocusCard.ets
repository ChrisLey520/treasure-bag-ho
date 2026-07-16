let storageCard = new LocalStorage();

@Entry(storageCard)
@Component
struct FocusCard {
  @LocalStorageProp('running') running: boolean = false;
  @LocalStorageProp('endText') endText: string = '';

  build() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Text('⏳').fontSize(16)
        Text('专注时钟')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        Blank()
      }
      .width('100%')

      Blank()

      if (this.running) {
        Column({ space: 2 }) {
          Text('专注中')
            .fontSize(12)
            .fontColor('#99FFFFFF')
          Text(`至 ${this.endText}`)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      } else {
        Column({ space: 2 }) {
          Text('沉浸 25 分钟')
            .fontSize(12)
            .fontColor('#99FFFFFF')
          Text('心无旁骛')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      Blank()

      Button(this.running ? '放弃' : '开始专注')
        .width('100%')
        .height(36)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.running ? Color.White : '#1A2980')
        .backgroundColor(this.running ? '#33FFFFFF' : Color.White)
        .onClick(() => {
          postCardAction(this, {
            action: 'message',
            params: { action: this.running ? 'stop' : 'start' }
          });
        })
    }
    .padding(14)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 160, colors: [['#1A2980', 0], ['#26D0CE', 1]] })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetTool: 'focus' }
      });
    })
  }
}
