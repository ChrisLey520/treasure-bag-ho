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

@Component
export struct RainbowPage {
  @State current: string = '点击下方按钮，生成一句彩虹屁 🌈';

  build() {
    NavDestination() {
      Column({ space: 30 }) {
        Blank()

        Text(this.current)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .lineHeight(32)
          .padding(28)
          .width('100%')
          .constraintSize({ minHeight: 180 })
          .borderRadius(24)
          .linearGradient({ angle: 135, colors: [['#FF9A9E', 0], ['#FAD0C4', 1]] })
          .shadow({ radius: 16, color: '#FF9A9E55', offsetY: 6 })
          .copyOption(CopyOptions.LocalDevice)

        Button('🌈 来一句')
          .width(200).height(54)
          .fontSize(17).fontWeight(FontWeight.Bold)
          .linearGradient({ angle: 135, colors: [['#F5576C', 0], ['#F093FB', 1]] })
          .onClick(() => {
            let next = this.current;
            while (next === this.current) {
              next = PRAISES[Math.floor(Math.random() * PRAISES.length)];
            }
            this.current = next;
          })

        Text('长按文字可复制')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))

        Blank()
        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('彩虹屁')
    .backgroundColor($r('app.color.bg_page'))
  }
}
