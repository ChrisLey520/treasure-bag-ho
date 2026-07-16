@Component
export struct FakeCallPage {
  @State callerName: string = '老板';
  @State delaySec: number = 5;
  @State waiting: boolean = false;
  @State ringing: boolean = false;
  @State inCall: boolean = false;
  @State callSeconds: number = 0;
  @State countdown: number = 0;
  private timerId: number = -1;

  aboutToDisappear(): void {
    this.clearTimer();
  }

  clearTimer(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  schedule(): void {
    this.waiting = true;
    this.countdown = this.delaySec;
    this.timerId = setInterval(() => {
      if (this.countdown > 1) {
        this.countdown -= 1;
        return;
      }
      this.clearTimer();
      this.waiting = false;
      this.ringing = true;
    }, 1000);
  }

  answer(): void {
    this.ringing = false;
    this.inCall = true;
    this.callSeconds = 0;
    this.timerId = setInterval(() => {
      this.callSeconds += 1;
    }, 1000);
  }

  hangup(): void {
    this.clearTimer();
    this.ringing = false;
    this.inCall = false;
  }

  fmtCall(): string {
    const m = Math.floor(this.callSeconds / 60).toString().padStart(2, '0');
    const s = (this.callSeconds % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  build() {
    NavDestination() {
      if (this.ringing || this.inCall) {
        // ── 全屏来电界面 ──
        Column() {
          Blank()
          Column({ space: 12 }) {
            Column()
              .width(96).height(96).borderRadius(48)
              .linearGradient({ angle: 135, colors: [['#5B6BF5', 0], ['#9B59B6', 1]] })
            Text(this.callerName)
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text(this.inCall ? this.fmtCall() : '来电…')
              .fontSize(16)
              .fontColor('#AAFFFFFF')
          }
          Blank()
          Blank()
          Row() {
            if (this.ringing) {
              Column({ space: 8 }) {
                Button('拒绝')
                  .width(72).height(72).borderRadius(36)
                  .backgroundColor('#F5576C')
                  .fontSize(14)
                  .onClick(() => this.hangup())
              }
              Blank()
              Column({ space: 8 }) {
                Button('接听')
                  .width(72).height(72).borderRadius(36)
                  .backgroundColor('#43E97B')
                  .fontSize(14)
                  .onClick(() => this.answer())
              }
            } else {
              Blank()
              Button('挂断')
                .width(72).height(72).borderRadius(36)
                .backgroundColor('#F5576C')
                .fontSize(14)
                .onClick(() => this.hangup())
              Blank()
            }
          }
          .width('70%')
          .margin({ bottom: 70 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#101218')
      } else {
        // ── 设置界面 ──
        Column({ space: 16 }) {
          Column({ space: 8 }) {
            Text('来电人').fontSize(13).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
            TextInput({ text: this.callerName })
              .height(48).borderRadius(12)
              .backgroundColor($r('app.color.bg_page'))
              .fontColor($r('app.color.text_primary'))
              .onChange((v: string) => { this.callerName = v; })
          }
          .width('100%').padding(16).borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
          .alignItems(HorizontalAlign.Start)

          Column({ space: 6 }) {
            Row() {
              Text('延迟触发').fontSize(14).fontColor($r('app.color.text_secondary'))
              Blank()
              Text(`${this.delaySec} 秒后`).fontSize(14).fontColor($r('app.color.text_primary'))
            }.width('100%')
            Slider({ value: this.delaySec, min: 3, max: 60, step: 1 })
              .onChange((v: number) => { this.delaySec = v; })
          }
          .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))

          if (this.waiting) {
            Column({ space: 10 }) {
              Text(`${this.countdown}`)
                .fontSize(60).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.accent'))
              Text('秒后来电，请把手机放好 🤫')
                .fontSize(14).fontColor($r('app.color.text_secondary'))
              Button('取消')
                .backgroundColor($r('app.color.bg_card'))
                .fontColor($r('app.color.text_primary'))
                .onClick(() => {
                  this.clearTimer();
                  this.waiting = false;
                })
            }
            .margin({ top: 30 })
          } else {
            Button('📞 设置来电')
              .width('100%').height(54)
              .fontSize(17).fontWeight(FontWeight.Bold)
              .linearGradient({ angle: 135, colors: [['#11998E', 0], ['#38EF7D', 1]] })
              .onClick(() => this.schedule())

            Text('饭局解围神器：设定几秒后"老板来电"，体面离场')
              .fontSize(12).fontColor($r('app.color.text_secondary'))
          }
        }
        .padding(20)
        .width('100%')
        .height('100%')
      }
    }
    .title(this.ringing || this.inCall ? '' : '来电模拟')
    .hideTitleBar(this.ringing || this.inCall)
    .backgroundColor($r('app.color.bg_page'))
  }
}
