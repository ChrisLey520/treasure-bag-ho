/**
 * 超级计算器共享核心：光标编辑模型 + 回显区数学式富渲染扫描器。
 * SuperCalcPage（App 内）与 SuperCalcCard（服务卡片）共用，保证两端行为一致。
 */

/** 回显区渲染元素：带原字符串索引，支持上/下标层级与参数块 */
export interface RItem {
  s: string;        // 显示文本（参数块为空串）
  box: boolean;     // 是否参数输入块
  level: number;    // 0 正常 1 上标 2 下标
  start: number;    // 在表达式串中的起始索引
  end: number;      // 结束索引（不含）
  cb: boolean;      // 光标画在该元素之前
  sel: boolean;     // 参数块处于选中态（光标落在块上）
}

/** 编辑操作结果：新表达式 + 新光标位 */
export interface EditState {
  expr: string;
  cursor: number;
}

/** 回显区按整体渲染的函数名（长名优先匹配） */
export const RENDER_FNS: string[] = ['arcsin', 'arccos', 'arctan', 'log10', 'log2',
  'lcm', 'gcd', 'abs', 'sin', 'cos', 'tan', 'ANS', 'lim', 'log', 'ln'];

/** 退格/光标移动按整体处理的函数名（长名优先） */
export const EDIT_FNS: string[] = ['arcsin', 'arccos', 'arctan', 'asin', 'acos', 'atan',
  'log2', 'lcm(', 'gcd(', 'abs(', 'lim(', 'sin', 'cos', 'tan', 'abs', 'ln', 'log', 'ANS', 'A(', 'C(', '∫('];

/** 光标位插入文本；光标停在 □ 上则替换该块 */
export function insertTextAt(expr: string, cursor: number, s: string): EditState {
  let after = expr.substring(cursor);
  if (after.startsWith('□')) {
    after = after.substring(1);
  }
  return { expr: expr.substring(0, cursor) + s + after, cursor: cursor + s.length } as EditState;
}

/** 插入含 □ 占位块的模板，光标落在第一个 □ 上 */
export function insertTemplateAt(expr: string, cursor: number, s: string): EditState {
  let after = expr.substring(cursor);
  if (after.startsWith('□')) {
    after = after.substring(1);
  }
  const boxIdx = s.indexOf('□');
  return {
    expr: expr.substring(0, cursor) + s + after,
    cursor: boxIdx >= 0 ? cursor + boxIdx : cursor + s.length
  } as EditState;
}

/** 光标位退格；函数名整体删除 */
export function backspaceAt(expr: string, cursor: number): EditState {
  if (cursor === 0) {
    return { expr: expr, cursor: cursor } as EditState;
  }
  const before = expr.substring(0, cursor);
  let cut = 1;
  for (const fn of EDIT_FNS) {
    if (before.endsWith(fn)) {
      cut = fn.length;
      break;
    }
  }
  return {
    expr: before.substring(0, before.length - cut) + expr.substring(cursor),
    cursor: cursor - cut
  } as EditState;
}

/** 光标左右移动；跨函数名整体跳过 */
export function moveCursorBy(expr: string, cursor: number, delta: number): number {
  let target = cursor + delta;
  if (delta < 0) {
    const before = expr.substring(0, cursor);
    for (const fn of EDIT_FNS) {
      if (before.endsWith(fn)) {
        target = cursor - fn.length;
        break;
      }
    }
  } else {
    const after = expr.substring(cursor);
    for (const fn of EDIT_FNS) {
      if (after.startsWith(fn)) {
        target = cursor + fn.length;
        break;
      }
    }
  }
  return Math.max(0, Math.min(expr.length, target));
}

/** 光标前是否已有可作为左操作数的内容（决定 ^ ! ÷ 是否补前置占位块） */
export function hasOperandBeforeAt(expr: string, cursor: number): boolean {
  if (cursor === 0) {
    return false;
  }
  const ch = expr[cursor - 1];
  return (ch >= '0' && ch <= '9') || ch === ')' || ch === 'x' || ch === 'y' || ch === 'z' ||
    ch === 'π' || ch === 'e' || ch === 'i' || ch === '!' || ch === '%' || ch === '□' ||
    ch === '°' || ch === '′' || ch === '″' || ch === '.';
}

/**
 * 回显区数学式富渲染：把表达式扫描为带原串索引的元素序列。
 * log(b,x)→log 下标 b (x)、A/C(n,r)→下标 n 上标 r、^→上标、
 * abs(x)→|x|、log2/log10→log 下标底数、∫ 上下限、lim 趋近点；□ 为参数输入块。
 * 光标标注三级判定：块选中 → 继承左侧上/下标层级 → 其后元素之前。
 */
export function buildRenderItems(s: string, cursor: number): RItem[] {
  const items: RItem[] = [];
  const modeStack: string[] = [];   // 与括号深度同步：''/logbase/logarg/abs/sup/An/Ar/intLo/intHi/intBody/limPt/limBody
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

  // 光标标注：
  // 1) 落在参数块上 → 块选中
  // 2) 贴在左侧元素之后并继承其上下标层级（参数位连续输入时光标留在参数区内）
  // 3) 否则画在其后元素之前；末尾兜底
  let done = false;
  for (let k = 0; k < items.length; k++) {
    const it = items[k];
    if (it.box && cursor === it.start) {
      it.sel = true;
      done = true;
      break;
    }
  }
  if (!done) {
    for (let k = items.length - 1; k >= 0; k--) {
      const it = items[k];
      if (!it.box && it.s.length > 0 && it.end === cursor && it.level !== 0) {
        items.splice(k + 1, 0, {
          s: '', box: false, level: it.level,
          start: cursor, end: cursor, cb: true, sel: false
        } as RItem);
        done = true;
        break;
      }
    }
  }
  if (!done) {
    for (let k = 0; k < items.length; k++) {
      const it = items[k];
      if (cursor <= it.start) {
        it.cb = true;
        done = true;
        break;
      }
    }
  }
  if (!done) {
    items.push({ s: '', box: false, level: 0, start: s.length, end: s.length, cb: true, sel: false } as RItem);
  }
  return items;
}
