let storageAnswer = new LocalStorage();

const ANSWERS: string[] = [
  '是的', '不', '也许吧', '毫无疑问', '再想想', '放手去做', '时机未到', '相信直觉',
  '问问你的心', '别犹豫了', '这不值得', '答案就在眼前', '需要等待', '换个角度看',
  '当然可以', '很难说', '命运掌握在你手中', '顺其自然', '再坚持一下', '立刻行动',
  '不要回头', '值得一试', '风险很大', '你已经知道答案了', '找人聊聊', '睡一觉再说',
  '会有转机', '别想太多', '这是个好主意', '保持耐心'
];

/**
 * 答案之书服务卡片（2×2）：心中默念问题，点水晶球出答案。
 * 与 App 内 AnswerPage 同一答案库。
 */
@Entry(storageAnswer)
@Component
struct AnswerCard {
  @State answer: string = '';
  @State asked: number = 0;   // 触发缩放动效

  ask(): void {
    let next = ANSWERS[Math.floor(Math.random() * ANSWERS.length)];
    // 避免连续两次同一条
    if (next === this.answer && ANSWERS.length > 1) {
      next = ANSWERS[(ANSWERS.indexOf(next) + 1) % ANSWERS.length];
    }
    this.answer = next;
    this.asked += 1;
  }

  build() {
    Column({ space: 8 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('🔮')
          .fontSize(12)
        Text('答案之书')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
        Blank()
      }
      .width('100%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetTool: 'answer' }
        });
      })

      Blank()

      Text('🔮')
        .fontSize(44)
        .scale({ x: this.asked % 2 === 0 ? 1 : 1.12, y: this.asked % 2 === 0 ? 1 : 1.12 })
        .animation({ duration: 260, curve: Curve.EaseOut })
        .onClick(() => this.ask())

      Text(this.answer.length > 0 ? `「 ${this.answer} 」` : '默念问题，点水晶球')
        .fontSize(this.answer.length > 0 ? 15 : 11)
        .fontWeight(this.answer.length > 0 ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.answer.length > 0 ? Color.White : '#CCFFFFFF')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .width('100%')
        .animation({ duration: 300, curve: Curve.EaseOut })

      Blank()
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#5B247A', 0], ['#1BCEDF', 1]] })
    .onClick(() => this.ask())
  }
}
