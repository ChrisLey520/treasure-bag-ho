import { ToolStore } from '../../utils/ToolStore';

enum FocusState {
  IDLE,
  FOCUS,
  BREAK
}

const PRESETS: number[] = [15, 25, 45, 60];
const BREAK_MINUTES = 5;
const STORE_KEY = 'focus';

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}

@Component
export struct FocusPage {
  @State state: FocusState = FocusState.IDLE;
  @State focusMinutes: number = 25;
  @State remain: number = 25 * 60;
  @State rounds: number = 0;
  private timerId: number = -1;

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    // rounds|date 按天持久化
    const saved = await ToolStore.get(ctx, STORE_KEY, '');
    if (saved.length > 0) {
      const parts = saved.split('|');
      if (parts[1] === todayStr()) {
        this.rounds = parseInt(parts[0]) || 0;
      }
    }
  }

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
    this.state = FocusState.FOCUS;
    this.remain = this.focusMinutes * 60;
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
      if (this.state === FocusState.FOCUS) {
        this.rounds += 1;
        ToolStore.save(STORE_KEY, `${this.rounds}|${todayStr()}`);
        this.state = FocusState.BREAK;
        this.remain = BREAK_MINUTES * 60;
      } else {
        this.state = FocusState.FOCUS;
        this.remain = this.focusMinutes * 60;
      }
    }, 1000);
  }

  reset(): void {
    this.clearTimer();
    this.state = FocusState.IDLE;
    this.remain = this.focusMinutes * 60;
  }

  fmtTime(): string {
    const m = Math.floor(this.remain / 60).toString().padStart(2, '0');
    const s = (this.remain % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  progress(): number {
    const total = this.state === FocusState.BREAK ? BREAK_MINUTES * 60 : this.focusMinutes * 60;
    return (1 - this.remain / total) * 100;
  }

  stateText(): string {
    if (this.state === FocusState.FOCUS) { return '专注中 · 心无旁骛'; }
    if (this.state === FocusState.BREAK) { return '休息一下 · 站起来走走'; }
    return '选择时长，开始沉浸';
  }

  build() {
    NavDestination() {
      Column({ space: 26 }) {
        Blank()

        Stack() {
          // 底环
          Progress({ value: 100, total: 100, type: ProgressType.Ring })
            .width(250).height(250)
            .style({ strokeWidth: 12 })
            .color('#22FFFFFF')
          Progress({ value: this.progress(), total: 100, type: ProgressType.Ring })
            .width(250).height(250)
            .style({ strokeWidth: 12 })
            .color(this.state === FocusState.BREAK ? '#26D0CE' : '#7F7FD5')

          Column({ space: 8 }) {
            Text(this.state === FocusState.BREAK ? '☕' : '⏳').fontSize(30)
            Text(this.fmtTime())
              .fontSize(54)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text(this.stateText())
              .fontSize(13)
              .fontColor('#99FFFFFF')
          }
        }

        // 时长预设（仅空闲时可选）
        if (this.state === FocusState.IDLE) {
          Row({ space: 10 }) {
            ForEach(PRESETS, (m: number) => {
              Text(`${m} 分`)
                .fontSize(14)
                .fontWeight(this.focusMinutes === m ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.focusMinutes === m ? '#1A2980' : '#CCFFFFFF')
                .padding({ left: 16, right: 16, top: 9, bottom: 9 })
                .borderRadius(18)
                .backgroundColor(this.focusMinutes === m ? Color.White : '#22FFFFFF')
                .onClick(() => {
                  this.focusMinutes = m;
                  this.remain = m * 60;
                })
            }, (m: number) => m.toString())
          }
        }

        Text(`今日已完成 ${this.rounds} 段专注`)
          .fontSize(13)
          .fontColor('#99FFFFFF')

        if (this.state === FocusState.IDLE) {
          Button('开始专注')
            .width(190).height(54)
            .fontSize(17).fontWeight(FontWeight.Bold)
            .fontColor('#1A2980')
            .backgroundColor(Color.White)
            .onClick(() => this.start())
        } else {
          Button('放弃本段')
            .width(150).height(50)
            .backgroundColor('#33FFFFFF')
            .fontColor(Color.White)
            .onClick(() => this.reset())
        }

        Blank()
        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('专注时钟')
    .backgroundColor(Color.Transparent)
    .linearGradient({ angle: 160, colors: [['#1A2980', 0], ['#26D0CE', 1]] })
  }
}
