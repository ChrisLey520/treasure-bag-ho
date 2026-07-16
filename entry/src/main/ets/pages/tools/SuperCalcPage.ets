import { SciParser, fmtResult } from '../../utils/SciParser';

interface HistoryItem {
  expr: string;
  result: string;
}

const SCI_KEYS: string[][] = [
  ['2nd', 'DEG', '(', ')', '⌫'],
  ['sin', 'cos', 'tan', 'π', '÷'],
  ['ln', 'log', '√', '^', '×'],
  ['7', '8', '9', 'e', '−'],
  ['4', '5', '6', '!', '+'],
  ['1', '2', '3', '%', 'ANS'],
  ['0', '.', 'x', 'C', '=']
];

const SCI_KEYS_2ND: string[][] = [
  ['2nd', 'DEG', '(', ')', '⌫'],
  ['asin', 'acos', 'atan', 'π', '÷'],
  ['ln', 'log', '√', '^', '×'],
  ['7', '8', '9', 'e', '−'],
  ['4', '5', '6', '!', '+'],
  ['1', '2', '3', '%', 'ANS'],
  ['0', '.', 'x', 'C', '=']
];

@Component
export struct SuperCalcPage {
  @State mode: number = 0;           // 0=科学计算 1=函数绘图
  @State expression: string = '';
  @State result: string = '';
  @State degMode: boolean = true;
  @State second: boolean = false;
  @State history: HistoryItem[] = [];
  @State plotExpr: string = 'sin x';
  @State plotError: string = '';
  private ans: number = 0;
  private parser: SciParser = new SciParser();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private plotCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private readonly PLOT_W: number = 330;
  private readonly PLOT_H: number = 240;

  keys(): string[][] {
    return this.second ? SCI_KEYS_2ND : SCI_KEYS;
  }

  onKey(k: string): void {
    if (k === '2nd') {
      this.second = !this.second;
      return;
    }
    if (k === 'DEG') {
      this.degMode = !this.degMode;
      return;
    }
    if (k === 'C') {
      this.expression = '';
      this.result = '';
      return;
    }
    if (k === '⌫') {
      // 函数名整体删除
      const fns: string[] = ['asin', 'acos', 'atan', 'sin', 'cos', 'tan', 'ln', 'log', 'ANS'];
      let cut = 1;
      for (const fn of fns) {
        if (this.expression.endsWith(fn)) {
          cut = fn.length;
          break;
        }
      }
      this.expression = this.expression.slice(0, -cut);
      return;
    }
    if (k === '=') {
      if (this.expression.length === 0) {
        return;
      }
      try {
        const v = this.parser.parse(this.expression, this.degMode, this.ans);
        this.result = fmtResult(v);
        this.ans = v;
        this.history = [{ expr: this.expression, result: this.result } as HistoryItem,
          ...this.history].slice(0, 20);
      } catch (err) {
        this.result = (err as Error).message;
      }
      return;
    }
    // 函数键自动补左括号风格：直接拼接（解析器支持 sin30 与 sin(30)）
    this.expression += k;
    this.result = '';
  }

  keyBg(k: string): ResourceColor {
    if (k === '=') {
      return $r('app.color.accent');
    }
    if (k === 'C') {
      return '#33F5576C';
    }
    if (k === '2nd') {
      return this.second ? $r('app.color.accent') : '#2E3140';
    }
    if (k === 'DEG') {
      return '#2E3140';
    }
    if ((k >= '0' && k <= '9') || k === '.') {
      return $r('app.color.bg_card');
    }
    return '#2E3140';
  }

  keyFg(k: string): ResourceColor {
    if (k === '=' || (k === '2nd' && this.second)) {
      return Color.White;
    }
    if (k === 'C') {
      return '#F5576C';
    }
    if ((k >= '0' && k <= '9') || k === '.') {
      return $r('app.color.text_primary');
    }
    return '#7B88FF';
  }

  keyLabel(k: string): string {
    if (k === 'DEG') {
      return this.degMode ? 'DEG' : 'RAD';
    }
    return k;
  }

  drawPlot(): void {
    const c = this.plotCtx;
    const W = this.PLOT_W;
    const H = this.PLOT_H;
    c.clearRect(0, 0, W, H);
    this.plotError = '';

    const expr = this.plotExpr.trim();
    if (expr.length === 0) {
      return;
    }
    // 采样：x ∈ [-10, 10]
    const X_MIN = -10;
    const X_MAX = 10;
    const N = 300;
    const xs: number[] = [];
    const ys: number[] = [];
    let yMin = Infinity;
    let yMax = -Infinity;
    for (let i = 0; i <= N; i++) {
      const x = X_MIN + (X_MAX - X_MIN) * i / N;
      let y = NaN;
      try {
        y = this.parser.evalWithX(expr, x, this.degMode);
      } catch (err) {
        y = NaN;
      }
      xs.push(x);
      ys.push(y);
      if (!isNaN(y) && isFinite(y)) {
        yMin = Math.min(yMin, y);
        yMax = Math.max(yMax, y);
      }
    }
    if (yMin > yMax) {
      this.plotError = '表达式无法求值，请检查（变量用 x）';
      return;
    }
    // y 量程留白，处理常函数
    if (yMax - yMin < 1e-9) {
      yMin -= 1;
      yMax += 1;
    }
    const pad = (yMax - yMin) * 0.1;
    yMin -= pad;
    yMax += pad;
    // 限制极端量程（如 tan）
    if (yMax > 50) { yMax = 50; }
    if (yMin < -50) { yMin = -50; }

    const px = (x: number): number => (x - X_MIN) / (X_MAX - X_MIN) * W;
    const py = (y: number): number => H - (y - yMin) / (yMax - yMin) * H;

    // 网格
    c.strokeStyle = '#33888888';
    c.lineWidth = 0.5;
    for (let gx = Math.ceil(X_MIN / 2) * 2; gx <= X_MAX; gx += 2) {
      c.beginPath();
      c.moveTo(px(gx), 0);
      c.lineTo(px(gx), H);
      c.stroke();
    }
    const gStep = Math.pow(10, Math.floor(Math.log10(yMax - yMin))) / 2;
    for (let gy = Math.ceil(yMin / gStep) * gStep; gy <= yMax; gy += gStep) {
      c.beginPath();
      c.moveTo(0, py(gy));
      c.lineTo(W, py(gy));
      c.stroke();
    }
    // 坐标轴
    c.strokeStyle = '#8A8F9C';
    c.lineWidth = 1.2;
    if (yMin <= 0 && yMax >= 0) {
      c.beginPath();
      c.moveTo(0, py(0));
      c.lineTo(W, py(0));
      c.stroke();
    }
    c.beginPath();
    c.moveTo(px(0), 0);
    c.lineTo(px(0), H);
    c.stroke();
    // 曲线
    c.strokeStyle = '#7B88FF';
    c.lineWidth = 2;
    c.beginPath();
    let penDown = false;
    for (let i = 0; i <= N; i++) {
      const y = ys[i];
      if (isNaN(y) || !isFinite(y) || y < yMin || y > yMax) {
        penDown = false;
        continue;
      }
      if (!penDown) {
        c.moveTo(px(xs[i]), py(y));
        penDown = true;
      } else {
        c.lineTo(px(xs[i]), py(y));
      }
    }
    c.stroke();
    // 量程标注
    c.fillStyle = '#8A8F9C';
    c.font = '10vp sans-serif';
    c.fillText(`y∈[${fmtResult(parseFloat(yMin.toFixed(2)))}, ${fmtResult(parseFloat(yMax.toFixed(2)))}]`, 6, 14);
    c.fillText('x∈[-10, 10]', 6, H - 6);
  }

  build() {
    NavDestination() {
      Column({ space: 10 }) {
        // 模式切换
        Row({ space: 10 }) {
          ForEach(['🧪 科学计算', '📈 函数绘图'], (label: string, i: number) => {
            Text(label)
              .fontSize(14)
              .fontWeight(this.mode === i ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.mode === i ? Color.White : $r('app.color.text_secondary'))
              .padding({ left: 18, right: 18, top: 8, bottom: 8 })
              .borderRadius(18)
              .backgroundColor(this.mode === i ? $r('app.color.accent') : $r('app.color.bg_card'))
              .onClick(() => {
                this.mode = i;
                if (i === 1) {
                  // 延迟绘制等待 Canvas ready
                  setTimeout(() => this.drawPlot(), 50);
                }
              })
          }, (label: string) => label)
        }

        if (this.mode === 0) {
          // ── 科学计算 ──
          Column({ space: 4 }) {
            Scroll() {
              Column({ space: 2 }) {
                ForEach(this.history, (h: HistoryItem) => {
                  Text(`${h.expr} = ${h.result}`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .textAlign(TextAlign.End)
                    .onClick(() => {
                      this.expression = h.result;
                      this.result = '';
                    })
                }, (h: HistoryItem, i: number) => `${i}-${h.expr}`)
              }
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .align(Alignment.BottomEnd)

            Text(this.expression.length > 0 ? this.expression : '0')
              .fontSize(this.expression.length > 18 ? 20 : 26)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .maxLines(2)
              .textAlign(TextAlign.End)
              .width('100%')
            if (this.result.length > 0) {
              Text(`= ${this.result}`)
                .fontSize(30)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.accent'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.End)
                .width('100%')
            }
          }
          .width('100%')
          .height(170)
          .padding(14)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
          .alignItems(HorizontalAlign.End)

          // 键盘
          Column({ space: 6 }) {
            ForEach(this.keys(), (row: string[]) => {
              Row({ space: 6 }) {
                ForEach(row, (k: string) => {
                  Text(this.keyLabel(k))
                    .fontSize(k.length > 2 ? 14 : 18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.keyFg(k))
                    .textAlign(TextAlign.Center)
                    .layoutWeight(1)
                    .height('100%')
                    .borderRadius(12)
                    .backgroundColor(this.keyBg(k))
                    .onClick(() => this.onKey(k))
                }, (k: string) => k)
              }
              .width('100%')
              .layoutWeight(1)
            }, (row: string[], i: number) => `r${i}${this.second}`)
          }
          .layoutWeight(1)
          .width('100%')
        } else {
          // ── 函数绘图 ──
          Column({ space: 12 }) {
            Row({ space: 8 }) {
              Text('f(x) =')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              TextInput({ placeholder: '如 sin x、x^2−2x+1、√x', text: this.plotExpr })
                .layoutWeight(1)
                .height(44)
                .borderRadius(12)
                .backgroundColor($r('app.color.bg_card'))
                .fontColor($r('app.color.text_primary'))
                .onChange((v: string) => { this.plotExpr = v; })
                .onSubmit(() => this.drawPlot())
            }
            .width('100%')

            Button('绘制曲线')
              .width('100%').height(46)
              .fontSize(15).fontWeight(FontWeight.Bold)
              .backgroundColor($r('app.color.accent'))
              .onClick(() => this.drawPlot())

            if (this.plotError.length > 0) {
              Text(this.plotError)
                .fontSize(13)
                .fontColor('#F5576C')
            }

            Canvas(this.plotCtx)
              .width(this.PLOT_W)
              .height(this.PLOT_H)
              .borderRadius(16)
              .backgroundColor($r('app.color.bg_card'))
              .onReady(() => this.drawPlot())

            // 快捷示例
            Scroll() {
              Row({ space: 8 }) {
                ForEach(['sin x', 'x^2', 'x^3−3x', '1÷x', 'tan x', 'ln x', '√x', 'abs x'], (ex: string) => {
                  Text(ex)
                    .fontSize(13)
                    .fontColor($r('app.color.text_secondary'))
                    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                    .borderRadius(14)
                    .backgroundColor($r('app.color.bg_card'))
                    .onClick(() => {
                      this.plotExpr = ex;
                      this.drawPlot();
                    })
                }, (ex: string) => ex)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')

            Text(`三角函数按 ${this.degMode ? 'DEG 角度' : 'RAD 弧度'} 制绘制（科学计算页可切换）`)
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))

            Blank()
          }
          .layoutWeight(1)
          .width('100%')
        }
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 16 })
      .width('100%')
      .height('100%')
    }
    .title('超级计算器')
    .backgroundColor($r('app.color.bg_page'))
  }
}
