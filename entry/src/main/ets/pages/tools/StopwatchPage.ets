@Component
export struct StopwatchPage {
  @State elapsedMs: number = 0;
  @State running: boolean = false;
  @State laps: number[] = [];
  private timerId: number = -1;
  private lastTick: number = 0;

  aboutToDisappear(): void {
    this.pause();
  }

  start(): void {
    this.running = true;
    this.lastTick = Date.now();
    this.timerId = setInterval(() => {
      const now = Date.now();
      this.elapsedMs += now - this.lastTick;
      this.lastTick = now;
    }, 33);
  }

  pause(): void {
    this.running = false;
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  reset(): void {
    this.pause();
    this.elapsedMs = 0;
    this.laps = [];
  }

  lap(): void {
    this.laps = [this.elapsedMs, ...this.laps].slice(0, 50);
  }

  fmt(ms: number): string {
    const m = Math.floor(ms / 60000);
    const s = Math.floor(ms % 60000 / 1000);
    const cs = Math.floor(ms % 1000 / 10);
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}.${cs.toString().padStart(2, '0')}`;
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        // 主表盘
        Text(this.fmt(this.elapsedMs))
          .fontSize(64)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ top: 50 })

        Row({ space: 16 }) {
          Button(this.running ? '⏸ 暂停' : (this.elapsedMs > 0 ? '▶ 继续' : '▶ 开始'))
            .width(130).height(54)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .linearGradient({
              angle: 135,
              colors: this.running ? [['#F7971E', 0], ['#FFD200', 1]] : [['#11998E', 0], ['#38EF7D', 1]]
            })
            .onClick(() => {
              if (this.running) {
                this.pause();
              } else {
                this.start();
              }
            })

          if (this.running) {
            Button('🏁 计次')
              .width(130).height(54)
              .fontSize(16)
              .backgroundColor($r('app.color.accent'))
              .onClick(() => this.lap())
          } else if (this.elapsedMs > 0) {
            Button('重置')
              .width(130).height(54)
              .fontSize(16)
              .backgroundColor($r('app.color.bg_card'))
              .fontColor($r('app.color.text_primary'))
              .onClick(() => this.reset())
          }
        }

        List({ space: 6 }) {
          ForEach(this.laps, (lapMs: number, i: number) => {
            ListItem() {
              Row() {
                Text(`第 ${this.laps.length - i} 次`)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                Blank()
                // 与上一计次的差
                if (i < this.laps.length - 1) {
                  Text(`+${this.fmt(lapMs - this.laps[i + 1])}`)
                    .fontSize(13)
                    .fontColor($r('app.color.accent'))
                    .margin({ right: 14 })
                }
                Text(this.fmt(lapMs))
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
              }
              .width('100%')
              .padding({ top: 12, bottom: 12, left: 16, right: 16 })
              .borderRadius(12)
              .backgroundColor($r('app.color.bg_card'))
            }
          }, (lapMs: number, i: number) => `${this.laps.length - i}-${lapMs}`)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('秒表')
    .backgroundColor($r('app.color.bg_page'))
  }
}
