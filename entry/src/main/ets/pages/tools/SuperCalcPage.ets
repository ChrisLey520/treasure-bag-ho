import { SciParser, fmtResult, normalizeFx, equationToFx, toFraction } from '../../utils/SciParser';

interface HistoryItem {
  expr: string;
  result: string;
}

interface LinResult {
  kind: string;      // unique / none / inf
  sol: number[];
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

/** 回显区渲染元素：带原字符串索引，支持上/下标层级与参数块 */
interface RItem {
  s: string;        // 显示文本（参数块为空串）
  box: boolean;     // 是否参数输入块
  level: number;    // 0 正常 1 上标 2 下标
  start: number;    // 在表达式串中的起始索引
  end: number;      // 结束索引（不含）
  cb: boolean;      // 光标画在该元素之前
  sel: boolean;     // 参数块处于选中态（光标落在块上）
}

/** 回显区按整体渲染的函数名（长名优先匹配） */
const RENDER_FNS: string[] = ['arcsin', 'arccos', 'arctan', 'log10', 'log2',
  'lcm', 'gcd', 'abs', 'sin', 'cos', 'tan', 'ANS', 'lim', 'log', 'ln'];

/** 基础键盘：对齐参考 App，可上下滚动（□ 为占位符模板键） */
const BASIC_KEYS: string[][] = [
  ['log□', '□^□', '√□', '□/□', '÷'],
  ['x', '7', '8', '9', '×'],
  ['y', '4', '5', '6', '−'],
  ['z', '1', '2', '3', '+'],
  ['(', ')', '0', '.', '='],
  ['log₂', 'log₁₀', 'ln', '°', '′″'],
  ['<', '≤', '>', '≥', '∞'],
  ['π', 'e', 'i', ';', '']
];

/** 函数键盘：对齐参考 App f 面板（□ 为占位符模板键） */
const FUNC_KEYS: string[][] = [
  ['sin', 'cos', 'tan', '公倍', '公约'],
  ['arcsin', 'arccos', 'arctan', '|□|', '□!'],
  ['∫□', 'lim', 'A□', 'C□', '']
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
  @State cursorOn: boolean = true;   // 光标闪烁相位
  private blinkTimer: number = -1;

  aboutToAppear(): void {
    this.blinkTimer = setInterval(() => {
      this.cursorOn = !this.cursorOn;
    }, 530);
  }

  aboutToDisappear(): void {
    if (this.blinkTimer >= 0) {
      clearInterval(this.blinkTimer);
    }
  }

  /** 光标竖条：高度与所在位置的字号/输入块一致，530ms 闪烁 */
  @Builder
  cursorBar(h: number, color: ResourceColor, yOff: number) {
    Text('')
      .width(2)
      .height(h)
      .borderRadius(1)
      .backgroundColor(color)
      .margin({ left: 1, right: 1 })
      .offset({ x: 0, y: yOff })
      .opacity(this.cursorOn ? 1 : 0)
  }

  private parser: SciParser = new SciParser();
  private lastSpanTap: number = 0;
  private kbScroller: Scroller = new Scroller();
  private secOffsets: number[] = [0, 0, 0, 0];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private plotCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private readonly PLOT_H: number = 240;
  private readonly FNS: string[] = ['arcsin', 'arccos', 'arctan', 'asin', 'acos', 'atan',
    'log2', 'lcm(', 'gcd(', 'abs(', 'lim(', 'sin', 'cos', 'tan', 'abs', 'ln', 'log', 'ANS', 'A(', 'C(', '∫('];

  // ════════ 光标编辑 ════════
  insertText(s: string): void {
    // 光标停在占位块 □ 上时，输入直接替换该块
    let after = this.expression.substring(this.cursor);
    if (after.startsWith('□')) {
      after = after.substring(1);
    }
    this.expression = this.expression.substring(0, this.cursor) + s + after;
    this.cursor += s.length;
    this.result = '';
    this.fracForm = '';
  }

  /** 插入含 □ 占位块的模板，光标落在第一个 □ 上 */
  insertTemplate(s: string): void {
    let after = this.expression.substring(this.cursor);
    if (after.startsWith('□')) {
      after = after.substring(1);
    }
    const start = this.cursor;
    this.expression = this.expression.substring(0, start) + s + after;
    const boxIdx = s.indexOf('□');
    this.cursor = boxIdx >= 0 ? start + boxIdx : start + s.length;
    this.result = '';
    this.fracForm = '';
  }

  /** 剔除 ∫(…)/lim(…) 整段后检测自由变量（积分/极限变量不算未知数） */
  private hasFreeVar(s: string): boolean {
    let out = '';
    let i = 0;
    while (i < s.length) {
      let hit = 0;
      if (s[i] === '∫' && s[i + 1] === '(') {
        hit = 2;
      } else if (s.startsWith('lim(', i)) {
        hit = 4;
      }
      if (hit > 0) {
        i += hit;
        let d = 1;
        while (i < s.length && d > 0) {
          if (s[i] === '(') {
            d += 1;
          } else if (s[i] === ')') {
            d -= 1;
          }
          i += 1;
        }
        continue;
      }
      out += s[i];
      i += 1;
    }
    return /[xyz]/.test(out.replace(/lcm|gcd|abs|arcsin|arccos|arctan|asin|acos|atan|ans/gi, ''));
  }

  /** 光标前是否已有可作为左操作数的内容（决定 ^ ! ÷ 是否补前置占位块） */
  private hasOperandBefore(): boolean {
    if (this.cursor === 0) {
      return false;
    }
    const ch = this.expression[this.cursor - 1];
    return (ch >= '0' && ch <= '9') || ch === ')' || ch === 'x' || ch === 'y' || ch === 'z' ||
      ch === 'π' || ch === 'e' || ch === 'i' || ch === '!' || ch === '%' || ch === '□' ||
      ch === '°' || ch === '′' || ch === '″' || ch === '.';
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

  /**
   * 回显区数学式富渲染：把表达式扫描为带原串索引的元素序列。
   * log(b,x)→log 下标 b (x)、A/C(n,r)→下标 n 上标 r、^→上标、
   * abs(x)→|x|、log2/log10→log 下标底数；□ 为参数输入块
   */
  buildRender(): RItem[] {
    const s = this.expression;
    const items: RItem[] = [];
    const modeStack: string[] = [];   // 与括号深度同步：''/logbase/logarg/abs/sup/An/Ar
    let supRunUntil = -1;
    let supPending = false;
    let i = 0;

    const curLevel = (idx: number): number => {
      if (idx < supRunUntil) {
        return 1;
      }
      for (let d = modeStack.length - 1; d >= 0; d--) {
        const m = modeStack[d];
        if (m === 'sup' || m === 'Ar' || m === 'intHi') {
          return 1;
        }
        if (m === 'logbase' || m === 'An' || m === 'intLo' || m === 'limPt') {
          return 2;
        }
      }
      return 0;
    };
    const push = (txt: string, box: boolean, st: number, en: number): void => {
      items.push({ s: txt, box: box, level: curLevel(st), start: st, end: en, cb: false, sel: false } as RItem);
    };
    // openIdx 处的括号内、深度 1 上是否有逗号（判断双参形式）
    const hasComma = (openIdx: number): boolean => {
      let d = 0;
      for (let j = openIdx; j < s.length; j++) {
        const c = s[j];
        if (c === '(') {
          d += 1;
        } else if (c === ')') {
          d -= 1;
          if (d === 0) {
            return false;
          }
        } else if (c === ',' && d === 1) {
          return true;
        }
      }
      return false;
    };

    while (i < s.length) {
      const ch = s[i];
      let matched = '';
      for (const fn of RENDER_FNS) {
        if (s.startsWith(fn, i)) {
          matched = fn;
          break;
        }
      }
      if (matched === 'log' && s[i + 3] === '(' && hasComma(i + 3)) {
        // log(底,真数)：底数下标，逗号处补可见 '('
        push('log', false, i, i + 3);
        modeStack.push('logbase');
        i += 4;
        continue;
      }
      if (matched === 'log2' || matched === 'log10') {
        push('log', false, i, i + 3);
        items.push({
          s: matched.substring(3), box: false, level: 2,
          start: i + 3, end: i + matched.length, cb: false, sel: false
        } as RItem);
        i += matched.length;
        continue;
      }
      if (matched === 'abs' && s[i + 3] === '(') {
        push('|', false, i, i + 4);
        modeStack.push('abs');
        i += 4;
        continue;
      }
      if (matched === 'lim' && s[i + 3] === '(') {
        // lim(趋近点,f)：渲染为 lim 下标 x→点，函数体正常位
        push('lim', false, i, i + 3);
        items.push({ s: 'x→', box: false, level: 2, start: i + 3, end: i + 4, cb: false, sel: false } as RItem);
        modeStack.push('limPt');
        i += 4;
        continue;
      }
      if (matched.length > 0) {
        push(matched, false, i, i + matched.length);
        i += matched.length;
        continue;
      }
      if ((ch === 'A' || ch === 'C') && s[i + 1] === '(' && hasComma(i + 1)) {
        push(ch, false, i, i + 1);
        modeStack.push('An');
        i += 2;
        continue;
      }
      if (ch === '∫' && s[i + 1] === '(') {
        // ∫(下限,上限,f)：下限下标、上限上标、函数体正常位
        push('∫', false, i, i + 1);
        modeStack.push('intLo');
        i += 2;
        continue;
      }
      if (ch === '(') {
        if (supPending) {
          modeStack.push('sup');   // 上标括号组：括号隐藏，内容升上标
          supPending = false;
        } else {
          modeStack.push('');
          push('(', false, i, i + 1);
        }
        i += 1;
        continue;
      }
      if (ch === ')') {
        const m = modeStack.length > 0 ? modeStack[modeStack.length - 1] : '';
        if (m === 'abs') {
          push('|', false, i, i + 1);
        } else if (m === '' || m === 'logarg') {
          push(')', false, i, i + 1);
        } else if (m === 'intBody') {
          push('dx', false, i, i + 1);
        }
        // sup/An/Ar/intLo/intHi/limPt/limBody 的右括号隐藏
        if (modeStack.length > 0) {
          modeStack.pop();
        }
        i += 1;
        continue;
      }
      if (ch === ',') {
        const m = modeStack.length > 0 ? modeStack[modeStack.length - 1] : '';
        if (m === 'logbase') {
          modeStack[modeStack.length - 1] = 'logarg';
          push('(', false, i, i + 1);
        } else if (m === 'An') {
          modeStack[modeStack.length - 1] = 'Ar';
        } else if (m === 'intLo') {
          modeStack[modeStack.length - 1] = 'intHi';
        } else if (m === 'intHi') {
          modeStack[modeStack.length - 1] = 'intBody';
        } else if (m === 'limPt') {
          modeStack[modeStack.length - 1] = 'limBody';
          push(' ', false, i, i + 1);
        } else {
          push(',', false, i, i + 1);
        }
        i += 1;
        continue;
      }
      if (ch === '^') {
        // ^ 本身隐藏，其后操作数升为上标
        if (s[i + 1] === '(') {
          supPending = true;
        } else {
          let j = i + 1;
          if (j < s.length && (s[j] === '−' || s[j] === '-')) {
            j += 1;
          }
          if (j < s.length && ((s[j] >= '0' && s[j] <= '9') || s[j] === '.')) {
            while (j < s.length && ((s[j] >= '0' && s[j] <= '9') || s[j] === '.')) {
              j += 1;
            }
          } else if (j < s.length) {
            j += 1;   // 单符号：x π e □ 等
          }
          supRunUntil = j;
        }
        i += 1;
        continue;
      }
      if (ch === '□') {
        push('', true, i, i + 1);
        i += 1;
        continue;
      }
      push(ch, false, i, i + 1);
      i += 1;
    }

    // 光标标注：落在参数块上→块选中；否则画在其前的元素上
    let done = false;
    for (let k = 0; k < items.length; k++) {
      const it = items[k];
      if (!done && this.cursor <= it.start) {
        if (it.box && this.cursor === it.start) {
          it.sel = true;
        } else {
          it.cb = true;
        }
        done = true;
      }
    }
    if (!done) {
      items.push({ s: '', box: false, level: 0, start: s.length, end: s.length, cb: true, sel: false } as RItem);
    }
    return items;
  }

  // ════════ 执行：含 = 求解方程，否则求值 ════════
  runCalc(): void {
    let s = this.expression.trim();
    if (s.length === 0) {
      return;
    }
    if (s.includes('□')) {
      const idx = this.expression.indexOf('□');
      this.cursor = idx;
      this.result = '请先填写高亮的参数块';
      this.fracForm = '';
      return;
    }
    // 方程组：分号分隔多个含 = 的式子
    if (s.includes(';') || s.includes('；')) {
      const eqs = s.split(/[;；]/).map((p: string): string => p.trim()).filter((p: string): boolean => p.length > 0);
      if (eqs.length >= 2) {
        this.result = this.solveSystem(eqs);
        this.fracForm = '';
        this.history = [{ expr: s, result: this.result.replace(/\n/g, '，') } as HistoryItem, ...this.history].slice(0, 20);
        return;
      }
      s = eqs.length === 1 ? eqs[0] : s;
    }
    // 末尾孤立的 = （右边为空）：按"按 = 出结果"处理，直接求值左边
    let eqIdx = s.indexOf('=');
    if (eqIdx >= 0 && s.substring(eqIdx + 1).trim().length === 0) {
      s = s.substring(0, eqIdx).trim();
      if (s.length === 0) {
        return;
      }
      eqIdx = s.indexOf('=');
    }
    // y= / f(x)= 前缀只是函数写法，不当方程；其余含 = 走方程求解
    const lhsKey = eqIdx >= 0 ? s.substring(0, eqIdx).replace(/\s/g, '').toLowerCase() : '';
    const isEquation = eqIdx >= 0 && lhsKey !== 'y' && lhsKey !== 'f(x)' && lhsKey !== 'fx' && lhsKey !== 'f';
    const hasVar = this.hasFreeVar(s);

    if (isEquation && !hasVar) {
      // 无变量等式：分别求两边，报成立/不成立
      try {
        const l = this.parser.parse(normalizeFx(s.substring(0, eqIdx)), this.degMode, this.ans);
        const r = this.parser.parse(normalizeFx(s.substring(eqIdx + 1)), this.degMode, this.ans);
        const eq = Math.abs(l - r) < 1e-10 * Math.max(1, Math.abs(l), Math.abs(r));
        this.result = eq
          ? `等式成立：两边 = ${fmtResult(l)}`
          : `等式不成立：左边 = ${fmtResult(l)}，右边 = ${fmtResult(r)}`;
      } catch (err) {
        this.result = (err as Error).message;
      }
      this.fracForm = '';
      this.history = [{ expr: s, result: '已验证' } as HistoryItem, ...this.history].slice(0, 20);
      return;
    }
    if (isEquation || (eqIdx < 0 && hasVar)) {
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

  // ════════ 方程组求解 ════════
  /**
   * 分号分隔的方程组：先探测各方程对 x/y/z 是否线性，
   * 全线性走高斯消元（含无解/无穷多解判定），
   * 否则多起点牛顿-差分法数值求解
   */
  solveSystem(eqs: string[]): string {
    // 每个方程移项为 f(x,y,z)=0
    const fxs: string[] = [];
    for (const eq of eqs) {
      const idx = eq.indexOf('=');
      if (idx < 0) {
        return `"${eq}" 缺少 =，方程组每个式子都要是方程`;
      }
      fxs.push(`(${eq.substring(0, idx)})−(${eq.substring(idx + 1)})`);
    }
    // 出现的变量集合
    const usedVars: string[] = [];
    for (const v of ['x', 'y', 'z']) {
      let hit = false;
      for (const fx of fxs) {
        if (fx.replace(/lcm|gcd|abs|arcsin|arccos|arctan|asin|acos|atan|ans/gi, '').includes(v)) {
          hit = true;
          break;
        }
      }
      if (hit) {
        usedVars.push(v);
      }
    }
    if (usedVars.length === 0) {
      return '方程组中没有未知数（支持 x y z）';
    }
    if (eqs.length < usedVars.length) {
      return `${usedVars.length} 个未知数（${usedVars.join(' ')}）只有 ${eqs.length} 个方程，欠定`;
    }

    const F = (fx: string, vx: number, vy: number, vz: number): number =>
      this.parser.evalWithVars(fx, vx, vy, vz, this.degMode);

    // 线性探测：f(v)−f(0) 对每个变量是否恒为一次（用 2 点验证）
    const n = usedVars.length;
    const m = fxs.length;
    const varIdx = (v: string): number => v === 'x' ? 0 : (v === 'y' ? 1 : 2);
    let linear = true;
    const A: number[][] = [];
    const B: number[] = [];
    try {
      for (let r = 0; r < m; r++) {
        const c0 = F(fxs[r], 0, 0, 0);
        const row: number[] = [];
        for (let c = 0; c < n; c++) {
          const pt1: number[] = [0, 0, 0];
          const pt2: number[] = [0, 0, 0];
          pt1[varIdx(usedVars[c])] = 1;
          pt2[varIdx(usedVars[c])] = 2;
          const d1 = F(fxs[r], pt1[0], pt1[1], pt1[2]) - c0;
          const d2 = F(fxs[r], pt2[0], pt2[1], pt2[2]) - c0;
          if (Math.abs(d2 - 2 * d1) > 1e-9 * Math.max(1, Math.abs(d2))) {
            linear = false;
          }
          row.push(d1);
        }
        // 交叉项检测：全变量同时取 1 应等于各系数和
        const ptAll: number[] = [0, 0, 0];
        for (const v of usedVars) {
          ptAll[varIdx(v)] = 1;
        }
        let sumRow = c0;
        for (const d of row) {
          sumRow += d;
        }
        if (Math.abs(F(fxs[r], ptAll[0], ptAll[1], ptAll[2]) - sumRow) > 1e-9 * Math.max(1, Math.abs(sumRow))) {
          linear = false;
        }
        A.push(row);
        B.push(-c0);
        if (!linear) {
          break;
        }
      }
    } catch (err) {
      return `方程组无法求值：${(err as Error).message}`;
    }

    if (linear) {
      const r = SuperCalcPage.gauss(A, B, n);
      if (r.kind === 'none') {
        return '线性方程组无解（矛盾方程）';
      }
      if (r.kind === 'inf') {
        return '线性方程组有无穷多解（方程相关）';
      }
      const parts: string[] = [];
      for (let c = 0; c < n; c++) {
        const v = parseFloat(r.sol[c].toPrecision(10));
        const fr = toFraction(v, 9999);
        parts.push(`${usedVars[c]} = ${fmtResult(v)}${fr !== undefined ? `（${fr}）` : ''}`);
      }
      return `线性方程组：\n${parts.join('\n')}`;
    }
    return this.solveNonlinear(fxs, usedVars);
  }

  /** 高斯消元（列主元），返回唯一解/无解/无穷多解 */
  private static gauss(A0: number[][], B0: number[], n: number): LinResult {
    const m = A0.length;
    // 增广矩阵
    const M: number[][] = [];
    for (let r = 0; r < m; r++) {
      M.push([...A0[r], B0[r]]);
    }
    let rank = 0;
    for (let col = 0; col < n && rank < m; col++) {
      let piv = -1;
      let best = 1e-10;
      for (let r = rank; r < m; r++) {
        if (Math.abs(M[r][col]) > best) {
          best = Math.abs(M[r][col]);
          piv = r;
        }
      }
      if (piv < 0) {
        continue;
      }
      const tmp = M[rank];
      M[rank] = M[piv];
      M[piv] = tmp;
      for (let r = 0; r < m; r++) {
        if (r !== rank && Math.abs(M[r][col]) > 1e-14) {
          const k = M[r][col] / M[rank][col];
          for (let c2 = col; c2 <= n; c2++) {
            M[r][c2] -= k * M[rank][c2];
          }
        }
      }
      rank += 1;
    }
    // 矛盾行：0 = 非0
    for (let r = 0; r < m; r++) {
      let allZero = true;
      for (let c = 0; c < n; c++) {
        if (Math.abs(M[r][c]) > 1e-9) {
          allZero = false;
          break;
        }
      }
      if (allZero && Math.abs(M[r][n]) > 1e-9) {
        return { kind: 'none', sol: [] } as LinResult;
      }
    }
    if (rank < n) {
      return { kind: 'inf', sol: [] } as LinResult;
    }
    // 回代（行已消成对角占位形式，逐列找主元行）
    const sol: number[] = new Array<number>(n).fill(0);
    for (let col = 0; col < n; col++) {
      for (let r = 0; r < m; r++) {
        if (Math.abs(M[r][col]) > 1e-10) {
          let isPivot = true;
          for (let c2 = 0; c2 < col; c2++) {
            if (Math.abs(M[r][c2]) > 1e-10) {
              isPivot = false;
              break;
            }
          }
          if (isPivot) {
            sol[col] = M[r][n] / M[r][col];
            break;
          }
        }
      }
    }
    return { kind: 'unique', sol: sol } as LinResult;
  }

  /** 非线性方程组：多起点牛顿法（数值雅可比 + 最小二乘伪逆方向） */
  private solveNonlinear(fxs: string[], usedVars: string[]): string {
    const n = usedVars.length;
    const m = fxs.length;
    const varIdx = (v: string): number => v === 'x' ? 0 : (v === 'y' ? 1 : 2);
    const F = (vals: number[]): number[] => {
      const full: number[] = [0, 0, 0];
      for (let c = 0; c < n; c++) {
        full[varIdx(usedVars[c])] = vals[c];
      }
      const out: number[] = [];
      for (const fx of fxs) {
        out.push(this.parser.evalWithVars(fx, full[0], full[1], full[2], this.degMode));
      }
      return out;
    };
    const starts: number[][] = [];
    const seeds: number[] = [0, 1, -1, 2, -2, 5, -5, 0.5];
    for (const s1 of seeds) {
      if (n === 1) {
        starts.push([s1]);
      } else {
        for (const s2 of seeds) {
          if (n === 2) {
            starts.push([s1, s2]);
          } else {
            starts.push([s1, s2, 1]);
            starts.push([s1, s2, -1]);
          }
        }
      }
    }
    const sols: number[][] = [];
    for (const st of starts) {
      let v = [...st];
      let ok = false;
      for (let iter = 0; iter < 60; iter++) {
        let fv: number[] = [];
        try {
          fv = F(v);
        } catch (err) {
          break;
        }
        let norm = 0;
        for (const y of fv) {
          if (isNaN(y) || !isFinite(y)) {
            norm = NaN;
            break;
          }
          norm += y * y;
        }
        if (isNaN(norm)) {
          break;
        }
        if (norm < 1e-20) {
          ok = true;
          break;
        }
        // 数值雅可比
        const J: number[][] = [];
        let jBad = false;
        for (let r = 0; r < m; r++) {
          J.push(new Array<number>(n).fill(0));
        }
        for (let c = 0; c < n; c++) {
          const h = Math.max(1e-7, Math.abs(v[c]) * 1e-7);
          const vp = [...v];
          vp[c] += h;
          try {
            const fp = F(vp);
            for (let r = 0; r < m; r++) {
              J[r][c] = (fp[r] - fv[r]) / h;
              if (isNaN(J[r][c]) || !isFinite(J[r][c])) {
                jBad = true;
              }
            }
          } catch (err) {
            jBad = true;
          }
          if (jBad) {
            break;
          }
        }
        if (jBad) {
          break;
        }
        // 正规方程 JᵀJ Δ = −Jᵀf（m≥n 时最小二乘）
        const AtA: number[][] = [];
        const Atb: number[] = [];
        for (let c = 0; c < n; c++) {
          AtA.push(new Array<number>(n).fill(0));
          let s2 = 0;
          for (let r = 0; r < m; r++) {
            s2 += J[r][c] * fv[r];
          }
          Atb.push(-s2);
        }
        for (let c1 = 0; c1 < n; c1++) {
          for (let c2 = 0; c2 < n; c2++) {
            let s2 = 0;
            for (let r = 0; r < m; r++) {
              s2 += J[r][c1] * J[r][c2];
            }
            AtA[c1][c2] = s2;
          }
        }
        const step = SuperCalcPage.gauss(AtA, Atb, n);
        if (step.kind !== 'unique') {
          break;
        }
        let moved = 0;
        for (let c = 0; c < n; c++) {
          const d = Math.max(-10, Math.min(10, step.sol[c]));   // 步长限幅
          v[c] += d;
          moved += Math.abs(d);
        }
        if (moved < 1e-13) {
          ok = true;
          break;
        }
      }
      if (ok) {
        // 验残差 + 去重
        let res = 0;
        try {
          for (const y of F(v)) {
            res += y * y;
          }
        } catch (err) {
          continue;
        }
        if (res > 1e-12) {
          continue;
        }
        let dup = false;
        for (const s0 of sols) {
          let d = 0;
          for (let c = 0; c < n; c++) {
            d += Math.abs(s0[c] - v[c]);
          }
          if (d < 1e-5) {
            dup = true;
            break;
          }
        }
        if (!dup) {
          sols.push(v.map((val: number): number => parseFloat((Math.abs(val) < 1e-10 ? 0 : val).toPrecision(8))));
        }
        if (sols.length >= 6) {
          break;
        }
      }
    }
    if (sols.length === 0) {
      return '非线性方程组：多起点迭代未收敛到解\n（可能无实数解，或解在 [-5,5] 初值范围外）';
    }
    const parts: string[] = [];
    for (let si = 0; si < sols.length; si++) {
      const one: string[] = [];
      for (let c = 0; c < n; c++) {
        one.push(`${usedVars[c]} = ${fmtResult(sols[si][c])}`);
      }
      parts.push(sols.length > 1 ? `解${si + 1}：${one.join('，')}` : one.join('\n'));
    }
    return `非线性方程组，${sols.length} 组解：\n${parts.join('\n')}`;
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
    // 模板键 → 插入 □ 占位块，光标落在首个 □（输入即替换）
    if (k === 'log□') {
      this.insertTemplate('log(□,□)');
      return;
    }
    if (k === '□^□') {
      if (this.hasOperandBefore()) {
        this.insertTemplate('^□');
      } else {
        this.insertTemplate('□^□');
      }
      return;
    }
    if (k === '√□') {
      this.insertTemplate('√□');
      return;
    }
    if (k === '□/□') {
      if (this.hasOperandBefore()) {
        this.insertTemplate('÷□');
      } else {
        this.insertTemplate('□÷□');
      }
      return;
    }
    if (k === 'log₂') {
      this.insertTemplate('log2(□)');
      return;
    }
    if (k === 'log₁₀') {
      this.insertTemplate('log(□)');
      return;
    }
    if (k === 'ln') {
      this.insertTemplate('ln(□)');
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
      this.insertTemplate('lcm(□,□)');
      return;
    }
    if (k === '公约') {
      this.insertTemplate('gcd(□,□)');
      return;
    }
    if (k === '|□|') {
      this.insertTemplate('abs(□)');
      return;
    }
    if (k === '□!') {
      if (this.hasOperandBefore()) {
        this.insertTemplate('!');
      } else {
        this.insertTemplate('□!');
      }
      return;
    }
    if (k === 'A□') {
      this.insertTemplate('A(□,□)');
      return;
    }
    if (k === 'C□') {
      this.insertTemplate('C(□,□)');
      return;
    }
    if (k === 'sin' || k === 'cos' || k === 'tan' || k === 'arcsin' || k === 'arccos' || k === 'arctan') {
      this.insertTemplate(`${k}(□)`);
      return;
    }
    if (k === '∫□') {
      this.insertTemplate('∫(□,□,□)');
      return;
    }
    if (k === 'lim') {
      this.insertTemplate('lim(□,□)');
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
    // a-z 区块的字母键（e/i 在基础区块作常量，保持符号色）
    return k === 'a' || k === 'b' || k === 'c' || k === 'h' || k === 'k' || k === 'p';
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

  /** 按键图标里的参数输入块 */
  @Builder
  pbox(w: number, h: number) {
    Text('')
      .width(w)
      .height(h)
      .borderRadius(2)
      .backgroundColor('#4D8A8F9C')
  }

  /** 按键面：多参数公式键在对应位置绘制输入块（上标右上、积分上下限等） */
  @Builder
  keyFace(k: string) {
    if (k === 'log□') {
      // log_□(□)：底数块右下，真数块随后
      Row() {
        Text('log').fontSize(14).fontColor('#7B88FF')
        this.pbox(7, 7)
        Row() {
          this.pbox(10, 12)
        }.margin({ left: 3 })
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '□^□') {
      // □ 的右上角小块（指数位）
      Row() {
        this.pbox(12, 13)
        Row() {
          this.pbox(7, 8)
        }.margin({ left: 2 }).offset({ x: 0, y: -7 })
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '√□') {
      Row() {
        Text('√').fontSize(19).fontColor('#7B88FF')
        this.pbox(10, 11)
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '□/□') {
      // 分数：上块 / 分数线 / 下块
      Column({ space: 2 }) {
        this.pbox(9, 8)
        Text('').width(16).height(1.2).backgroundColor('#7B88FF')
        this.pbox(9, 8)
      }
      .alignItems(HorizontalAlign.Center)
    } else if (k === '|□|') {
      Row({ space: 2 }) {
        Text('|').fontSize(16).fontColor('#7B88FF')
        this.pbox(9, 10)
        Text('|').fontSize(16).fontColor('#7B88FF')
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '□!') {
      Row({ space: 2 }) {
        this.pbox(10, 11)
        Text('!').fontSize(17).fontColor('#7B88FF')
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '∫□') {
      // 积分：上限块右上、下限块右下
      Row() {
        Text('∫').fontSize(22).fontColor('#7B88FF')
        Column({ space: 9 }) {
          this.pbox(7, 7)
          this.pbox(7, 7)
        }.margin({ left: 2 })
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === 'lim') {
      // 极限：lim 下方 □→□
      Column({ space: 1 }) {
        Text('lim').fontSize(12).fontColor('#7B88FF')
        Row({ space: 1 }) {
          this.pbox(6, 6)
          Text('→').fontSize(9).fontColor('#7B88FF')
          this.pbox(6, 6)
        }
        .alignItems(VerticalAlign.Center)
      }
      .alignItems(HorizontalAlign.Center)
    } else if (k === 'A□' || k === 'C□') {
      // 排列组合：上标块右上、下标块右下
      Row() {
        Text(k.substring(0, 1)).fontSize(17).fontColor('#7B88FF')
        Column({ space: 6 }) {
          this.pbox(7, 7)
          this.pbox(7, 7)
        }.margin({ left: 2 })
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === 'log₂' || k === 'log₁₀' || k === 'ln') {
      Row({ space: 2 }) {
        Text(k).fontSize(k === 'log₁₀' ? 11 : 13).fontColor('#7B88FF')
        this.pbox(9, 10)
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '°') {
      Row({ space: 1 }) {
        this.pbox(8, 9)
        Text('°').fontSize(16).fontColor('#7B88FF')
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '′″') {
      Row({ space: 1 }) {
        this.pbox(7, 8)
        Text('′').fontSize(13).fontColor('#7B88FF')
        this.pbox(7, 8)
        Text('″').fontSize(13).fontColor('#7B88FF')
      }
      .alignItems(VerticalAlign.Center)
    } else {
      Text(this.keyLabel(k))
        .fontSize(k.length > 2 ? 12 : 18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.keyFg(k))
    }
  }

  /** 键盘按键行（连续面板内各区块共用） */
  @Builder
  keyRows(layout: string[][], tag: string) {
    ForEach(layout, (row: string[]) => {
      Row({ space: 6 }) {
        ForEach(row, (k: string) => {
          Row() {
            this.keyFace(k)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .layoutWeight(1)
          .height(52)
          .borderRadius(12)
          .backgroundColor(k.length === 0 ? Color.Transparent : this.keyBg(k))
          .onClick(() => this.onKey(k))
        }, (k: string, j: number) => `${k}-${j}`)
      }
      .width('100%')
    }, (row: string[], i: number) => `${tag}r${i}`)
  }

  /** 侧边栏锚点按钮（f(x) 按截图用橙色高亮），点击滚动到对应区块 */
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
        this.kbScroller.scrollTo({
          xOffset: 0,
          yOffset: this.secOffsets[idx],
          animation: { duration: 260, curve: Curve.EaseOut }
        });
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

            // 表达式：数学式富渲染（上下标、参数块在公式对应位置），点击定位光标
            Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap,
              justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
              if (this.expression.length === 0) {
                Text('输入算式或方程…')
                  .fontSize(16)
                  .fontColor($r('app.color.text_secondary'))
                this.cursorBar(26, $r('app.color.accent'), 0)
              } else {
                ForEach(this.buildRender(), (it: RItem, idx: number) => {
                  if (it.cb) {
                    // 光标高度对齐所在层级：正常位同主字号，上下标位同小块
                    this.cursorBar(it.level === 0 ? 26 : 16, $r('app.color.accent'),
                      it.level === 1 ? -8 : (it.level === 2 ? 8 : 0))
                  }
                  if (it.box) {
                    // 参数输入块：选中态深橙+等高闪烁光标
                    Row() {
                      if (it.sel) {
                        this.cursorBar(it.level === 0 ? 20 : 11, '#FF9F43', 0)
                      }
                    }
                    .justifyContent(FlexAlign.Center)
                    .width(it.level === 0 ? 22 : 14)
                    .height(it.level === 0 ? 26 : 16)
                    .borderRadius(4)
                    .backgroundColor(it.sel ? '#66FF9F43' : '#2EFF9F43')
                    .border({ width: 1, color: it.sel ? '#FF9F43' : '#66FF9F43' })
                    .margin({ left: 1, right: 1 })
                    .offset({ x: 0, y: it.level === 1 ? -8 : (it.level === 2 ? 8 : 0) })
                    .onClick(() => {
                      this.lastSpanTap = Date.now();
                      this.cursor = it.start;
                    })
                  } else if (it.s.length > 0) {
                    Text(it.s)
                      .fontSize(it.level === 0 ? 24 : 14)
                      .fontColor($r('app.color.text_primary'))
                      .offset({ x: 0, y: it.level === 1 ? -8 : (it.level === 2 ? 8 : 0) })
                      .onClick(() => {
                        this.lastSpanTap = Date.now();
                        this.cursor = it.end;
                      })
                  }
                }, (it: RItem, idx: number) => `${idx}-${it.s}-${it.box}-${it.level}-${it.cb}-${it.sel}`)
              }
            }
            .width('100%')
            .onClick(() => {
              // 点击空白处：光标移到末尾（元素点击 100ms 内不抢占）
              if (Date.now() - this.lastSpanTap > 100) {
                this.cursor = this.expression.length;
              }
            })

            if (this.result.length > 0) {
              Text(`${this.result}${this.fracForm.length > 0 ? `  =  ${this.fracForm}` : ''}`)
                .fontSize(this.result.includes('\n') ? 15 : 24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.accent'))
                .lineHeight(this.result.includes('\n') ? 24 : 30)
                .maxLines(8)
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

          // ══ 侧边栏锚点（+−×÷ / f / a-z / f(x)）+ 连续滚动面板 ══
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

            // 右侧整体一个面板，四个区块连贯滚动，侧栏是锚点
            Scroll(this.kbScroller) {
              Column({ space: 6 }) {
                // ── 区块0：基础运算 ──
                Column({ space: 6 }) {
                  this.keyRows(BASIC_KEYS, 'basic')
                }
                .width('100%')
                .onAreaChange((_o: Area, n: Area) => {
                  this.secOffsets[0] = n.position.y as number;
                })

                // ── 区块1：函数 ──
                Column({ space: 6 }) {
                  this.keyRows(FUNC_KEYS, 'func')
                }
                .width('100%')
                .onAreaChange((_o: Area, n: Area) => {
                  this.secOffsets[1] = n.position.y as number;
                })

                // ── 区块2：字母 + 常用函数模板 ──
                Column({ space: 6 }) {
                  this.keyRows(AZ_KEYS, 'az')
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
                .width('100%')
                .onAreaChange((_o: Area, n: Area) => {
                  this.secOffsets[2] = n.position.y as number;
                })

                // ── 区块3：f(x) 公式模板（左分类跨行 右公式列表）──
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
                .borderRadius(12)
                .backgroundColor($r('app.color.bg_card'))
                .onAreaChange((_o: Area, n: Area) => {
                  this.secOffsets[3] = n.position.y as number;
                })
              }
              .width('100%')
            }
            .layoutWeight(1)
            .height('100%')
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .onDidScroll(() => {
              // 滚动时反向高亮当前区块锚点
              const y = this.kbScroller.currentOffset().yOffset + 10;
              let cur = 0;
              for (let i = 3; i >= 0; i--) {
                if (y >= this.secOffsets[i]) {
                  cur = i;
                  break;
                }
              }
              if (cur !== this.panel) {
                this.panel = cur;
              }
            })
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
