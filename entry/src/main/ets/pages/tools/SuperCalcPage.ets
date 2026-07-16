import { SciParser, fmtResult, normalizeFx } from '../../utils/SciParser';

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

const MODES: string[] = ['计算', '绘图', '方程', '分数', '统计'];

/** 最大公约数 */
function gcd(a: number, b: number): number {
  a = Math.abs(a);
  b = Math.abs(b);
  while (b > 0) {
    const t = a % b;
    a = b;
    b = t;
  }
  return a;
}

@Component
export struct SuperCalcPage {
  @State mode: number = 0;
  // ── 科学计算 ──
  @State expression: string = '';
  @State result: string = '';
  @State degMode: boolean = true;
  @State second: boolean = false;
  @State history: HistoryItem[] = [];
  private ans: number = 0;
  // ── 绘图 ──
  @State plotExpr: string = 'sin x';
  @State plotError: string = '';
  @State plotW: number = 320;
  // ── 方程 ──
  @State eqA: string = '1';
  @State eqB: string = '-3';
  @State eqC: string = '2';
  @State eqResult: string = '';
  @State fxExpr: string = 'x^2−2';
  @State fxRoots: string = '';
  // ── 分数 ──
  @State fracN1: string = '1';
  @State fracD1: string = '2';
  @State fracN2: string = '1';
  @State fracD2: string = '3';
  @State fracOp: number = 0;   // 0+ 1− 2× 3÷
  @State fracResult: string = '';
  @State decInput: string = '0.375';
  @State decResult: string = '';
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
        this.ans = v;
        this.history = [{ expr: this.expression, result: this.result } as HistoryItem,
          ...this.history].slice(0, 20);
      } catch (err) {
        this.result = (err as Error).message;
      }
      return;
    }
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

    // 采样（失败也继续，保证网格坐标轴总是画出来）
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
      // 无有效点：默认量程，仍画空白坐标系
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
    // 坐标轴：x 轴——0 在量程内画 y=0，否则贴近的边画基线（虚线示意）
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
    // y 轴（x=0 恒在 [-10,10] 内）
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
    // 量程标注
    c.fillStyle = '#8A8F9C';
    c.font = '10vp sans-serif';
    c.fillText(`y∈[${fmtResult(parseFloat(yMin.toFixed(2)))}, ${fmtResult(parseFloat(yMax.toFixed(2)))}]`, 6, 14);
    c.fillText('x∈[-10, 10]', 6, H - 6);
  }

  // ════════ 方程求解 ════════
  solveQuadratic(): void {
    const a = parseFloat(this.eqA);
    const b = parseFloat(this.eqB);
    const c = parseFloat(this.eqC);
    if (isNaN(a) || isNaN(b) || isNaN(c)) {
      this.eqResult = '请输入有效系数';
      return;
    }
    if (a === 0) {
      if (b === 0) {
        this.eqResult = c === 0 ? '恒等式，x 为任意数' : '无解';
        return;
      }
      this.eqResult = `一次方程：x = ${fmtResult(-c / b)}`;
      return;
    }
    const d = b * b - 4 * a * c;
    if (d > 0) {
      const x1 = (-b + Math.sqrt(d)) / (2 * a);
      const x2 = (-b - Math.sqrt(d)) / (2 * a);
      this.eqResult = `Δ = ${fmtResult(d)} > 0，两个实根\nx₁ = ${fmtResult(x1)}\nx₂ = ${fmtResult(x2)}`;
    } else if (d === 0) {
      this.eqResult = `Δ = 0，重根\nx = ${fmtResult(-b / (2 * a))}`;
    } else {
      const re = fmtResult(-b / (2 * a));
      const im = fmtResult(Math.sqrt(-d) / (2 * a));
      this.eqResult = `Δ = ${fmtResult(d)} < 0，共轭复根\nx₁ = ${re} + ${im}i\nx₂ = ${re} − ${im}i`;
    }
  }

  /** f(x)=0 数值求根：[-10,10] 均匀扫描变号区间 + 二分法 */
  solveFx(): void {
    const expr = normalizeFx(this.fxExpr);
    if (expr.length === 0) {
      this.fxRoots = '请输入表达式';
      return;
    }
    const f = (x: number): number => this.parser.evalWithX(expr, x, this.degMode);
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
        if (prevY === 0) {
          roots.push(prevX);
        } else if (prevY * y < 0) {
          // 二分求根
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
    // 去重（相邻根间距 < 1e-6 视为同根）
    const uniq: number[] = [];
    for (const r of roots) {
      if (uniq.length === 0 || Math.abs(r - uniq[uniq.length - 1]) > 1e-6) {
        uniq.push(r);
      }
    }
    if (uniq.length === 0) {
      this.fxRoots = '在 [-10, 10] 内未找到实根（不排除区间外或偶重根）';
    } else {
      const parts: string[] = [];
      for (let i = 0; i < uniq.length; i++) {
        const clean = Math.abs(uniq[i]) < 1e-10 ? 0 : uniq[i];
        parts.push(`x${i + 1} = ${fmtResult(parseFloat(clean.toPrecision(8)))}`);
      }
      this.fxRoots = `找到 ${uniq.length} 个根：\n${parts.join('\n')}`;
    }
  }

  // ════════ 分数计算 ════════
  calcFraction(): void {
    const n1 = parseInt(this.fracN1);
    const d1 = parseInt(this.fracD1);
    const n2 = parseInt(this.fracN2);
    const d2 = parseInt(this.fracD2);
    if (isNaN(n1) || isNaN(d1) || isNaN(n2) || isNaN(d2) || d1 === 0 || d2 === 0) {
      this.fracResult = '请输入有效分数（分母非 0）';
      return;
    }
    let rn = 0;
    let rd = 0;
    if (this.fracOp === 0) {
      rn = n1 * d2 + n2 * d1;
      rd = d1 * d2;
    } else if (this.fracOp === 1) {
      rn = n1 * d2 - n2 * d1;
      rd = d1 * d2;
    } else if (this.fracOp === 2) {
      rn = n1 * n2;
      rd = d1 * d2;
    } else {
      if (n2 === 0) {
        this.fracResult = '除数不能为 0';
        return;
      }
      rn = n1 * d2;
      rd = d1 * n2;
    }
    if (rd < 0) {
      rn = -rn;
      rd = -rd;
    }
    const g = gcd(rn, rd);
    const sn = g > 0 ? rn / g : rn;
    const sd = g > 0 ? rd / g : rd;
    if (sd === 1) {
      this.fracResult = `= ${sn}`;
    } else {
      const dec = fmtResult(sn / sd);
      // 带分数
      let mixed = '';
      if (Math.abs(sn) > sd) {
        const whole = sn > 0 ? Math.floor(sn / sd) : -Math.floor(-sn / sd);
        const rem = Math.abs(sn) % sd;
        mixed = `（带分数 ${whole} ${rem}/${sd}）`;
      }
      this.fracResult = `= ${sn}/${sd} ${mixed}\n≈ ${dec}`;
    }
  }

  /** 小数 → 分数：连分数展开法 */
  decToFraction(): void {
    const v = parseFloat(this.decInput);
    if (isNaN(v)) {
      this.decResult = '请输入有效小数';
      return;
    }
    let x = Math.abs(v);
    let n0 = 0;
    let d0 = 1;
    let n1 = 1;
    let d1 = 0;
    let val = x;
    for (let i = 0; i < 40; i++) {
      const a = Math.floor(val);
      const n2 = a * n1 + n0;
      const d2 = a * d1 + d0;
      if (d2 > 1e9) {
        break;
      }
      n0 = n1;
      d0 = d1;
      n1 = n2;
      d1 = d2;
      const frac = val - a;
      if (frac < 1e-12 || Math.abs(n1 / d1 - x) < 1e-12) {
        break;
      }
      val = 1 / frac;
    }
    const sign = v < 0 ? '−' : '';
    if (d1 === 1) {
      this.decResult = `= ${sign}${n1}`;
    } else {
      this.decResult = `= ${sign}${n1}/${d1}`;
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
  inputField(placeholder: string, value: string, onChangeValue: (v: string) => void) {
    TextInput({ placeholder: placeholder, text: value })
      .height(44)
      .borderRadius(12)
      .backgroundColor($r('app.color.bg_card'))
      .fontColor($r('app.color.text_primary'))
      .onChange((v: string) => onChangeValue(v))
  }

  @Builder
  resultCard(text: string) {
    Text(text)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_primary'))
      .lineHeight(26)
      .width('100%')
      .padding(16)
      .borderRadius(14)
      .backgroundColor($r('app.color.bg_card'))
  }

  build() {
    NavDestination() {
      Column({ space: 10 }) {
        // 模式切换
        Scroll() {
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
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

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
          .height(160)
          .padding(14)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
          .alignItems(HorizontalAlign.End)

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
          // ── 方程求解 ──
          Scroll() {
            Column({ space: 14 }) {
              Text('一元二次方程  ax² + bx + c = 0')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .alignSelf(ItemAlign.Start)
              Row({ space: 8 }) {
                Column({ space: 4 }) {
                  Text('a').fontSize(12).fontColor($r('app.color.text_secondary'))
                  this.inputField('a', this.eqA, (v) => { this.eqA = v; })
                }.layoutWeight(1)
                Column({ space: 4 }) {
                  Text('b').fontSize(12).fontColor($r('app.color.text_secondary'))
                  this.inputField('b', this.eqB, (v) => { this.eqB = v; })
                }.layoutWeight(1)
                Column({ space: 4 }) {
                  Text('c').fontSize(12).fontColor($r('app.color.text_secondary'))
                  this.inputField('c', this.eqC, (v) => { this.eqC = v; })
                }.layoutWeight(1)
              }
              .width('100%')
              Button('求解（含复根）')
                .width('100%').height(46)
                .fontSize(15).fontWeight(FontWeight.Bold)
                .backgroundColor($r('app.color.accent'))
                .onClick(() => this.solveQuadratic())
              if (this.eqResult.length > 0) {
                this.resultCard(this.eqResult)
              }

              Divider().margin({ top: 6, bottom: 6 })

              Text('任意方程  f(x) = 0（数值求根）')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .alignSelf(ItemAlign.Start)
              this.inputField('如 x^2−2、sin x − 0.5、x^3−3x+1', this.fxExpr, (v) => { this.fxExpr = v; })
              Button('在 [-10, 10] 内求根')
                .width('100%').height(46)
                .fontSize(15).fontWeight(FontWeight.Bold)
                .backgroundColor($r('app.color.accent'))
                .onClick(() => this.solveFx())
              if (this.fxRoots.length > 0) {
                this.resultCard(this.fxRoots)
              }
            }
            .width('100%')
            .padding({ bottom: 20 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        } else if (this.mode === 3) {
          // ── 分数计算 ──
          Scroll() {
            Column({ space: 14 }) {
              Text('分数四则运算')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .alignSelf(ItemAlign.Start)
              Row({ space: 10 }) {
                // 分数 1
                Column({ space: 4 }) {
                  this.inputField('分子', this.fracN1, (v) => { this.fracN1 = v; })
                  Divider().strokeWidth(2).color($r('app.color.text_primary'))
                  this.inputField('分母', this.fracD1, (v) => { this.fracD1 = v; })
                }
                .layoutWeight(2)
                // 运算符
                Column() {
                  Text(['＋', '－', '×', '÷'][this.fracOp])
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                    .width(48).height(48)
                    .textAlign(TextAlign.Center)
                    .borderRadius(24)
                    .backgroundColor($r('app.color.accent'))
                    .onClick(() => {
                      this.fracOp = (this.fracOp + 1) % 4;
                    })
                  Text('点击切换')
                    .fontSize(10)
                    .fontColor($r('app.color.text_secondary'))
                    .margin({ top: 4 })
                }
                .layoutWeight(1)
                // 分数 2
                Column({ space: 4 }) {
                  this.inputField('分子', this.fracN2, (v) => { this.fracN2 = v; })
                  Divider().strokeWidth(2).color($r('app.color.text_primary'))
                  this.inputField('分母', this.fracD2, (v) => { this.fracD2 = v; })
                }
                .layoutWeight(2)
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              Button('计算并约分')
                .width('100%').height(46)
                .fontSize(15).fontWeight(FontWeight.Bold)
                .backgroundColor($r('app.color.accent'))
                .onClick(() => this.calcFraction())
              if (this.fracResult.length > 0) {
                this.resultCard(this.fracResult)
              }

              Divider().margin({ top: 6, bottom: 6 })

              Text('小数 → 分数')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .alignSelf(ItemAlign.Start)
              this.inputField('如 0.375、3.14159、0.333333', this.decInput, (v) => { this.decInput = v; })
              Button('化为最简分数')
                .width('100%').height(46)
                .fontSize(15).fontWeight(FontWeight.Bold)
                .backgroundColor($r('app.color.accent'))
                .onClick(() => this.decToFraction())
              if (this.decResult.length > 0) {
                this.resultCard(this.decResult)
              }
            }
            .width('100%')
            .padding({ bottom: 20 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
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
