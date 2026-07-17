let storageCoinDice = new LocalStorage();

/** 骰子 3×3 点阵（与 App 内 CoinDicePage 同款） */
const PIP_MAP: number[][] = [
  [0, 0, 0, 0, 1, 0, 0, 0, 0],
  [0, 0, 1, 0, 0, 0, 1, 0, 0],
  [0, 0, 1, 0, 1, 0, 1, 0, 0],
  [1, 0, 1, 0, 0, 0, 1, 0, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 1, 1, 0, 1, 1, 0, 1]
];

/**
 * 硬币·骰子服务卡片（2×2）：点骰子翻滚出点数，右上角切硬币模式。
 * 卡片无定时器：翻滚用累计旋转 + animation，动效结束点数已定
 * （出结果与动画同帧提交，转动中视觉上无法辨认点数变化）。
 */
@Entry(storageCoinDice)
@Component
struct CoinDiceCard {
  @State mode: number = 0;        // 0 骰子 1 硬币
  @State value: number = 1;       // 骰子点数
  @State coinFace: string = '';   // 正面/反面
  @State spin: number = 0;        // 累计旋转角

  private roll(): void {
    this.spin += 1080;
    if (this.mode === 0) {
      this.value = Math.floor(Math.random() * 6) + 1;
    } else {
      this.coinFace = Math.random() < 0.5 ? '正面' : '反面';
    }
  }

  /** 拟真骰面（缩小版） */
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
    .shadow({ radius: size * 0.1, color: '#33000000', offsetY: size * 0.04 })
  }

  build() {
    Column({ space: 4 }) {
      // 品牌行 + 模式切换
      Row({ space: 5 }) {
        Text('🪙')
          .fontSize(12)
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: { targetTool: 'coindice' }
            });
          })
        Text('硬币 · 骰子')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: { targetTool: 'coindice' }
            });
          })
        Blank()
        Text(this.mode === 0 ? '🎲 骰子' : '🪙 硬币')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
          .backgroundColor('#33FFFFFF')
          .onClick(() => {
            this.mode = this.mode === 0 ? 1 : 0;
            this.coinFace = '';
          })
      }
      .width('100%')

      Blank()

      if (this.mode === 0) {
        Column() {
          this.dieFace(this.value, 62)
        }
        .rotate({ x: 1, y: 1, z: 0.3, angle: this.spin })
        .animation({ duration: 900, curve: Curve.EaseOut })
        .onClick(() => this.roll())

        Text('点骰子摇一摇')
          .fontSize(9)
          .fontColor('#CCFFFFFF')
          .margin({ top: 6 })
      } else {
        Text(this.coinFace === '' ? '🪙' : (this.coinFace === '正面' ? '🌕' : '🌑'))
          .fontSize(56)
          .rotate({ x: 1, y: 0, z: 0, angle: this.spin })
          .animation({ duration: 900, curve: Curve.EaseOut })
          .onClick(() => this.roll())

        Text(this.coinFace.length > 0 ? this.coinFace : '点硬币抛一抛')
          .fontSize(this.coinFace.length > 0 ? 13 : 9)
          .fontWeight(this.coinFace.length > 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.coinFace.length > 0 ? Color.White : '#CCFFFFFF')
          .margin({ top: 6 })
      }

      Blank()
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#F7971E', 0], ['#FFD200', 1]] })
    .onClick(() => this.roll())
  }
}
