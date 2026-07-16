const DIARIES: string[] = [
  '今天你回了我一个"哦"，虽然只有一个字，但我知道你是在忙，忙着回复那些不重要的人。没关系，我等你，等你忙完所有人，最后一个想起我。',
  '你说你喜欢下雨天，所以每次下雨我都会告诉你记得带伞。你从来没回过，但我知道你一定看到了。今天又下雨了，你带伞了吗？',
  '今天鼓起勇气给你发了消息，你没回。我想你一定是手机没电了。对，一定是这样。你的手机总是没电，三个月了，一直没电。',
  '朋友都说我卑微，我不觉得。能看到你的朋友圈，能给你点赞，能在你生日时第一个发去祝福（虽然你从没回过），我已经很满足了。',
  '你换了新头像，真好看。我盯着看了半小时，然后默默地把我的头像也换成了同一个系列的。这样我们看起来就像情侣头像了，虽然只有我知道。',
  '今天你在群里发了一句"哈哈哈"，我反复读了十几遍，试图分析你今天心情好的原因。如果是因为别人，那我祝福你；如果没有原因，那能不能分我一点？',
  '我给你备注是"宝"，你给我备注可能是全名，也可能没有备注。没关系，备注只是形式，我对你的心不是。',
  '深夜十二点，你的朋友圈更新了，配文"睡不着"。我立刻回复"我也是"。其实我已经躺下了，但为了陪你，我可以一直睡不着。你没回我。',
  '今天路过你常去的那家奶茶店，帮你点了一杯少糖去冰的乌龙玛奇朵。走到你公司楼下才想起来，你根本没让我买，我们也已经两个月没说过话了。奶茶很好喝，就是有点咸。'
];

@Component
export struct DogDiaryPage {
  @State index: number = 0;

  build() {
    NavDestination() {
      Column({ space: 24 }) {
        Scroll() {
          Column({ space: 14 }) {
            Text('🐕 舔狗日记')
              .fontSize(14)
              .fontColor('#CCFFFFFF')
            Text(DIARIES[this.index])
              .fontSize(17)
              .fontColor(Color.White)
              .lineHeight(30)
              .copyOption(CopyOptions.LocalDevice)
          }
          .alignItems(HorizontalAlign.Start)
          .padding(24)
        }
        .width('100%')
        .layoutWeight(1)
        .borderRadius(24)
        .linearGradient({ angle: 135, colors: [['#606C88', 0], ['#3F4C6B', 1]] })
        .shadow({ radius: 16, color: '#3F4C6B55', offsetY: 6 })
        .margin({ top: 20 })

        Button('💔 再看一篇')
          .width(200).height(54)
          .fontSize(17).fontWeight(FontWeight.Bold)
          .backgroundColor('#606C88')
          .onClick(() => {
            this.index = (this.index + 1 + Math.floor(Math.random() * (DIARIES.length - 1))) % DIARIES.length;
          })

        Text('长按文字可复制 · 舔到最后应有尽有（并没有）')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 10 })
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('舔狗日记')
    .backgroundColor($r('app.color.bg_page'))
  }
}
