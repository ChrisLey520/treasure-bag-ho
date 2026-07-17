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
      } else if (ch === '(' || ch === 'π' || ch === 'e' || this.isFuncStart(ch) || ch === '√' || ch === 'A' || ch === 'C' || ch === '∫') {
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
    if (ch === '∞') {
      this.pos += 1;
      return Infinity;
    }
    // 定积分 ∫(下限,上限,f(x))：数值 Simpson 法
    if (ch === '∫') {
      this.pos += 1;
      if (this.peek() !== '(') {
        throw new Error('∫ 需要 (下限,上限,函数) 形式');
      }
      this.pos += 1;
      const a = this.parseExpr();
      if (this.peek() !== ',' && this.peek() !== '，') {
        throw new Error('∫ 参数用逗号分隔');
      }
      this.pos += 1;
      const b = this.parseExpr();
      if (this.peek() !== ',' && this.peek() !== '，') {
        throw new Error('∫ 需要三个参数：∫(下限,上限,函数)');
      }
      this.pos += 1;
      const body = this.captureBalanced();
      if (this.peek() !== ')') {
        throw new Error('缺少右括号');
      }
      this.pos += 1;
      if (body.trim().length === 0) {
        throw new Error('被积函数为空');
      }
      return SciParser.integrate(a, b, body, this.degMode);
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
      // 极限 lim(趋近点,f(x))：数值双侧逼近，趋近点可为 ±∞
      if (this.src.startsWith('lim', this.pos)) {
        this.pos += 3;
        if (this.peek() !== '(') {
          throw new Error('lim 需要 (趋近点,函数) 形式');
        }
        this.pos += 1;
        const a = this.parseExpr();
        if (this.peek() !== ',' && this.peek() !== '，') {
          throw new Error('lim 参数用逗号分隔');
        }
        this.pos += 1;
        const body = this.captureBalanced();
        if (this.peek() !== ')') {
          throw new Error('缺少右括号');
        }
        this.pos += 1;
        if (body.trim().length === 0) {
          throw new Error('极限函数为空');
        }
        return SciParser.limitOf(a, body, this.degMode);
      }
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

  /** 从当前位置截取到匹配右括号前的原始子串（不消费右括号），用于 ∫/lim 的函数体 */
  private captureBalanced(): string {
    let depth = 0;
    const start = this.pos;
    let i = this.pos;
    while (i < this.src.length) {
      const c = this.src[i];
      if (c === '(') {
        depth += 1;
      } else if (c === ')') {
        if (depth === 0) {
          break;
        }
        depth -= 1;
      }
      i += 1;
    }
    this.pos = i;
    return this.src.substring(start, i);
  }

  /** 定积分：自适应 Simpson 复合公式，2000 段 */
  private static integrate(a: number, b: number, body: string, degMode: boolean): number {
    if (!isFinite(a) || !isFinite(b)) {
      throw new Error('∫ 上下限须为有限数');
    }
    if (a === b) {
      return 0;
    }
    const p = new SciParser();
    const f = (x: number): number => p.evalWithX(body, x, degMode);
    const N = 2000;   // 偶数段
    const h = (b - a) / N;
    let sum = 0;
    let bad = 0;
    for (let i = 0; i <= N; i++) {
      const x = a + h * i;
      let y = NaN;
      try {
        y = f(x);
      } catch (err) {
        y = NaN;
      }
      if (isNaN(y) || !isFinite(y)) {
        // 端点/奇点容错：内缩半步取值
        try {
          y = f(x + (i === 0 ? h : -h) * 1e-6);
        } catch (err) {
          y = NaN;
        }
        if (isNaN(y) || !isFinite(y)) {
          bad += 1;
          y = 0;
        }
      }
      sum += y * (i === 0 || i === N ? 1 : (i % 2 === 1 ? 4 : 2));
    }
    if (bad > N / 10) {
      throw new Error('被积函数在区间内大量无定义');
    }
    return sum * h / 3;
  }

  /** 极限：趋近点双侧递缩逼近（±∞ 时取递增大值），检测收敛与左右一致 */
  private static limitOf(a: number, body: string, degMode: boolean): number {
    const p = new SciParser();
    const f = (x: number): number => {
      try {
        return p.evalWithX(body, x, degMode);
      } catch (err) {
        return NaN;
      }
    };
    const seqAt = (xs: number[]): number => {
      const vs: number[] = [];
      for (const x of xs) {
        const v = f(x);
        if (!isNaN(v) && isFinite(v)) {
          vs.push(v);
        }
      }
      if (vs.length < 2) {
        return NaN;
      }
      const last = vs[vs.length - 1];
      const prev = vs[vs.length - 2];
      const tol = 1e-6 * Math.max(1, Math.abs(last));
      if (Math.abs(last - prev) < tol) {
        return last;
      }
      // 发散判定：单调放大
      if (Math.abs(last) > 1e10 && Math.abs(last) > Math.abs(prev) * 1.5) {
        return last > 0 ? Infinity : -Infinity;
      }
      return NaN;
    };
    if (!isFinite(a)) {
      const sign = a > 0 ? 1 : -1;
      const xs: number[] = [];
      for (let k = 2; k <= 8; k++) {
        xs.push(sign * Math.pow(10, k));
      }
      const v = seqAt(xs);
      if (isNaN(v)) {
        throw new Error('极限不存在或不收敛');
      }
      return v;
    }
    const right: number[] = [];
    const left: number[] = [];
    for (let k = 2; k <= 9; k++) {
      const d = Math.pow(10, -k);
      right.push(a + d);
      left.push(a - d);
    }
    const vr = seqAt(right);
    const vl = seqAt(left);
    if (isNaN(vr) && isNaN(vl)) {
      throw new Error('极限不存在或不收敛');
    }
    if (isNaN(vr)) {
      return vl;
    }
    if (isNaN(vl)) {
      return vr;
    }
    if (!isFinite(vr) || !isFinite(vl)) {
      if (vr === vl) {
        return vr;
      }
      throw new Error('左右极限不一致（左 ' + (vl > 0 ? '+∞' : vl < 0 ? '−∞' : String(vl)) +
        '，右 ' + (vr > 0 ? '+∞' : vr < 0 ? '−∞' : String(vr)) + '）');
    }
    const tol = 1e-5 * Math.max(1, Math.abs(vr), Math.abs(vl));
    if (Math.abs(vr - vl) > tol) {
      throw new Error(`左右极限不一致（左 ${vl.toPrecision(6)}，右 ${vr.toPrecision(6)}）`);
    }
    const v = (vr + vl) / 2;
    // 修约到 8 位有效数字，抹去数值逼近尾差
    return parseFloat(v.toPrecision(8));
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

  /** 数值 → 可解析字面量（避免 1e-7 这类科学计数法字符串进解析器） */
  private static numLit(v: number): string {
    if (Math.abs(v) < 1e-12) {
      return '(0)';
    }
    const abs = Math.abs(v);
    let body = '';
    if (abs >= 1e-12 && abs < 1e15) {
      body = abs.toFixed(12).replace(/0+$/, '').replace(/\.$/, '');
    } else {
      body = abs.toFixed(0);
    }
    return v < 0 ? `(−${body})` : `(${body})`;
  }

  /** 解析含变量 x 的表达式（绘图/求根用）：把 x 替换为数值后复用 parse */
  evalWithX(expr: string, x: number, degMode: boolean): number {
    const substituted = expr.replace(/x/g, SciParser.numLit(x));
    return this.parse(substituted, degMode, 0);
  }

  /** 多变量代入求值（方程组用）：x/y/z 全部替换 */
  evalWithVars(expr: string, vx: number, vy: number, vz: number, degMode: boolean): number {
    const substituted = expr
      .replace(/x/g, SciParser.numLit(vx))
      .replace(/y/g, SciParser.numLit(vy))
      .replace(/z/g, SciParser.numLit(vz));
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
