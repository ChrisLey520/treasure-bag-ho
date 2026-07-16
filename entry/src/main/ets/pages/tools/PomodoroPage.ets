enum PomodoroState {
  IDLE,
  FOCUS,
  BREAK
}

const FOCUS_SECONDS = 25 * 60;
const BREAK_SECONDS = 5 * 60;

@Component
export struct PomodoroPage {
  @State state: PomodoroState = PomodoroState.IDLE;
  @State remain: number = FOCUS_SECONDS;
  @State rounds: number = 0;
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

  start(): void {
    this.state = PomodoroState.FOCUS;
    this.remain = FOCUS_SECONDS;
    this.tick();
  }

  tick(): void {
    this.clearTimer();
    this.timerId = setInterval(() => {
      if (this.remain > 1) {
        this.remain -= 1;
        return;
      }
      // 阶段切换
      if (this.state === PomodoroState.FOCUS) {
        this.rounds += 1;
        this.state = PomodoroState.BREAK;
        this.remain = BREAK_SECONDS;
      } else {
        this.state = PomodoroState.FOCUS;
        this.remain = FOCUS_SECONDS;
      }
    }, 1000);
  }

  reset(): void {
    this.clearTimer();
    this.state = PomodoroState.IDLE;
    this.remain = FOCUS_SECONDS;
  }

  fmtTime(): string {
    const m = Math.floor(this.remain / 60).toString().padStart(2, '0');
    const s = (this.remain % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  progress(): number {
    const total = this.state === PomodoroState.BREAK ? BREAK_SECONDS : FOCUS_SECONDS;
    return (1 - this.remain / total) * 100;
  }

  stateText(): string {
    if (this.state === PomodoroState.FOCUS) { return '专注中 🎯'; }
    if (this.state === PomodoroState.BREAK) { return '休息一下 ☕'; }
    return '准备开始';
  }

  build() {
    NavDestination() {
      Column({ space: 30 }) {
        Blank()

        Stack() {
          Progress({ value: this.progress(), total: 100, type: ProgressType.Ring })
            .width(240).height(240)
            .style({ strokeWidth: 14 })
            .color(this.state === PomodoroState.BREAK ? '#43E97B' : '#FF512F')

          Column({ space: 8 }) {
            Text(this.fmtTime())
              .fontSize(56)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(this.stateText())
              .fontSize(15)
              .fontColor($r('app.color.text_secondary'))
          }
        }

        Text(`今日完成 ${this.rounds} 个番茄 🍅`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))

        Row({ space: 16 }) {
          if (this.state === PomodoroState.IDLE) {
            Button('开始专注')
              .width(180).height(54)
              .fontSize(17).fontWeight(FontWeight.Bold)
              .linearGradient({ angle: 135, colors: [['#FF512F', 0], ['#DD2476', 1]] })
              .onClick(() => this.start())
          } else {
            Button('放弃')
              .width(140).height(50)
              .backgroundColor($r('app.color.bg_card'))
              .fontColor($r('app.color.text_primary'))
              .onClick(() => this.reset())
          }
        }

        Blank()
        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('番茄钟')
    .backgroundColor($r('app.color.bg_page'))
  }
}
