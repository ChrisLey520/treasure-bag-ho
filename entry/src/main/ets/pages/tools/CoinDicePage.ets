/** 骰子 3×3 点阵：每个点数对应的亮点位置（行优先） */
const PIP_MAP: number[][] = [
  [0, 0, 0, 0, 1, 0, 0, 0, 0],   // 1
  [0, 0, 1, 0, 0, 0, 1, 0, 0],   // 2
  [0, 0, 1, 0, 1, 0, 1, 0, 0],   // 3
  [1, 0, 1, 0, 0, 0, 1, 0, 1],   // 4
  [1, 0, 1, 0, 1, 0, 1, 0, 1],   // 5
  [1, 0, 1, 1, 0, 1, 1, 0, 1]    // 6
];

@Component
export struct CoinDicePage {
  @State mode: number = 0; // 0=硬币 1=骰子
  @State coinResult: string = '';
  @State diceCount: number = 1;
  @State diceResults: number[] = [];
  @State rolling: boolean = false;
  @State spin: number = 0;        // 骰子翻滚角度（累计）
  @State coinSpin: number = 0;    // 硬币翻转角度（累计）
  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearTimeout(this.timerId);
    }
  }

  flip(): void {
    if (this.rolling) {
      return;
    }
    this.rolling = true;
    this.coinResult = '';
    // 连续翻转若干整圈（180 的偶数倍保证停在正面朝上）
    this.coinSpin += 1800;
    this.timerId = setTimeout(() => {
      this.timerId = -1;
      this.coinResult = Math.random() < 0.5 ? '正面' : '反面';
      this.rolling = false;
    }, 1000);
  }

  roll(): void {
    if (this.rolling) {
      return;
    }
    this.rolling = true;
    // 翻滚整数圈，动画结束时回到端正姿态，随后一次性定点数
    this.spin += 1080;
    this.timerId = setTimeout(() => {
      this.timerId = -1;
      const results: number[] = [];
      for (let i = 0; i < this.diceCount; i++) {
        results.push(Math.floor(Math.random() * 6) + 1);
      }
      this.diceResults = results;
      this.rolling = false;
    }, 1000);
  }

  diceSum(): number {
    let sum = 0;
    for (const v of this.diceResults) {
      sum += v;
    }
    return sum;
  }

  /** 展示用点数数组：未出结果时按当前骰子数显示 1 点占位 */
  shownDice(): number[] {
    if (this.diceResults.length === this.diceCount) {
      return this.diceResults;
    }
    const arr: number[] = [];
    for (let i = 0; i < this.diceCount; i++) {
      arr.push(1);
    }
    return arr;
  }

  /** 拟真骰子：白面、圆角、内凹阴影点 */
  @Builder
  dieFace(value: number, size: number) {
    Column() {
      ForEach([0, 1, 2], (row: number) => {
        Row() {
          ForEach([0, 1, 2], (col: number) => {
            Text('')
              .width(size * 0.16)
              .height(size * 0.16)
              .borderRadius(size * 0.08)
              .backgroundColor(PIP_MAP[value - 1][row * 3 + col] === 1 ? '#1A1D26' : Color.Transparent)
          }, (col: number) => `c${col}`)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
      }, (row: number) => `r${row}`)
    }
    .width(size)
    .height(size)
    .padding(size * 0.14)
    .borderRadius(size * 0.18)
    .backgroundColor(Color.White)
    .border({ width: 1, color: '#22000000' })
    .shadow({ radius: size * 0.12, color: '#33000000', offsetY: size * 0.05 })
  }

  build() {
    NavDestination() {
      Column({ space: 24 }) {
        // 模式切换
        Row({ space: 10 }) {
          ForEach(['🪙 抛硬币', '🎲 摇骰子'], (label: string, i: number) => {
            Text(label)
              .fontSize(15)
              .fontWeight(this.mode === i ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.mode === i ? Color.White : $r('app.color.text_secondary'))
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .borderRadius(20)
              .backgroundColor(this.mode === i ? $r('app.color.accent') : $r('app.color.bg_card'))
              .onClick(() => { this.mode = i; })
          }, (label: string) => label)
        }
        .margin({ top: 20 })

        Blank()

        if (this.mode === 0) {
          // 硬币：绕 X 轴连续翻转，停下后亮结果
          Text(this.coinResult === '' ? '🪙' : (this.coinResult === '正面' ? '🌕' : '🌑'))
            .fontSize(120)
            .rotate({ x: 1, y: 0, z: 0, angle: this.coinSpin })
            .animation({ duration: 1000, curve: Curve.EaseOut })
          Text(this.rolling ? '…' : (this.coinResult.length > 0 ? this.coinResult : '点击下方按钮'))
            .fontSize(this.coinResult.length > 0 && !this.rolling ? 34 : 16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Button('抛！')
            .width(180).height(54)
            .fontSize(17).fontWeight(FontWeight.Bold)
            .linearGradient({ angle: 135, colors: [['#F7971E', 0], ['#FFD200', 1]] })
            .enabled(!this.rolling)
            .onClick(() => this.flip())
        } else {
          // 骰子：拟真点阵骰子，绕斜轴翻滚一段时间后停在点数
          Row({ space: 16 }) {
            ForEach(this.shownDice(), (v: number, i: number) => {
              Column() {
                this.dieFace(v, this.diceCount <= 2 ? 110 : 76)
              }
              .rotate({ x: 1, y: 1, z: 0.3, angle: this.spin })
              .animation({ duration: 1000, curve: Curve.EaseOut })
            }, (v: number, i: number) => `${i}`)
          }
          .height(130)
          .alignItems(VerticalAlign.Center)

          if (this.diceResults.length > 1 && !this.rolling) {
            Text(`总点数：${this.diceSum()}`)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.accent'))
          }
          Row({ space: 8 }) {
            ForEach([1, 2, 3], (n: number) => {
              Text(`${n} 个`)
                .fontSize(13)
                .fontColor(this.diceCount === n ? Color.White : $r('app.color.text_secondary'))
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .borderRadius(15)
                .backgroundColor(this.diceCount === n ? $r('app.color.accent') : $r('app.color.bg_card'))
                .onClick(() => {
                  this.diceCount = n;
                  this.diceResults = [];
                })
            }, (n: number) => n.toString())
          }
          Button('摇！')
            .width(180).height(54)
            .fontSize(17).fontWeight(FontWeight.Bold)
            .linearGradient({ angle: 135, colors: [['#E53935', 0], ['#E35D5B', 1]] })
            .enabled(!this.rolling)
            .onClick(() => this.roll())
        }

        Blank()
        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('硬币 · 骰子')
    .backgroundColor($r('app.color.bg_page'))
  }
}
