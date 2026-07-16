let storageCalc = new LocalStorage();

const KEYS: string[][] = [
  ['C', '⌫', '%', '÷'],
  ['7', '8', '9', '×'],
  ['4', '5', '6', '−'],
  ['1', '2', '3', '+'],
  ['00', '0', '.', '=']
];

@Entry(storageCalc)
@Component
struct CalcCard {
  @State display: string = '0';
  @State expression: string = '';

  isOp(k: string): boolean {
    return k === '÷' || k === '×' || k === '−' || k === '+' || k === '%';
  }

  /** 不用 eval：手动解析表达式（先乘除后加减），与 App 内计算器同款 */
  evaluate(expr: string): string {
    const tokens: string[] = [];
    let num = '';
    for (const ch of expr) {
      if ((ch >= '0' && ch <= '9') || ch === '.') {
        num += ch;
      } else {
        if (num.length > 0) {
          tokens.push(num);
          num = '';
        }
        tokens.push(ch);
      }
    }
    if (num.length > 0) {
      tokens.push(num);
    }
    if (tokens.length === 0) {
      return '0';
    }
    while (tokens.length > 0 && this.isOp(tokens[tokens.length - 1])) {
      tokens.pop();
    }
    const pass0: string[] = [];
    for (const t of tokens) {
      if (t === '%') {
        const prev = pass0.pop();
        if (prev === undefined) {
          return '错误';
        }
        pass0.push((parseFloat(prev) / 100).toString());
      } else {
        pass0.push(t);
      }
    }
    const pass1: string[] = [];
    let i = 0;
    while (i < pass0.length) {
      const t = pass0[i];
      if (t === '×' || t === '÷') {
        const a = parseFloat(pass1.pop() ?? '0');
        const b = parseFloat(pass0[i + 1]);
        if (t === '÷' && b === 0) {
          return '不能除以 0';
        }
        pass1.push((t === '×' ? a * b : a / b).toString());
        i += 2;
      } else {
        pass1.push(t);
        i += 1;
      }
    }
    let result = parseFloat(pass1[0]);
    i = 1;
    while (i < pass1.length - 1) {
      const op = pass1[i];
      const b = parseFloat(pass1[i + 1]);
      result = op === '+' ? result + b : result - b;
      i += 2;
    }
    if (isNaN(result) || !isFinite(result)) {
      return '错误';
    }
    return parseFloat(result.toPrecision(12)).toString();
  }

  onKey(k: string): void {
    if (k === 'C') {
      this.display = '0';
      this.expression = '';
      return;
    }
    if (k === '⌫') {
      this.expression = this.expression.slice(0, -1);
      this.display = this.expression.length > 0 ? this.expression : '0';
      return;
    }
    if (k === '=') {
      this.display = this.evaluate(this.expression);
      this.expression = this.display === '错误' || this.display === '不能除以 0' ? '' : this.display;
      return;
    }
    if (this.isOp(k)) {
      if (this.expression.length === 0 && k !== '−') {
        return;
      }
      if (this.expression.length > 0 && this.isOp(this.expression[this.expression.length - 1])) {
        this.expression = this.expression.slice(0, -1);
      }
      this.expression += k;
    } else {
      this.expression += k;
    }
    this.display = this.expression;
  }

  keyColor(k: string): ResourceColor {
    if (k === '=') {
      return $r('app.color.accent');
    }
    if (k === 'C' || k === '⌫' || this.isOp(k)) {
      return '#2E3140';
    }
    return $r('app.color.bg_card');
  }

  keyTextColor(k: string): ResourceColor {
    if (k === '=') {
      return Color.White;
    }
    if (k === 'C') {
      return '#F5576C';
    }
    if (k === '⌫' || this.isOp(k)) {
      return '#7B88FF';
    }
    return $r('app.color.text_primary');
  }

  build() {
    Column({ space: 6 }) {
      // 显示区（点击可进 App 打开完整计算器）
      Text(this.display)
        .fontSize(this.display.length > 12 ? 16 : 22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.End)
        .width('100%')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(12)
        .backgroundColor($r('app.color.bg_card'))
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { targetTool: 'calculator' }
          });
        })

      // 键盘（布局与 App 内计算器一致）
      Column({ space: 4 }) {
        ForEach(KEYS, (row: string[]) => {
          Row({ space: 4 }) {
            ForEach(row, (k: string) => {
              Text(k)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.keyTextColor(k))
                .textAlign(TextAlign.Center)
                .layoutWeight(1)
                .height('100%')
                .borderRadius(10)
                .backgroundColor(this.keyColor(k))
                .onClick(() => this.onKey(k))
            }, (k: string) => k)
          }
          .width('100%')
          .layoutWeight(1)
        }, (row: string[]) => row.join(''))
      }
      .layoutWeight(1)
      .width('100%')
    }
    .padding(10)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
