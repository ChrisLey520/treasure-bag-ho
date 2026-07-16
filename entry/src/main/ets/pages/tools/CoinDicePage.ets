const DICE_FACES: string[] = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅'];

@Component
export struct CoinDicePage {
  @State mode: number = 0; // 0=硬币 1=骰子
  @State coinResult: string = '';
  @State diceCount: number = 1;
  @State diceResults: number[] = [];
  @State rolling: boolean = false;
  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
    }
  }

  flip(): void {
    if (this.rolling) {
      return;
    }
    this.rolling = true;
    let count = 0;
    this.timerId = setInterval(() => {
      this.coinResult = Math.random() < 0.5 ? '正面' : '反面';
      count += 1;
      if (count >= 12) {
        clearInterval(this.timerId);
        this.timerId = -1;
        this.rolling = false;
      }
    }, 80);
  }

  roll(): void {
    if (this.rolling) {
      return;
    }
    this.rolling = true;
    let count = 0;
    this.timerId = setInterval(() => {
      const results: number[] = [];
      for (let i = 0; i < this.diceCount; i++) {
        results.push(Math.floor(Math.random() * 6) + 1);
      }
      this.diceResults = results;
      count += 1;
      if (count >= 12) {
        clearInterval(this.timerId);
        this.timerId = -1;
        this.rolling = false;
      }
    }, 80);
  }

  diceSum(): number {
    let sum = 0;
    for (const v of this.diceResults) {
      sum += v;
    }
    return sum;
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
          // 硬币
          Text(this.coinResult.length === 0 ? '🪙' : (this.coinResult === '正面' ? '🌕' : '🌑'))
            .fontSize(120)
            .rotate({ angle: this.rolling ? 180 : 0, x: 1, y: 0, z: 0 })
            .animation({ duration: 80, curve: Curve.Linear })
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
          // 骰子
          Row({ space: 12 }) {
            ForEach(this.diceResults, (v: number, i: number) => {
              Text(DICE_FACES[v - 1])
                .fontSize(this.diceCount <= 2 ? 100 : 64)
                .fontColor($r('app.color.text_primary'))
            }, (v: number, i: number) => `${i}-${v}`)
            if (this.diceResults.length === 0) {
              Text('🎲').fontSize(100)
            }
          }
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
