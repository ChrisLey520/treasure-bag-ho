const KFC_TEXTS: string[] = [
  '我一直以为自己是个坚强的人，直到今天路过肯德基，闻到那熟悉的香味，才发现我的坚强不堪一击。今天是疯狂星期四，谁请我吃？',
  '医生说我缺钾，需要补充。我上网查了一下，肯德基的"疯狂星期四"就很补钾（家）。V 我 50，我请你看结果。',
  '刚才有个朋友问我：兄弟，今天星期几？我说星期四。他说哦。就没有然后了。其实我在等他说"疯狂星期四 V 你 50"。',
  '天青色等烟雨，而我在等你。月色被打捞起，晕开了结局。如传世的青花瓷自顾自美丽，你眼带笑意。今天疯狂星期四，V 我 50，我把周杰伦全套演唱会门票的故事讲给你听。',
  '亲爱的，我们分手吧。我遇到了让我心动的人——肯德基疯狂星期四。除非你 V 我 50，否则我们就此别过。',
  '公司倒闭了，老板跑路了，我三个月工资没发。房东在催房租，我已经两天没吃饭了。兄弟，今天疯狂星期四，V 我 50，让我吃顿好的。',
  '考古学家在埃及金字塔深处发现了一行神秘的象形文字，经过 20 年破译，内容终于公布：今天疯狂星期四，V 我 50。',
  '你知道吗，光从太阳到达地球需要 8 分 20 秒，而我从看到疯狂星期四广告到饿只需要 1 秒。V 我 50，拯救一个饥饿的灵魂。'
];

@Component
export struct KfcPage {
  @State index: number = 0;

  build() {
    NavDestination() {
      Column({ space: 24 }) {
        Scroll() {
          Text(KFC_TEXTS[this.index])
            .fontSize(17)
            .fontColor(Color.White)
            .lineHeight(30)
            .padding(24)
            .copyOption(CopyOptions.LocalDevice)
        }
        .width('100%')
        .layoutWeight(1)
        .borderRadius(24)
        .linearGradient({ angle: 135, colors: [['#F83600', 0], ['#F9D423', 1]] })
        .shadow({ radius: 16, color: '#F8360055', offsetY: 6 })
        .margin({ top: 20 })

        Button('🍗 换一篇')
          .width(200).height(54)
          .fontSize(17).fontWeight(FontWeight.Bold)
          .backgroundColor('#D32F2F')
          .onClick(() => {
            this.index = (this.index + 1 + Math.floor(Math.random() * (KFC_TEXTS.length - 1))) % KFC_TEXTS.length;
          })

        Text('长按文字可复制 · 周四发到群里效果更佳')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: 10 })
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('疯狂星期四')
    .backgroundColor($r('app.color.bg_page'))
  }
}
