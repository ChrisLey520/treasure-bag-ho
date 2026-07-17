let storageDecision = new LocalStorage();

/**
 * 随机决定服务卡片（2×2）：内置常用选项组，点击换一组，按按钮出结果。
 * 完整自定义选项请进 App。
 */
interface OptionSet {
  label: string;
  opts: string[];
}

const OPTION_SETS: OptionSet[] = [
  { label: '吃什么', opts: ['火锅', '烧烤', '日料', '面条', '炒饭', '轻食'] },
  { label: '做不做', opts: ['做！', '不做', '再想想'] },
  { label: '谁来做', opts: ['我来', '你来', '猜拳定'] },
  { label: '去哪玩', opts: ['公园', '商场', '电影院', '待在家', '近郊走走'] }
];

@Entry(storageDecision)
@Component
struct DecisionCard {
  @State setIdx: number = 0;
  @State result: string = '';
  @State rolled: number = 0;   // 触发弹跳动效

  /** 卡片不支持定时器：直接抽取，用缩放动效体现（滚动动画进 App 体验） */
  roll(): void {
    const opts = OPTION_SETS[this.setIdx].opts;
    let next = opts[Math.floor(Math.random() * opts.length)];
    if (next === this.result && opts.length > 1) {
      next = opts[(opts.indexOf(next) + 1) % opts.length];
    }
    this.result = next;
    this.rolled += 1;
  }

  build() {
    Column({ space: 6 }) {
      // 品牌行 + 选项组切换
      Row({ space: 5 }) {
        Text('🎯')
          .fontSize(12)
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: { targetTool: 'decision' }
            });
          })
        Text('随机决定')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
          .onClick(() => {
            postCardAction(this, {
              action: 'router',
              abilityName: 'EntryAbility',
              params: { targetTool: 'decision' }
            });
          })
        Blank()
        Text(OPTION_SETS[this.setIdx].label + ' ⌄')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
          .backgroundColor('#33FFFFFF')
          .onClick(() => {
            this.setIdx = (this.setIdx + 1) % OPTION_SETS.length;
            this.result = '';
          })
      }
      .width('100%')

      Blank()

      Text(this.result.length > 0 ? this.result : '❓')
        .fontSize(this.result.length > 0 ? 26 : 34)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .maxLines(1)
        .scale({ x: this.rolled % 2 === 0 ? 1 : 1.15, y: this.rolled % 2 === 0 ? 1 : 1.15 })
        .animation({ duration: 220, curve: Curve.EaseOut })

      Text(this.result.length > 0 ? '就它了！' : OPTION_SETS[this.setIdx].opts.join(' · '))
        .fontSize(10)
        .fontColor('#CCFFFFFF')
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      Blank()

      Text('帮我决定')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FC466B')
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(30)
        .borderRadius(15)
        .backgroundColor(Color.White)
        .onClick(() => this.roll())
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#FC466B', 0], ['#3F5EFB', 1]] })
  }
}
