@Component
export struct CalculatorPage {
  @State display: string = '0';
  @State expression: string = '';

  private keys: string[][] = [
    ['C', '⌫', '%', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['00', '0', '.', '=']
  ];

  isOp(k: string): boolean {
    return k === '÷' || k === '×' || k === '−' || k === '+' || k === '%';
  }

  /** 不用 eval：手动解析表达式（先乘除后加减） */
  evaluate(expr: string): string {
    // 词法拆分
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
    // 末尾悬挂运算符则丢弃
    while (tokens.length > 0 && this.isOp(tokens[tokens.length - 1])) {
      tokens.pop();
    }
    // 先处理 % （单目，作用于前一个数）
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
    // 乘除
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
    // 加减
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
      // 连续运算符替换
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
    NavDestination() {
      Column({ space: 14 }) {
        // 显示区
        Column({ space: 6 }) {
          Blank()
          Text(this.display)
            .fontSize(this.display.length > 12 ? 32 : 48)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(2)
            .textAlign(TextAlign.End)
            .width('100%')
        }
        .layoutWeight(1)
        .width('100%')
        .padding(20)
        .borderRadius(20)
        .backgroundColor($r('app.color.bg_card'))
        .alignItems(HorizontalAlign.End)

        // 键盘
        Column({ space: 10 }) {
          ForEach(this.keys, (row: string[]) => {
            Row({ space: 10 }) {
              ForEach(row, (k: string) => {
                Text(k)
                  .fontSize(24)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.keyTextColor(k))
                  .textAlign(TextAlign.Center)
                  .layoutWeight(1)
                  .height(64)
                  .borderRadius(18)
                  .backgroundColor(this.keyColor(k))
                  .onClick(() => this.onKey(k))
              }, (k: string) => k)
            }
            .width('100%')
          }, (row: string[]) => row.join(''))
        }
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('计算器')
    .backgroundColor($r('app.color.bg_page'))
  }
}
