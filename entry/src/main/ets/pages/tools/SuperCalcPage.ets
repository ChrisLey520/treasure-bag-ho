import { SciParser, fmtResult, normalizeFx, equationToFx, toFraction } from '../../utils/SciParser';

interface HistoryItem {
  expr: string;
  result: string;
}

interface ResultRow {
  label: string;
  value: string;
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

/** 方程专用键盘：所有符号按钮化，无需手动输入 */
const EQ_KEYS: string[][] = [
  ['x', '=', '(', ')', '⌫'],
  ['sin', 'cos', 'tan', '√', '÷'],
  ['7', '8', '9', '^', '×'],
  ['4', '5', '6', 'π', '−'],
  ['1', '2', '3', 'ln', '+'],
  ['0', '.', 'log', 'C', '求解']
];

const MODES: string[] = ['计算', '绘图', '方程', '统计'];

@Component
export struct SuperCalcPage {
  @State mode: number = 0;
  // ── 科学计算 ──
  @State expression: string = '';
  @State result: string = '';
  @State fracForm: string = '';   // 结果的分数形式（若存在）
  @State degMode: boolean = true;
  @State second: boolean = false;
  @State history: HistoryItem[] = [];
  private ans: number = 0;
  // ── 绘图 ──
  @State plotExpr: string = 'sin x';
  @State plotError: string = '';
  @State plotW: number = 320;
  // ── 方程 ──
  @State eqInput: string = 'x^2−x−1=0';
  @State eqResult: string = '';
  // ── 统计 ──
  @State statInput: string = '';
  @State statRows: ResultRow[] = [];

  private parser: SciParser = new SciParser();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private plotCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private readonly PLOT_H: number = 240;

  keys(): string[][] {
    return this.second ? SCI_KEYS_2ND : SCI_KEYS;
  }

  // ════════ 科学计算 ════════
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
      this.fracForm = '';
      return;
    }
    if (k === '⌫') {
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
        // 分数形式：仅当能表示为"好看"的分数（分母 ≤ 9999）时展示
        const frac = toFraction(v, 9999);
        this.fracForm = frac !== undefined ? frac : '';
        this.ans = v;
        this.history = [{ expr: this.expression, result: this.result } as HistoryItem,
          ...this.history].slice(0, 20);
      } catch (err) {
        this.result = (err as Error).message;
        this.fracForm = '';
      }
      return;
    }
    this.expression += k;
    this.result = '';
    this.fracForm = '';
  }

  keyBg(k: string): ResourceColor {
    if (k === '=' || k === '求解') {
      return $r('app.color.accent');
    }
    if (k === 'C') {
      return '#33F5576C';
    }
    if (k === '2nd') {
      return this.second ? $r('app.color.accent') : '#2E3140';
    }
    if ((k >= '0' && k <= '9') || k === '.') {
      return $r('app.color.bg_card');
    }
    return '#2E3140';
  }

  keyFg(k: string): ResourceColor {
    if (k === '=' || k === '求解' || (k === '2nd' && this.second)) {
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

  // ════════ 函数绘图 ════════
  drawPlot(): void {
    const c = this.plotCtx;
    const W = this.plotW;
    const H = this.PLOT_H;
    c.clearRect(0, 0, W, H);
    this.plotError = '';

    const X_MIN = -10;
    const X_MAX = 10;
    const expr = normalizeFx(this.plotExpr);

    const N = 300;
    const xs: number[] = [];
    const ys: number[] = [];
    let yMin = Infinity;
    let yMax = -Infinity;
    let valid = 0;
    if (expr.length > 0) {
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
          valid += 1;
          yMin = Math.min(yMin, y);
          yMax = Math.max(yMax, y);
        }
      }
    }
    if (valid === 0) {
      yMin = -5;
      yMax = 5;
      if (expr.length > 0) {
        this.plotError = '表达式无法求值（变量用 x，如 x^2−2x+1）';
      }
    } else {
      if (yMax - yMin < 1e-9) {
        yMin -= 1;
        yMax += 1;
      }
      const pad = (yMax - yMin) * 0.1;
      yMin -= pad;
      yMax += pad;
      if (yMax > 50) { yMax = 50; }
      if (yMin < -50) { yMin = -50; }
    }

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
    // x 轴
    c.strokeStyle = '#8A8F9C';
    c.lineWidth = 1.2;
    if (yMin <= 0 && yMax >= 0) {
      c.beginPath();
      c.moveTo(0, py(0));
      c.lineTo(W, py(0));
      c.stroke();
    } else {
      const edgeY = yMin > 0 ? H - 1 : 1;
      c.setLineDash([4, 4]);
      c.beginPath();
      c.moveTo(0, edgeY);
      c.lineTo(W, edgeY);
      c.stroke();
      c.setLineDash([]);
    }
    // y 轴
    c.beginPath();
    c.moveTo(px(0), 0);
    c.lineTo(px(0), H);
    c.stroke();
    // 曲线
    if (valid > 0) {
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
    }
    c.fillStyle = '#8A8F9C';
    c.font = '10vp sans-serif';
    c.fillText(`y∈[${fmtResult(parseFloat(yMin.toFixed(2)))}, ${fmtResult(parseFloat(yMax.toFixed(2)))}]`, 6, 14);
    c.fillText('x∈[-10, 10]', 6, H - 6);
  }

  // ════════ 方程求解 ════════
  onEqKey(k: string): void {
    if (k === 'C') {
      this.eqInput = '';
      this.eqResult = '';
      return;
    }
    if (k === '⌫') {
      const fns: string[] = ['sin', 'cos', 'tan', 'ln', 'log'];
      let cut = 1;
      for (const fn of fns) {
        if (this.eqInput.endsWith(fn)) {
          cut = fn.length;
          break;
        }
      }
      this.eqInput = this.eqInput.slice(0, -cut);
      return;
    }
    if (k === '求解') {
      this.solveEquation();
      return;
    }
    this.eqInput += k;
    this.eqResult = '';
  }

  /**
   * 通用方程求解：
   * 1) 移项为 f(x) = 0
   * 2) 多项式检测（差分法）：一次/二次给精确解（含复根）
   * 3) 其余数值求根：[-10,10] 扫描 + 二分
   */
  solveEquation(): void {
    if (this.eqInput.trim().length === 0) {
      this.eqResult = '请输入方程';
      return;
    }
    const fx = equationToFx(this.eqInput);
    const f = (x: number): number => this.parser.evalWithX(fx, x, this.degMode);

    // 试采样，确认表达式可求值
    let ok = 0;
    const probe: number[] = [0, 1, -1, 2, -2, 3, 0.5];
    const pv: number[] = [];
    for (const x of probe) {
      try {
        const y = f(x);
        pv.push(y);
        if (!isNaN(y) && isFinite(y)) {
          ok += 1;
        }
      } catch (err) {
        pv.push(NaN);
      }
    }
    if (ok === 0) {
      this.eqResult = '方程无法求值，请检查输入（未知数用 x）';
      return;
    }

    // 多项式检测：f(0),f(1),f(-1),f(2),f(3) 全部有效时试拟合二次
    if (!isNaN(pv[0]) && !isNaN(pv[1]) && !isNaN(pv[2]) && !isNaN(pv[3]) && !isNaN(pv[5])) {
      const c = pv[0];                       // f(0)
      const a = (pv[1] + pv[2]) / 2 - c;     // (f(1)+f(-1))/2 − f(0)
      const b = (pv[1] - pv[2]) / 2;         // (f(1)−f(-1))/2
      // 验证拟合（x=2、x=3 两点）
      const fit2 = a * 4 + b * 2 + c;
      const fit3 = a * 9 + b * 3 + c;
      const scale = Math.max(1, Math.abs(pv[3]), Math.abs(pv[5]));
      if (Math.abs(fit2 - pv[3]) < 1e-9 * scale && Math.abs(fit3 - pv[5]) < 1e-9 * scale) {
        this.solvePolynomial(a, b, c);
        return;
      }
    }
    // 非多项式：数值求根
    this.solveNumeric(f);
  }

  /** 一次/二次精确解（含复根、分数形式） */
  solvePolynomial(a: number, b: number, c: number): void {
    const withFrac = (v: number): string => {
      const fr = toFraction(v, 9999);
      return fr !== undefined ? `${fmtResult(v)}（${fr}）` : fmtResult(v);
    };
    if (Math.abs(a) < 1e-12) {
      if (Math.abs(b) < 1e-12) {
        this.eqResult = Math.abs(c) < 1e-12 ? '恒等式：x 为任意数' : '矛盾式：无解';
        return;
      }
      this.eqResult = `一次方程 ${fmtResult(b)}x + ${fmtResult(c)} = 0\n\nx = ${withFrac(-c / b)}`;
      return;
    }
    const d = b * b - 4 * a * c;
    const head = `二次方程 a=${fmtResult(a)}, b=${fmtResult(b)}, c=${fmtResult(c)}\nΔ = ${fmtResult(d)}`;
    if (d > 1e-12) {
      const x1 = (-b + Math.sqrt(d)) / (2 * a);
      const x2 = (-b - Math.sqrt(d)) / (2 * a);
      this.eqResult = `${head} > 0，两个实根\n\nx₁ = ${withFrac(x1)}\nx₂ = ${withFrac(x2)}`;
    } else if (Math.abs(d) <= 1e-12) {
      this.eqResult = `${head} = 0，重根\n\nx = ${withFrac(-b / (2 * a))}`;
    } else {
      const re = fmtResult(-b / (2 * a));
      const im = fmtResult(Math.sqrt(-d) / (2 * Math.abs(a)));
      this.eqResult = `${head} < 0，共轭复根\n\nx₁ = ${re} + ${im}i\nx₂ = ${re} − ${im}i`;
    }
  }

  /** 数值求根：[-10,10] 扫描变号区间 + 二分 */
  solveNumeric(f: (x: number) => number): void {
    const roots: number[] = [];
    const N = 400;
    const X_MIN = -10;
    const X_MAX = 10;
    let prevX = X_MIN;
    let prevY = NaN;
    try {
      prevY = f(prevX);
    } catch (err) {
      prevY = NaN;
    }
    for (let i = 1; i <= N; i++) {
      const x = X_MIN + (X_MAX - X_MIN) * i / N;
      let y = NaN;
      try {
        y = f(x);
      } catch (err) {
        y = NaN;
      }
      if (!isNaN(prevY) && !isNaN(y) && isFinite(prevY) && isFinite(y)) {
        if (Math.abs(prevY) < 1e-12) {
          roots.push(prevX);
        } else if (prevY * y < 0) {
          let lo = prevX;
          let hi = x;
          let flo = prevY;
          for (let iter = 0; iter < 60; iter++) {
            const mid = (lo + hi) / 2;
            let fm = NaN;
            try {
              fm = f(mid);
            } catch (err) {
              break;
            }
            if (fm === 0 || (hi - lo) < 1e-12) {
              lo = mid;
              break;
            }
            if (flo * fm < 0) {
              hi = mid;
            } else {
              lo = mid;
              flo = fm;
            }
          }
          roots.push((lo + hi) / 2);
        }
      }
      prevX = x;
      prevY = y;
    }
    const uniq: number[] = [];
    for (const r of roots) {
      if (uniq.length === 0 || Math.abs(r - uniq[uniq.length - 1]) > 1e-6) {
        uniq.push(r);
      }
    }
    if (uniq.length === 0) {
      this.eqResult = '数值求解：在 [-10, 10] 内未找到实根\n（不排除区间外的根或偶重根）';
    } else {
      const parts: string[] = [];
      for (let i = 0; i < uniq.length; i++) {
        const clean = Math.abs(uniq[i]) < 1e-10 ? 0 : uniq[i];
        const v = parseFloat(clean.toPrecision(8));
        const fr = toFraction(v, 9999);
        parts.push(`x${i + 1} = ${fmtResult(v)}${fr !== undefined ? `（${fr}）` : ''}`);
      }
      this.eqResult = `数值求解，找到 ${uniq.length} 个根：\n\n${parts.join('\n')}`;
    }
  }

  // ════════ 统计分析 ════════
  calcStats(): void {
    const parts = this.statInput.split(/[,，\s]+/);
    const nums: number[] = [];
    for (const p of parts) {
      if (p.trim().length === 0) {
        continue;
      }
      const v = parseFloat(p.trim());
      if (isNaN(v)) {
        this.statRows = [{ label: '错误', value: `"${p}" 不是数字` } as ResultRow];
        return;
      }
      nums.push(v);
    }
    if (nums.length === 0) {
      this.statRows = [];
      return;
    }
    nums.sort((a, b) => a - b);
    const n = nums.length;
    let sum = 0;
    for (const v of nums) {
      sum += v;
    }
    const mean = sum / n;
    let sq = 0;
    for (const v of nums) {
      sq += (v - mean) * (v - mean);
    }
    const varP = sq / n;
    const varS = n > 1 ? sq / (n - 1) : 0;
    const median = n % 2 === 1 ? nums[(n - 1) / 2] : (nums[n / 2 - 1] + nums[n / 2]) / 2;
    this.statRows = [
      { label: '个数 n', value: n.toString() } as ResultRow,
      { label: '总和 Σx', value: fmtResult(sum) } as ResultRow,
      { label: '平均值 x̄', value: fmtResult(mean) } as ResultRow,
      { label: '中位数', value: fmtResult(median) } as ResultRow,
      { label: '最小 / 最大', value: `${fmtResult(nums[0])} / ${fmtResult(nums[n - 1])}` } as ResultRow,
      { label: '极差', value: fmtResult(nums[n - 1] - nums[0]) } as ResultRow,
      { label: '总体方差 σ²', value: fmtResult(varP) } as ResultRow,
      { label: '总体标准差 σ', value: fmtResult(Math.sqrt(varP)) } as ResultRow,
      { label: '样本方差 s²', value: fmtResult(varS) } as ResultRow,
      { label: '样本标准差 s', value: fmtResult(Math.sqrt(varS)) } as ResultRow
    ];
  }

  @Builder
  keyboard(layout: string[][], onPress: (k: string) => void) {
    Column({ space: 6 }) {
      ForEach(layout, (row: string[]) => {
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
              .onClick(() => onPress(k))
          }, (k: string) => k)
        }
        .width('100%')
        .layoutWeight(1)
      }, (row: string[], i: number) => `r${i}${this.second}`)
    }
    .layoutWeight(1)
    .width('100%')
  }

  build() {
    NavDestination() {
      Column({ space: 10 }) {
        // 模式切换
        Row({ space: 8 }) {
          ForEach(MODES, (label: string, i: number) => {
            Text(label)
              .fontSize(14)
              .fontWeight(this.mode === i ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.mode === i ? Color.White : $r('app.color.text_secondary'))
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .borderRadius(18)
              .backgroundColor(this.mode === i ? $r('app.color.accent') : $r('app.color.bg_card'))
              .onClick(() => {
                this.mode = i;
                if (i === 1) {
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
                      this.fracForm = '';
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
              Text(`= ${this.result}${this.fracForm.length > 0 ? `  =  ${this.fracForm}` : ''}`)
                .fontSize(this.fracForm.length > 0 ? 24 : 30)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.accent'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .textAlign(TextAlign.End)
                .width('100%')
            }
          }
          .width('100%')
          .height(160)
          .padding(14)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
          .alignItems(HorizontalAlign.End)

          this.keyboard(this.keys(), (k) => this.onKey(k))
        } else if (this.mode === 1) {
          // ── 函数绘图 ──
          Scroll() {
            Column({ space: 12 }) {
              Row({ space: 8 }) {
                Text('f(x) =')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))
                TextInput({ placeholder: '如 sin x、x^2−2x+1（可写 y=…）', text: this.plotExpr })
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
                .width('100%')
                .height(this.PLOT_H)
                .borderRadius(16)
                .backgroundColor($r('app.color.bg_card'))
                .onAreaChange((_o: Area, n: Area) => {
                  const w = n.width as number;
                  if (w > 0 && Math.abs(w - this.plotW) > 1) {
                    this.plotW = w;
                    this.drawPlot();
                  }
                })
                .onReady(() => this.drawPlot())

              Scroll() {
                Row({ space: 8 }) {
                  ForEach(['sin x', 'x^2', 'x^3−3x', '1÷x', 'tan x', 'ln x', '√x', 'x+1'], (ex: string) => {
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

              Text(`三角函数按 ${this.degMode ? 'DEG 角度' : 'RAD 弧度'} 制绘制（计算页可切换）`)
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
            }
            .width('100%')
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else if (this.mode === 2) {
          // ── 方程求解：显示区 + 结果 + 专用键盘 ──
          Column({ space: 4 }) {
            Text(this.eqInput.length > 0 ? this.eqInput : '输入方程，如 x^2−x−1=0')
              .fontSize(this.eqInput.length > 18 ? 18 : 24)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.eqInput.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
              .maxLines(2)
              .textAlign(TextAlign.End)
              .width('100%')
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
          .alignItems(HorizontalAlign.End)

          if (this.eqResult.length > 0) {
            Scroll() {
              Text(this.eqResult)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .lineHeight(24)
                .width('100%')
            }
            .width('100%')
            .constraintSize({ maxHeight: 150 })
            .padding(14)
            .borderRadius(16)
            .backgroundColor($r('app.color.bg_card'))
            .scrollBar(BarState.Off)
          } else {
            Text('支持任意一元方程：二次以内给精确解（含复根与分数），\n其余自动数值求根；含 = 自动移项，不写 = 视为 f(x)=0')
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
          }

          this.keyboard(EQ_KEYS, (k) => this.onEqKey(k))
        } else {
          // ── 统计分析 ──
          Scroll() {
            Column({ space: 14 }) {
              Text('输入一组数据（逗号/空格分隔）')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .alignSelf(ItemAlign.Start)
              TextArea({ placeholder: '如：85, 92, 78, 90, 88', text: this.statInput })
                .height(90)
                .borderRadius(12)
                .backgroundColor($r('app.color.bg_card'))
                .fontColor($r('app.color.text_primary'))
                .onChange((v: string) => { this.statInput = v; })
              Button('统计分析')
                .width('100%').height(46)
                .fontSize(15).fontWeight(FontWeight.Bold)
                .backgroundColor($r('app.color.accent'))
                .onClick(() => this.calcStats())
              if (this.statRows.length > 0) {
                Column() {
                  ForEach(this.statRows, (row: ResultRow, i: number) => {
                    Row() {
                      Text(row.label)
                        .fontSize(14)
                        .fontColor($r('app.color.text_secondary'))
                      Blank()
                      Text(row.value)
                        .fontSize(15)
                        .fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.text_primary'))
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10, left: 16, right: 16 })
                    if (i < this.statRows.length - 1) {
                      Divider().margin({ left: 16, right: 16 })
                    }
                  }, (row: ResultRow) => row.label)
                }
                .borderRadius(14)
                .backgroundColor($r('app.color.bg_card'))
              }
            }
            .width('100%')
            .padding({ bottom: 20 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
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
