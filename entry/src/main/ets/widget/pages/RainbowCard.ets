let storageRainbow = new LocalStorage();

/** 与 App 内 RainbowPage 同一文案库 */
const PRAISES: string[] = [
  '你的笑容比阳光还灿烂，看到你的那一刻，我的世界都亮了。',
  '和你聊天就像在读一本好书，每一句都让人回味无穷。',
  '你不是锦上添花，你是雪中送炭还自带暖气。',
  '如果优秀有形状，那一定是你的轮廓。',
  '你解决问题的样子，比任何大片都精彩。',
  '别人是努力发光，你是天生就亮。',
  '你的想法总是那么独特，和你相处永远不会无聊。',
  '你一开口，会议室的智商平均值都被拉高了。',
  '你的品味就像你的人一样出众。',
  '认识你之后，我才知道"靠谱"两个字怎么写。',
  '你随手一做的东西，都是别人努力半天的天花板。',
  '你的存在本身，就是对"优秀"最好的诠释。',
  '跟你学到的东西，比我看十本书都多。',
  '你笑起来的时候，连空气都是甜的。',
  '宇宙这么大，能遇到你这么好的人，是我的幸运。'
];

/**
 * 彩虹屁服务卡片（2×2）：显示一句夸人金句，点击换一句（连续不重复）。
 */
@Entry(storageRainbow)
@Component
struct RainbowCard {
  @State current: string = PRAISES[0];
  @State changed: number = 0;   // 换句动效

  private next(): void {
    let n = PRAISES[Math.floor(Math.random() * PRAISES.length)];
    if (n === this.current && PRAISES.length > 1) {
      n = PRAISES[(PRAISES.indexOf(n) + 1) % PRAISES.length];
    }
    this.current = n;
    this.changed += 1;
  }

  build() {
    Column({ space: 6 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('🌈')
          .fontSize(12)
        Text('彩虹屁')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
        Blank()
        Text('换一句')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
          .backgroundColor('#33FFFFFF')
          .onClick(() => this.next())
      }
      .width('100%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetTool: 'rainbow' }
        });
      })

      Blank()

      Text(this.current)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .lineHeight(19)
        .textAlign(TextAlign.Center)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .scale({ x: this.changed % 2 === 0 ? 1 : 1.03, y: this.changed % 2 === 0 ? 1 : 1.03 })
        .animation({ duration: 220, curve: Curve.EaseOut })

      Blank()
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#FF9A9E', 0], ['#FAD0C4', 1]] })
    .onClick(() => this.next())
  }
}
