import { SciParser, fmtResult, normalizeFx, equationToFx, toFraction } from '../../utils/SciParser';

interface HistoryItem {
  expr: string;
  result: string;
}

interface ResultRow {
  label: string;
  value: string;
}

interface Template {
  label: string;
  expr: string;
}

interface TemplateGroup {
  label: string;
  exprs: string[];
}

/** 基础键盘：对齐参考 App，可上下滚动（□ 为占位符模板键） */
const BASIC_KEYS: string[][] = [
  ['log□', '□^□', '√□', '□/□', '÷'],
  ['x', '7', '8', '9', '×'],
  ['y', '4', '5', '6', '−'],
  ['z', '1', '2', '3', '+'],
  ['(', ')', '0', '.', '='],
  ['log₂', 'log₁₀', 'ln', '°', '′″'],
  ['<', '≤', '>', '≥', '∞'],
  ['π', 'e', 'i', '', '']
];

/** 函数键盘：对齐参考 App f 面板（□ 为占位符模板键） */
const FUNC_KEYS: string[][] = [
  ['sin', 'cos', 'tan', '公倍', '公约'],
  ['arcsin', 'arccos', 'arctan', '|□|', '□!'],
  ['∫□', 'lim', 'A□', 'C□', ''],
  ['', '', '', '', '']
];

/** 字母键盘：对齐参考 App，只保留常用字母 a-p 两行 */
const AZ_KEYS: string[][] = [
  ['a', 'b', 'c', 'h', 'k'],
  ['p', '', '', '', '']
];

/** a-z 面板下方的常用函数模板（对齐截图） */
const AZ_TEMPLATES: Template[] = [
  { label: '一元一次函数', expr: 'y=kx+b' },
  { label: '反比例函数', expr: 'y=k÷x' },
  { label: '一元二次函数', expr: 'y=ax^2+bx+c' },
  { label: '一元二次·顶点式', expr: 'y=a(x−h)^2+k' }
];

/** f(x) 模板：对齐参考 App，左分类右公式，一类可多式 */
const TEMPLATE_GROUPS: TemplateGroup[] = [
  { label: '指数函数', exprs: ['y=a^x'] },
  { label: '对数函数', exprs: ['y=log(a,x)'] },
  { label: '圆', exprs: ['(x−a)^2+(y−b)^2=1', 'x^2+y^2+ax+by+c=0'] },
  { label: '椭圆', exprs: ['x^2÷a^2+y^2÷b^2=1', '(x−k)^2÷a^2+(y−h)^2÷b^2=1'] },
  { label: '双曲线', exprs: ['x^2÷a^2−y^2÷b^2=1', '(x−k)^2÷a^2−(y−h)^2÷b^2=1'] },
  { label: '抛物线', exprs: ['y^2=2px'] }
];

const MODES: string[] = ['计算', '绘图', '统计'];

@Component
export struct SuperCalcPage {
  @State mode: number = 0;
  // ── 计算（表达式 + 光标编辑）──
  @State expression: string = '';
  @State cursor: number = 0;
  @State result: string = '';
  @State fracForm: string = '';
  @State degMode: boolean = true;
  @State panel: number = 0;   // 0 基础 1 函数 2 模板
  @State history: HistoryItem[] = [];
  private ans: number = 0;
  // ── 绘图 ──
  @State plotExpr: string = 'sin x';
  @State plotError: string = '';
  @State plotW: number = 320;
  // ── 统计 ──
  @State statInput: string = '';
  @State statRows: ResultRow[] = [];

  private parser: SciParser = new SciParser();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private plotCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private readonly PLOT_H: number = 240;
  private readonly FNS: string[] = ['arcsin', 'arccos', 'arctan', 'asin', 'acos', 'atan',
    'log2', 'lcm(', 'gcd(', 'abs(', 'sin', 'cos', 'tan', 'abs', 'ln', 'log', 'ANS', 'A(', 'C('];

  // ════════ 光标编辑 ════════
  insertText(s: string): void {
    this.expression = this.expression.substring(0, this.cursor) + s + this.expression.substring(this.cursor);
    this.cursor += s.length;
    this.result = '';
    this.fracForm = '';
  }

  backspace(): void {
    if (this.cursor === 0) {
      return;
    }
    const before = this.expression.substring(0, this.cursor);
    let cut = 1;
    for (const fn of this.FNS) {
      if (before.endsWith(fn)) {
        cut = fn.length;
        break;
      }
    }
    this.expression = before.substring(0, before.length - cut) + this.expression.substring(this.cursor);
    this.cursor -= cut;
    this.result = '';
    this.fracForm = '';
  }

  moveCursor(delta: number): void {
    let target = this.cursor + delta;
    // 跨函数名整体跳过
    if (delta < 0) {
      const before = this.expression.substring(0, this.cursor);
      for (const fn of this.FNS) {
        if (before.endsWith(fn)) {
          target = this.cursor - fn.length;
          break;
        }
      }
    } else {
      const after = this.expression.substring(this.cursor);
      for (const fn of this.FNS) {
        if (after.startsWith(fn)) {
          target = this.cursor + fn.length;
          break;
        }
      }
    }
    this.cursor = Math.max(0, Math.min(this.expression.length, target));
  }

  clearAll(): void {
    this.expression = '';
    this.cursor = 0;
    this.result = '';
    this.fracForm = '';
  }

  // ════════ 执行：含 = 求解方程，否则求值 ════════
  runCalc(): void {
    const s = this.expression.trim();
    if (s.length === 0) {
      return;
    }
    // y= / f(x)= 前缀只是函数写法，不当方程；其余含 = 走方程求解
    const eqIdx = s.indexOf('=');
    const lhsKey = eqIdx >= 0 ? s.substring(0, eqIdx).replace(/\s/g, '').toLowerCase() : '';
    const isEquation = eqIdx >= 0 && lhsKey !== 'y' && lhsKey !== 'f(x)' && lhsKey !== 'fx' && lhsKey !== 'f';

    if (isEquation || (eqIdx < 0 && s.includes('x'))) {
      this.result = this.solveEquation(s);
      this.fracForm = '';
      this.history = [{ expr: s, result: '已求解' } as HistoryItem, ...this.history].slice(0, 20);
      return;
    }
    try {
      const v = this.parser.parse(normalizeFx(s), this.degMode, this.ans);
      this.result = `= ${fmtResult(v)}`;
      const frac = toFraction(v, 9999);
      this.fracForm = frac !== undefined ? frac : '';
      this.ans = v;
      this.history = [{ expr: s, result: fmtResult(v) } as HistoryItem, ...this.history].slice(0, 20);
    } catch (err) {
      this.result = (err as Error).message;
      this.fracForm = '';
    }
  }

  solveEquation(input: string): string {
    const fx = equationToFx(input);
    const f = (x: number): number => this.parser.evalWithX(fx, x, this.degMode);

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
      return '方程无法求值，请检查输入（未知数用 x）';
    }
    if (!isNaN(pv[0]) && !isNaN(pv[1]) && !isNaN(pv[2]) && !isNaN(pv[3]) && !isNaN(pv[5])) {
      const c = pv[0];
      const a = (pv[1] + pv[2]) / 2 - c;
      const b = (pv[1] - pv[2]) / 2;
      const fit2 = a * 4 + b * 2 + c;
      const fit3 = a * 9 + b * 3 + c;
      const scale = Math.max(1, Math.abs(pv[3]), Math.abs(pv[5]));
      if (Math.abs(fit2 - pv[3]) < 1e-9 * scale && Math.abs(fit3 - pv[5]) < 1e-9 * scale) {
        return this.solvePolynomial(a, b, c);
      }
    }
    return this.solveNumeric(f);
  }

  solvePolynomial(a: number, b: number, c: number): string {
    const withFrac = (v: number): string => {
      const fr = toFraction(v, 9999);
      return fr !== undefined ? `${fmtResult(v)}（${fr}）` : fmtResult(v);
    };
    if (Math.abs(a) < 1e-12) {
      if (Math.abs(b) < 1e-12) {
        return Math.abs(c) < 1e-12 ? '恒等式：x 为任意数' : '矛盾式：无解';
      }
      return `一次方程\nx = ${withFrac(-c / b)}`;
    }
    const d = b * b - 4 * a * c;
    const head = `二次方程，Δ = ${fmtResult(d)}`;
    if (d > 1e-12) {
      const x1 = (-b + Math.sqrt(d)) / (2 * a);
      const x2 = (-b - Math.sqrt(d)) / (2 * a);
      return `${head} > 0\nx₁ = ${withFrac(x1)}\nx₂ = ${withFrac(x2)}`;
    }
    if (Math.abs(d) <= 1e-12) {
      return `${head} = 0，重根\nx = ${withFrac(-b / (2 * a))}`;
    }
    const re = fmtResult(-b / (2 * a));
    const im = fmtResult(Math.sqrt(-d) / (2 * Math.abs(a)));
    return `${head} < 0，共轭复根\nx₁ = ${re} + ${im}i\nx₂ = ${re} − ${im}i`;
  }

  solveNumeric(f: (x: number) => number): string {
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
      return '数值求解：[-10, 10] 内未找到实根\n（不排除区间外的根或偶重根）';
    }
    const parts: string[] = [];
    for (let i = 0; i < uniq.length; i++) {
      const clean = Math.abs(uniq[i]) < 1e-10 ? 0 : uniq[i];
      const v = parseFloat(clean.toPrecision(8));
      const fr = toFraction(v, 9999);
      parts.push(`x${i + 1} = ${fmtResult(v)}${fr !== undefined ? `（${fr}）` : ''}`);
    }
    return `数值求解，${uniq.length} 个根：\n${parts.join('\n')}`;
  }

  // ════════ 键盘按键 ════════
  onKey(k: string): void {
    if (k.length === 0) {
      return;
    }
    if (k === 'DEG') {
      this.degMode = !this.degMode;
      return;
    }
    // 模板键 → 文本形式
    if (k === 'log□') {
      this.insertText('log(');   // 支持 log(x) 与 log(底,真数)
      return;
    }
    if (k === '□^□') {
      this.insertText('^');
      return;
    }
    if (k === '√□') {
      this.insertText('√');
      return;
    }
    if (k === '□/□') {
      this.insertText('÷');
      return;
    }
    if (k === 'log₂') {
      this.insertText('log2');
      return;
    }
    if (k === 'log₁₀') {
      this.insertText('log');
      return;
    }
    if (k === '′″') {
      // 分′秒″复合键：先插 ′，紧接再按升级为 ″
      if (this.cursor > 0 && this.expression[this.cursor - 1] === '′') {
        this.expression = this.expression.substring(0, this.cursor - 1) + '″' + this.expression.substring(this.cursor);
      } else {
        this.insertText('′');
      }
      return;
    }
    // f 面板模板键
    if (k === '公倍') {
      this.insertText('lcm(');
      return;
    }
    if (k === '公约') {
      this.insertText('gcd(');
      return;
    }
    if (k === '|□|') {
      this.insertText('abs(');
      return;
    }
    if (k === '□!') {
      this.insertText('!');
      return;
    }
    if (k === 'A□') {
      this.insertText('A(');
      return;
    }
    if (k === 'C□') {
      this.insertText('C(');
      return;
    }
    if (k === '∫□' || k === 'lim') {
      this.result = `${k === 'lim' ? '极限' : '积分'}属于符号运算，暂未支持`;
      this.fracForm = '';
      return;
    }
    this.insertText(k);
  }

  private isPlainKey(k: string): boolean {
    if ((k >= '0' && k <= '9') || k === '.') {
      return true;
    }
    if (k === 'x' || k === 'y' || k === 'z' || k === '(' || k === ')') {
      return true;
    }
    return this.panel === 2 && k.length === 1 && k >= 'a' && k <= 'z';
  }

  keyBg(k: string): ResourceColor {
    return this.isPlainKey(k) ? $r('app.color.bg_card') : '#2E3140';
  }

  keyFg(k: string): ResourceColor {
    return this.isPlainKey(k) ? $r('app.color.text_primary') : '#7B88FF';
  }

  keyLabel(k: string): string {
    if (k === 'DEG') {
      return this.degMode ? 'DEG' : 'RAD';
    }
    return k;
  }

  // ════════ 绘图（与前版一致）════════
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
    c.beginPath();
    c.moveTo(px(0), 0);
    c.lineTo(px(0), H);
    c.stroke();
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

  // ════════ 统计（与前版一致）════════
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

  /** 侧边栏圆形按钮（f(x) 按截图用橙色高亮） */
  @Builder
  sideButton(label: string, idx: number) {
    Text(label)
      .fontSize(idx === 0 ? 10 : 13)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.panel === idx ? Color.White : (idx === 3 ? '#FF9F43' : $r('app.color.text_secondary')))
      .textAlign(TextAlign.Center)
      .width(42)
      .height(42)
      .borderRadius(21)
      .backgroundColor(this.panel === idx ? (idx === 3 ? '#FF9F43' : $r('app.color.accent')) : $r('app.color.bg_card'))
      .onClick(() => {
        this.panel = idx;
      })
  }

  build() {
    NavDestination() {
      Column({ space: 8 }) {
        // 模式 Tab
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
          // ══ 显示区：带光标的表达式 + 结果 ══
          Column({ space: 6 }) {
            Scroll() {
              Column({ space: 2 }) {
                ForEach(this.history, (h: HistoryItem) => {
                  Text(`${h.expr}  →  ${h.result}`)
                    .fontSize(11)
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .textAlign(TextAlign.End)
                    .onClick(() => {
                      this.expression = h.expr;
                      this.cursor = h.expr.length;
                      this.result = '';
                      this.fracForm = '';
                    })
                }, (h: HistoryItem, i: number) => `${i}-${h.expr}`)
              }
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .align(Alignment.BottomEnd)

            // 表达式 + 光标
            Text() {
              if (this.expression.length === 0) {
                Span('输入算式或方程…')
                  .fontSize(16)
                  .fontColor($r('app.color.text_secondary'))
              } else {
                Span(this.expression.substring(0, this.cursor))
                  .fontSize(24)
                  .fontColor($r('app.color.text_primary'))
              }
              Span('❘')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.accent'))
              Span(this.expression.substring(this.cursor))
                .fontSize(24)
                .fontColor($r('app.color.text_primary'))
            }
            .textAlign(TextAlign.End)
            .maxLines(2)
            .width('100%')

            if (this.result.length > 0) {
              Text(`${this.result}${this.fracForm.length > 0 ? `  =  ${this.fracForm}` : ''}`)
                .fontSize(this.result.includes('\n') ? 15 : 24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.accent'))
                .lineHeight(this.result.includes('\n') ? 24 : 30)
                .maxLines(4)
                .textAlign(TextAlign.End)
                .width('100%')
            }
          }
          .width('100%')
          .height(190)
          .padding(14)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
          .alignItems(HorizontalAlign.End)

          // ══ 编辑工具条（对齐截图：清空 回车执行 ◀ ▶ 退格）══
          Row({ space: 8 }) {
            Text('🗑')
              .fontSize(16)
              .textAlign(TextAlign.Center)
              .layoutWeight(1).height(42)
              .borderRadius(12)
              .backgroundColor('#33F5576C')
              .onClick(() => this.clearAll())
            Text('↵')
              .fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .layoutWeight(2).height(42)
              .borderRadius(12)
              .backgroundColor($r('app.color.accent'))
              .onClick(() => this.runCalc())
            Text('◀')
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1).height(42)
              .borderRadius(12)
              .backgroundColor($r('app.color.bg_card'))
              .onClick(() => this.moveCursor(-1))
            Text('▶')
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1).height(42)
              .borderRadius(12)
              .backgroundColor($r('app.color.bg_card'))
              .onClick(() => this.moveCursor(1))
            Text('⌫')
              .fontSize(17)
              .fontColor('#7B88FF')
              .textAlign(TextAlign.Center)
              .layoutWeight(1).height(42)
              .borderRadius(12)
              .backgroundColor('#2E3140')
              .onClick(() => this.backspace())
          }
          .width('100%')

          // ══ 侧边栏（+−×÷ / f / a-z / f(x)）+ 面板 ══
          Row({ space: 8 }) {
            Column({ space: 10 }) {
              this.sideButton('+−\n×÷', 0)
              this.sideButton('f', 1)
              this.sideButton('a-z', 2)
              this.sideButton('f(x)', 3)
              Blank()
            }
            .width(50)
            .height('100%')

            if (this.panel <= 2) {
              // 可滚动键盘（参考 App：基础面板 8 行，可视约 5 行）
              Scroll() {
                Column({ space: 6 }) {
                  ForEach(this.panel === 0 ? BASIC_KEYS : (this.panel === 1 ? FUNC_KEYS : AZ_KEYS), (row: string[]) => {
                    Row({ space: 6 }) {
                      ForEach(row, (k: string) => {
                        Text(this.keyLabel(k))
                          .fontSize(k.length > 2 ? 12 : 18)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(this.keyFg(k))
                          .textAlign(TextAlign.Center)
                          .layoutWeight(1)
                          .height(52)
                          .borderRadius(12)
                          .backgroundColor(k.length === 0 ? Color.Transparent : this.keyBg(k))
                          .onClick(() => this.onKey(k))
                      }, (k: string, j: number) => `${k}-${j}`)
                    }
                    .width('100%')
                  }, (row: string[], i: number) => `p${this.panel}r${i}`)

                  if (this.panel === 2) {
                    // a-z 面板下方：常用函数模板（对齐截图分隔条+两列列表）
                    Divider()
                      .strokeWidth(3)
                      .color('#33888888')
                      .margin({ top: 4, bottom: 4 })
                    ForEach(AZ_TEMPLATES, (t: Template) => {
                      Row() {
                        Text(t.label)
                          .fontSize(14)
                          .fontColor($r('app.color.text_secondary'))
                          .width('42%')
                          .textAlign(TextAlign.Center)
                        Divider()
                          .vertical(true)
                          .height(24)
                        Text(t.expr)
                          .fontSize(16)
                          .fontWeight(FontWeight.Medium)
                          .fontColor($r('app.color.text_primary'))
                          .layoutWeight(1)
                          .textAlign(TextAlign.Center)
                      }
                      .width('100%')
                      .padding({ top: 14, bottom: 14 })
                      .borderRadius(12)
                      .backgroundColor($r('app.color.bg_card'))
                      .onClick(() => {
                        this.expression = t.expr;
                        this.cursor = t.expr.length;
                        this.result = '';
                        this.fracForm = '';
                      })
                    }, (t: Template) => t.label)
                  }
                }
                .width('100%')
              }
              .layoutWeight(1)
              .height('100%')
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring)
            } else {
              // f(x) 模板：左分类名跨行 右公式列表（对齐截图）
              Scroll() {
                Column() {
                  ForEach(TEMPLATE_GROUPS, (g: TemplateGroup, gi: number) => {
                    Row() {
                      Text(g.label)
                        .fontSize(15)
                        .fontColor($r('app.color.text_secondary'))
                        .width('34%')
                        .textAlign(TextAlign.Center)
                      Column() {
                        ForEach(g.exprs, (ex: string, ei: number) => {
                          Text(ex)
                            .fontSize(15)
                            .fontWeight(FontWeight.Medium)
                            .fontColor($r('app.color.text_primary'))
                            .maxLines(1)
                            .minFontSize(10)
                            .maxFontSize(15)
                            .textAlign(TextAlign.Center)
                            .width('100%')
                            .padding({ top: 16, bottom: 16, left: 6, right: 6 })
                            .onClick(() => {
                              this.expression = ex;
                              this.cursor = ex.length;
                              this.result = '';
                              this.fracForm = '';
                            })
                          if (ei < g.exprs.length - 1) {
                            Divider().strokeWidth(0.5).color('#33888888')
                          }
                        }, (ex: string) => ex)
                      }
                      .layoutWeight(1)
                      .border({ width: { left: 0.5 }, color: '#33888888' })
                    }
                    .width('100%')
                    .alignItems(VerticalAlign.Center)
                    if (gi < TEMPLATE_GROUPS.length - 1) {
                      Divider().strokeWidth(0.5).color('#33888888')
                    }
                  }, (g: TemplateGroup) => g.label)
                }
                .width('100%')
              }
              .layoutWeight(1)
              .height('100%')
              .borderRadius(12)
              .backgroundColor($r('app.color.bg_card'))
              .scrollBar(BarState.Off)
              .edgeEffect(EdgeEffect.Spring)
            }
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
