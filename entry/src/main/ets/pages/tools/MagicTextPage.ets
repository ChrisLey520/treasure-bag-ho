import { pasteboard } from '@kit.BasicServicesKit';

/**
 * 魔法文案：在每个字符之间插入零宽字符（U+200B / U+200C / U+200D），
 * 肉眼不可见，但能改变字符串指纹。
 */
const INVISIBLES: string[] = ['​', '‌', '‍'];

@Component
export struct MagicTextPage {
  @State input: string = '';
  @State output: string = '';
  @State density: number = 1; // 每个字符后插入的零宽字符数

  applyMagic(): void {
    if (this.input.length === 0) {
      this.output = '';
      return;
    }
    let result = '';
    for (const ch of this.input) {
      result += ch;
      for (let i = 0; i < this.density; i++) {
        result += INVISIBLES[Math.floor(Math.random() * INVISIBLES.length)];
      }
    }
    this.output = result;
  }

  restore(): void {
    let result = this.input;
    for (const inv of INVISIBLES) {
      result = result.split(inv).join('');
    }
    this.output = result;
  }

  copyOutput(): void {
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.output);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: '已复制到剪贴板', duration: 1200 });
    }).catch((err: Error) => {
      console.error('copy failed:', err.message);
    });
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        TextArea({ placeholder: '输入原文…', text: this.input })
          .layoutWeight(2)
          .borderRadius(14)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.input = v; })

        Column({ space: 6 }) {
          Row() {
            Text('魔法强度').fontSize(14).fontColor($r('app.color.text_secondary'))
            Blank()
            Text(`${this.density}`).fontSize(14).fontColor($r('app.color.text_primary'))
          }.width('100%')
          Slider({ value: this.density, min: 1, max: 3, step: 1 })
            .onChange((v: number) => { this.density = v; })
        }
        .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))

        Row({ space: 10 }) {
          Button('✨ 施展魔法')
            .layoutWeight(1).height(48)
            .linearGradient({ angle: 135, colors: [['#8E2DE2', 0], ['#4A00E0', 1]] })
            .onClick(() => this.applyMagic())
          Button('还原')
            .layoutWeight(1).height(48)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onClick(() => this.restore())
        }
        .width('100%')

        Column({ space: 8 }) {
          Row() {
            Text(`结果（${this.output.length} 字符）`)
              .fontSize(13).fontColor($r('app.color.text_secondary'))
            Blank()
            if (this.output.length > 0) {
              Text('复制')
                .fontSize(13).fontColor($r('app.color.accent'))
                .onClick(() => this.copyOutput())
            }
          }
          .width('100%')
          Scroll() {
            Text(this.output.length > 0 ? this.output : '处理结果显示在这里，外观与原文一致但内含隐形字符')
              .fontSize(15)
              .fontColor(this.output.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
              .width('100%')
          }
          .layoutWeight(1)
          .align(Alignment.TopStart)
        }
        .layoutWeight(2)
        .width('100%')
        .padding(14)
        .borderRadius(14)
        .backgroundColor($r('app.color.bg_card'))
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('魔法文案')
    .backgroundColor($r('app.color.bg_page'))
  }
}
