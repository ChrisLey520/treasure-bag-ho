/**
 * 科学表达式解析器：递归下降，支持
 * + − × ÷ ^ % ! 括号、sin/cos/tan/asin/acos/atan/ln/log/√、π/e/ANS、隐式乘法
 */
export class SciParser {
  private src: string = '';
  private pos: number = 0;
  private degMode: boolean = true;
  private ansValue: number = 0;

  parse(expr: string, degMode: boolean, ans: number): number {
    this.src = expr;
    this.pos = 0;
    this.degMode = degMode;
    this.ansValue = ans;
    const v = this.parseExpr();
    this.skipSpace();
    if (this.pos < this.src.length) {
      throw new Error(`无法解析 "${this.src.substring(this.pos)}"`);
    }
    return v;
  }

  private skipSpace(): void {
    while (this.pos < this.src.length && this.src[this.pos] === ' ') {
      this.pos += 1;
    }
  }

  private peek(): string {
    this.skipSpace();
    return this.pos < this.src.length ? this.src[this.pos] : '';
  }

  /** 加减 */
  private parseExpr(): number {
    let v = this.parseTerm();
    while (true) {
      const ch = this.peek();
      if (ch === '+') {
        this.pos += 1;
        v += this.parseTerm();
      } else if (ch === '−' || ch === '-') {
        this.pos += 1;
        v -= this.parseTerm();
      } else {
        return v;
      }
    }
  }

  /** 乘除（含隐式乘法：2π、3(4+1)、2sin30） */
  private parseTerm(): number {
    let v = this.parseUnary();
    while (true) {
      const ch = this.peek();
      if (ch === '×' || ch === '*') {
        this.pos += 1;
        v *= this.parseUnary();
      } else if (ch === '÷' || ch === '/') {
        this.pos += 1;
        const d = this.parseUnary();
        if (d === 0) {
          throw new Error('除数不能为 0');
        }
        v /= d;
      } else if (ch === '(' || ch === 'π' || ch === 'e' || this.isFuncStart(ch) || ch === '√' || ch === 'A' || ch === 'C') {
        // 隐式乘法
        v *= this.parseUnary();
      } else {
        return v;
      }
    }
  }

  /** 一元负号 */
  private parseUnary(): number {
    const ch = this.peek();
    if (ch === '−' || ch === '-') {
      this.pos += 1;
      return -this.parseUnary();
    }
    return this.parsePostfix();
  }

  /** 后缀：^ 幂（右结合）、! 阶乘、% 百分数 */
  private parsePostfix(): number {
    let v = this.parseAtom();
    while (true) {
      const ch = this.peek();
      if (ch === '^') {
        this.pos += 1;
        v = Math.pow(v, this.parseUnary());   // 右结合：2^3^2 = 2^(3^2)
      } else if (ch === '!') {
        this.pos += 1;
        v = SciParser.factorial(v);
      } else if (ch === '%') {
        this.pos += 1;
        v /= 100;
      } else if (ch === '°') {
        this.pos += 1;
        v = this.degMode ? v : v * Math.PI / 180;
      } else if (ch === '′') {
        this.pos += 1;
        const deg = v / 60;
        v = this.degMode ? deg : deg * Math.PI / 180;
      } else if (ch === '″') {
        this.pos += 1;
        const deg = v / 3600;
        v = this.degMode ? deg : deg * Math.PI / 180;
      } else {
        return v;
      }
    }
  }

  private isFuncStart(ch: string): boolean {
    return ch >= 'a' && ch <= 'z' && ch !== 'e';
  }

  /** 原子：数字、常量、括号、函数、√ */
  private parseAtom(): number {
    this.skipSpace();
    const ch = this.peek();

    if (ch === '(') {
      this.pos += 1;
      const v = this.parseExpr();
      if (this.peek() !== ')') {
        throw new Error('缺少右括号');
      }
      this.pos += 1;
      return v;
    }
    if (ch === 'π') {
      this.pos += 1;
      return Math.PI;
    }
    if (ch === 'e') {
      this.pos += 1;
      return Math.E;
    }
    if (ch === '√') {
      this.pos += 1;
      const v = this.parseUnary();
      if (v < 0) {
        throw new Error('负数不能开平方');
      }
      return Math.sqrt(v);
    }
    // ANS（上次结果，大小写均可，须在 A(n,r) 之前判断）
    if (this.src.startsWith('ANS', this.pos) || this.src.startsWith('ans', this.pos)) {
      this.pos += 3;
      return this.ansValue;
    }
    // 排列 A(n,r) / 组合 C(n,r)
    if (ch === 'A' || ch === 'C') {
      const isPerm = ch === 'A';
      this.pos += 1;
      const args = this.parseTwoArgs(isPerm ? 'A(n,r)' : 'C(n,r)');
      return isPerm ? SciParser.perm(args[0], args[1]) : SciParser.comb(args[0], args[1]);
    }
    // 函数名
    if (this.isFuncStart(ch)) {
      // 双参数函数：公倍 lcm(a,b) / 公约 gcd(a,b)
      const twoArg: string[] = ['lcm', 'gcd'];
      for (const fn of twoArg) {
        if (this.src.startsWith(fn, this.pos)) {
          this.pos += fn.length;
          const args = this.parseTwoArgs(`${fn}(a,b)`);
          return fn === 'lcm' ? SciParser.lcmInt(args[0], args[1]) : SciParser.gcdInt(args[0], args[1]);
        }
      }
      const fns: string[] = ['arcsin', 'arccos', 'arctan', 'asin', 'acos', 'atan',
        'log10', 'log2', 'sin', 'cos', 'tan', 'ln', 'log', 'abs'];
      for (const fn of fns) {
        if (this.src.startsWith(fn, this.pos)) {
          this.pos += fn.length;
          // log(底,真数) 双参数形式
          if (fn === 'log') {
            this.skipSpace();
            if (this.peek() === '(') {
              const save = this.pos;
              try {
                const args = this.parseTwoArgs('log(底,真数)');
                if (args[0] <= 0 || args[0] === 1) {
                  throw new Error('对数底数需 >0 且 ≠1');
                }
                if (args[1] <= 0) {
                  throw new Error('真数需 >0');
                }
                return Math.log(args[1]) / Math.log(args[0]);
              } catch (err) {
                const msg = (err as Error).message;
                if (msg.includes('底数') || msg.includes('真数')) {
                  throw new Error(msg);
                }
                this.pos = save;   // 非双参形式，回退按单参 log 解析
              }
            }
          }
          const arg = this.parseUnary();
          let name = fn;
          if (fn === 'arcsin') { name = 'asin'; }
          else if (fn === 'arccos') { name = 'acos'; }
          else if (fn === 'arctan') { name = 'atan'; }
          else if (fn === 'log10') { name = 'log'; }
          return this.applyFunc(name, arg);
        }
      }
      throw new Error(`未知函数 "${this.src.substring(this.pos, this.pos + 4)}"`);
    }
    // 数字
    let num = '';
    this.skipSpace();
    while (this.pos < this.src.length) {
      const c = this.src[this.pos];
      if ((c >= '0' && c <= '9') || c === '.') {
        num += c;
        this.pos += 1;
      } else {
        break;
      }
    }
    if (num.length === 0) {
      throw new Error('表达式不完整');
    }
    const v = parseFloat(num);
    if (isNaN(v)) {
      throw new Error(`无效数字 "${num}"`);
    }
    return v;
  }

  private applyFunc(fn: string, x: number): number {
    const toRad = (d: number): number => this.degMode ? d * Math.PI / 180 : d;
    const toDeg = (r: number): number => this.degMode ? r * 180 / Math.PI : r;
    if (fn === 'sin') { return Math.sin(toRad(x)); }
    if (fn === 'cos') { return Math.cos(toRad(x)); }
    if (fn === 'tan') {
      const r = toRad(x);
      if (Math.abs(Math.cos(r)) < 1e-12) {
        throw new Error('tan 无定义');
      }
      return Math.tan(r);
    }
    if (fn === 'asin') {
      if (x < -1 || x > 1) { throw new Error('asin 定义域 [-1,1]'); }
      return toDeg(Math.asin(x));
    }
    if (fn === 'acos') {
      if (x < -1 || x > 1) { throw new Error('acos 定义域 [-1,1]'); }
      return toDeg(Math.acos(x));
    }
    if (fn === 'atan') { return toDeg(Math.atan(x)); }
    if (fn === 'ln') {
      if (x <= 0) { throw new Error('ln 定义域 (0,+∞)'); }
      return Math.log(x);
    }
    if (fn === 'log') {
      if (x <= 0) { throw new Error('log 定义域 (0,+∞)'); }
      return Math.log10(x);
    }
    if (fn === 'log2') {
      if (x <= 0) { throw new Error('log₂ 定义域 (0,+∞)'); }
      return Math.log2(x);
    }
    if (fn === 'abs') { return Math.abs(x); }
    throw new Error(`未知函数 ${fn}`);
  }

  /** 解析 (a,b) 双参数 */
  private parseTwoArgs(sig: string): number[] {
    if (this.peek() !== '(') {
      throw new Error(`${sig} 需要括号参数`);
    }
    this.pos += 1;
    const a = this.parseExpr();
    const sep = this.peek();
    if (sep !== ',' && sep !== '，') {
      throw new Error(`${sig} 参数用逗号分隔`);
    }
    this.pos += 1;
    const b = this.parseExpr();
    if (this.peek() !== ')') {
      throw new Error('缺少右括号');
    }
    this.pos += 1;
    return [a, b];
  }

  private static gcdInt(a: number, b: number): number {
    if (Math.floor(a) !== a || Math.floor(b) !== b || a <= 0 || b <= 0) {
      throw new Error('公约数需正整数');
    }
    let x = a;
    let y = b;
    while (y > 0) {
      const t = x % y;
      x = y;
      y = t;
    }
    return x;
  }

  private static lcmInt(a: number, b: number): number {
    return a / SciParser.gcdInt(a, b) * b;
  }

  private static perm(n: number, r: number): number {
    if (Math.floor(n) !== n || Math.floor(r) !== r || n < 0 || r < 0 || r > n) {
      throw new Error('A(n,r) 需 0≤r≤n 整数');
    }
    let v = 1;
    for (let i = n - r + 1; i <= n; i++) {
      v *= i;
    }
    return v;
  }

  private static comb(n: number, r: number): number {
    return SciParser.perm(n, r) / SciParser.factorial(r);
  }

  private static factorial(n: number): number {
    if (n < 0 || Math.floor(n) !== n) {
      throw new Error('阶乘仅支持非负整数');
    }
    if (n > 170) {
      throw new Error('阶乘溢出（≤170）');
    }
    let r = 1;
    for (let i = 2; i <= n; i++) {
      r *= i;
    }
    return r;
  }

  /** 解析含变量 x 的表达式（绘图/求根用）：把 x 替换为数值后复用 parse */
  evalWithX(expr: string, x: number, degMode: boolean): number {
    // 用括号包裹避免负数破坏语法
    const substituted = expr.replace(/x/g, `(${x < 0 ? '−' + Math.abs(x) : x.toString()})`);
    return this.parse(substituted, degMode, 0);
  }
}

/** 清理用户输入的函数表达式：容错 y= / f(x)= / X 大写等写法 */
export function normalizeFx(input: string): string {
  let s = input.trim();
  // 去掉 y= / f(x)= / Y= / F(x)= 前缀
  const eq = s.indexOf('=');
  if (eq >= 0) {
    const lhs = s.substring(0, eq).replace(/\s/g, '').toLowerCase();
    if (lhs === 'y' || lhs === 'f(x)' || lhs === 'fx' || lhs === 'f') {
      s = s.substring(eq + 1);
    }
  }
  return s.replace(/X/g, 'x').trim();
}

/**
 * 方程输入 → f(x) 标准形式：
 * 含 = 则移项为 lhs−(rhs)；y=/f(x)= 前缀视为 rhs 即 f(x)
 */
export function equationToFx(input: string): string {
  let s = input.trim().replace(/X/g, 'x');
  const eq = s.indexOf('=');
  if (eq < 0) {
    return s;   // 无 = ：视为 f(x) = 0
  }
  const lhs = s.substring(0, eq).trim();
  const rhs = s.substring(eq + 1).trim();
  const lhsKey = lhs.replace(/\s/g, '').toLowerCase();
  if (lhsKey === 'y' || lhsKey === 'f(x)' || lhsKey === 'fx' || lhsKey === 'f') {
    return rhs;  // y = … 形式：求 rhs = 0 的根
  }
  if (rhs.length === 0 || rhs === '0') {
    return lhs;
  }
  return `(${lhs})−(${rhs})`;   // 通用移项
}

/** 小数 → 最简分数（连分数展开）。误差 > tol 或分母超限返回 undefined */
export function toFraction(v: number, maxDen: number): string | undefined {
  if (isNaN(v) || !isFinite(v)) {
    return undefined;
  }
  if (Math.floor(v) === v) {
    return undefined;   // 整数无须分数形式
  }
  const x = Math.abs(v);
  let n0 = 0;
  let d0 = 1;
  let n1 = 1;
  let d1 = 0;
  let val = x;
  for (let i = 0; i < 40; i++) {
    const a = Math.floor(val);
    const n2 = a * n1 + n0;
    const d2 = a * d1 + d0;
    if (d2 > maxDen) {
      return undefined;   // 分母超限：不是"好看"的分数
    }
    n0 = n1;
    d0 = d1;
    n1 = n2;
    d1 = d2;
    const frac = val - a;
    if (frac < 1e-12 || Math.abs(n1 / d1 - x) < 1e-12 * Math.max(1, x)) {
      break;
    }
    val = 1 / frac;
  }
  if (d1 <= 1) {
    return undefined;
  }
  // 验证精度（避免把无理数硬凑成分数）
  if (Math.abs(n1 / d1 - x) > 1e-10 * Math.max(1, x)) {
    return undefined;
  }
  return `${v < 0 ? '−' : ''}${n1}/${d1}`;
}

/** 结果格式化：12 位精度修约，超范围转科学计数法 */
export function fmtResult(v: number): string {
  if (isNaN(v)) {
    return '错误';
  }
  if (!isFinite(v)) {
    return v > 0 ? '∞' : '-∞';
  }
  if (v !== 0 && (Math.abs(v) >= 1e12 || Math.abs(v) < 1e-9)) {
    return v.toExponential(6).replace('e+', '×10^').replace('e-', '×10^-');
  }
  return parseFloat(v.toPrecision(12)).toString();
}
