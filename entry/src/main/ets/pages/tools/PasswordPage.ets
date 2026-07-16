import { pasteboard } from '@kit.BasicServicesKit';

const LOWER = 'abcdefghijkmnopqrstuvwxyz';   // 去掉易混 l
const UPPER = 'ABCDEFGHJKLMNPQRSTUVWXYZ';    // 去掉易混 I/O
const DIGITS = '23456789';                   // 去掉易混 0/1
const SYMBOLS = '!@#$%^&*_-+=?';

@Component
export struct PasswordPage {
  @State length: number = 16;
  @State useLower: boolean = true;
  @State useUpper: boolean = true;
  @State useDigits: boolean = true;
  @State useSymbols: boolean = false;
  @State password: string = '';

  charset(): string {
    let set = '';
    if (this.useLower) { set += LOWER; }
    if (this.useUpper) { set += UPPER; }
    if (this.useDigits) { set += DIGITS; }
    if (this.useSymbols) { set += SYMBOLS; }
    return set;
  }

  generate(): void {
    const set = this.charset();
    if (set.length === 0) {
      this.getUIContext().getPromptAction().showToast({ message: '至少选择一种字符', duration: 1200 });
      return;
    }
    // 保证每类选中的字符至少出现一次
    const groups: string[] = [];
    if (this.useLower) { groups.push(LOWER); }
    if (this.useUpper) { groups.push(UPPER); }
    if (this.useDigits) { groups.push(DIGITS); }
    if (this.useSymbols) { groups.push(SYMBOLS); }
    const chars: string[] = [];
    for (const g of groups) {
      chars.push(g[Math.floor(Math.random() * g.length)]);
    }
    while (chars.length < this.length) {
      chars.push(set[Math.floor(Math.random() * set.length)]);
    }
    // Fisher-Yates 洗牌
    for (let i = chars.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }
    this.password = chars.slice(0, this.length).join('');
  }

  strength(): string {
    let variety = 0;
    if (this.useLower) { variety += 1; }
    if (this.useUpper) { variety += 1; }
    if (this.useDigits) { variety += 1; }
    if (this.useSymbols) { variety += 1; }
    const score = this.length * variety;
    if (score >= 48) { return '💪 极强'; }
    if (score >= 32) { return '🔒 强'; }
    if (score >= 20) { return '🙂 中等'; }
    return '⚠️ 弱';
  }

  copy(): void {
    if (this.password.length === 0) {
      return;
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.password);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: '已复制密码', duration: 1200 });
    }).catch((err: Error) => {
      console.error('copy failed:', err.message);
    });
  }

  @Builder
  toggleRow(label: string, sample: string, value: boolean, onToggle: (v: boolean) => void) {
    Row() {
      Column({ space: 2 }) {
        Text(label).fontSize(15).fontColor($r('app.color.text_primary'))
        Text(sample).fontSize(11).fontColor($r('app.color.text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor($r('app.color.accent'))
        .onChange((v: boolean) => onToggle(v))
    }
    .width('100%')
    .padding({ top: 10, bottom: 10, left: 16, right: 16 })
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        // 结果卡片
        Column({ space: 10 }) {
          Text(this.password.length > 0 ? this.password : '点击下方按钮生成')
            .fontSize(this.password.length > 24 ? 18 : 22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .copyOption(CopyOptions.LocalDevice)
          if (this.password.length > 0) {
            Text(`强度：${this.strength()}`)
              .fontSize(13)
              .fontColor('#CCFFFFFF')
          }
        }
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .constraintSize({ minHeight: 110 })
        .padding(20)
        .borderRadius(20)
        .linearGradient({ angle: 135, colors: [['#0F3443', 0], ['#34E89E', 1]] })
        .onClick(() => this.copy())

        Column({ space: 6 }) {
          Row() {
            Text('长度').fontSize(14).fontColor($r('app.color.text_secondary'))
            Blank()
            Text(`${this.length} 位`).fontSize(14).fontColor($r('app.color.text_primary'))
          }.width('100%')
          Slider({ value: this.length, min: 6, max: 40, step: 1 })
            .onChange((v: number) => { this.length = v; })
        }
        .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))

        Column() {
          this.toggleRow('小写字母', 'abc（去掉易混 l）', this.useLower, (v) => { this.useLower = v; })
          Divider().margin({ left: 16, right: 16 })
          this.toggleRow('大写字母', 'ABC（去掉易混 I O）', this.useUpper, (v) => { this.useUpper = v; })
          Divider().margin({ left: 16, right: 16 })
          this.toggleRow('数字', '2-9（去掉易混 0 1）', this.useDigits, (v) => { this.useDigits = v; })
          Divider().margin({ left: 16, right: 16 })
          this.toggleRow('特殊符号', '!@#$%…', this.useSymbols, (v) => { this.useSymbols = v; })
        }
        .borderRadius(16)
        .backgroundColor($r('app.color.bg_card'))

        Row({ space: 10 }) {
          Button('🎲 生成密码')
            .layoutWeight(2).height(52)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => this.generate())
          if (this.password.length > 0) {
            Button('复制')
              .layoutWeight(1).height(52)
              .backgroundColor($r('app.color.bg_card'))
              .fontColor($r('app.color.text_primary'))
              .onClick(() => this.copy())
          }
        }
        .width('100%')

        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('密码生成')
    .backgroundColor($r('app.color.bg_page'))
  }
}
