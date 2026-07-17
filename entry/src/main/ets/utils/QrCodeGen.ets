/**
 * QR 码编码器（纯本地实现，不依赖 ScanKit 系统服务）。
 * 算法移植自 Project Nayuki qr-code-generator（MIT License）
 * https://www.nayuki.io/page/qr-code-generator-library
 * 适配 ArkTS：去 namespace/嵌套类/元组，仅保留 Byte 模式（任意 UTF-8 文本均可编码）。
 */

/** 纠错级别（ordinal 用于容量表索引，formatBits 写入格式信息） */
export class QrEcc {
  static readonly LOW: QrEcc = new QrEcc(0, 1);
  static readonly MEDIUM: QrEcc = new QrEcc(1, 0);
  static readonly QUARTILE: QrEcc = new QrEcc(2, 3);
  static readonly HIGH: QrEcc = new QrEcc(3, 2);

  readonly ordinal: number;
  readonly formatBits: number;

  private constructor(ord: number, fb: number) {
    this.ordinal = ord;
    this.formatBits = fb;
  }
}

const MIN_VERSION = 1;
const MAX_VERSION = 40;

/** 每版本每纠错级的纠错码字数（行 = 级别 ordinal L/M/Q/H，列 = version，[0] 占位） */
const ECC_CODEWORDS_PER_BLOCK: number[][] = [
  [-1, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
  [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28],
  [-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
  [-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30]
];

/** 每版本每纠错级的纠错块数 */
const NUM_ERROR_CORRECTION_BLOCKS: number[][] = [
  [-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8, 8, 9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25],
  [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49],
  [-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68],
  [-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81]
];

/** version 的总数据模块数（含纠错，不含功能图形），转字节容量用 */
function getNumRawDataModules(ver: number): number {
  let result = (16 * ver + 128) * ver + 64;
  if (ver >= 2) {
    const numAlign = Math.floor(ver / 7) + 2;
    result -= (25 * numAlign - 10) * numAlign - 55;
    if (ver >= 7) {
      result -= 36;
    }
  }
  return result;
}

function getNumDataCodewords(ver: number, ecl: QrEcc): number {
  return Math.floor(getNumRawDataModules(ver) / 8) -
    ECC_CODEWORDS_PER_BLOCK[ecl.ordinal][ver] * NUM_ERROR_CORRECTION_BLOCKS[ecl.ordinal][ver];
}

/** GF(2^8) 乘法（模 0x11D） */
function reedSolomonMultiply(x: number, y: number): number {
  let z = 0;
  for (let i = 7; i >= 0; i--) {
    z = (z << 1) ^ ((z >>> 7) * 0x11D);
    z ^= ((y >>> i) & 1) * x;
  }
  return z & 0xFF;
}

function reedSolomonComputeDivisor(degree: number): number[] {
  const result: number[] = [];
  for (let i = 0; i < degree - 1; i++) {
    result.push(0);
  }
  result.push(1);
  let root = 1;
  for (let i = 0; i < degree; i++) {
    for (let j = 0; j < result.length; j++) {
      result[j] = reedSolomonMultiply(result[j], root);
      if (j + 1 < result.length) {
        result[j] ^= result[j + 1];
      }
    }
    root = reedSolomonMultiply(root, 0x02);
  }
  return result;
}

function reedSolomonComputeRemainder(data: number[], divisor: number[]): number[] {
  const result: number[] = divisor.map((): number => 0);
  for (const b of data) {
    const factor = b ^ (result.shift() as number);
    result.push(0);
    divisor.forEach((coef: number, i: number): void => {
      result[i] ^= reedSolomonMultiply(coef, factor);
    });
  }
  return result;
}

/** UTF-8 编码 */
function toUtf8Bytes(str: string): number[] {
  const out: number[] = [];
  for (let i = 0; i < str.length; i++) {
    let cp = str.codePointAt(i) as number;
    if (cp > 0xFFFF) {
      i++;
    }
    if (cp < 0x80) {
      out.push(cp);
    } else if (cp < 0x800) {
      out.push(0xC0 | (cp >>> 6), 0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
      out.push(0xE0 | (cp >>> 12), 0x80 | ((cp >>> 6) & 0x3F), 0x80 | (cp & 0x3F));
    } else {
      out.push(0xF0 | (cp >>> 18), 0x80 | ((cp >>> 12) & 0x3F), 0x80 | ((cp >>> 6) & 0x3F), 0x80 | (cp & 0x3F));
    }
  }
  return out;
}

const PENALTY_N1 = 3;
const PENALTY_N2 = 3;
const PENALTY_N3 = 40;
const PENALTY_N4 = 10;

/**
 * QR 码：encodeText 编码文本 → modules[y][x]（true=黑）。
 * Byte 模式 + 自动选版本（1-40）+ 自动选掩码。
 */
export class QrCode {
  readonly version: number;
  readonly size: number;
  readonly mask: number;
  private modules: boolean[][] = [];
  private isFunction: boolean[][] = [];

  /** 任意文本 → QR（Byte 模式，UTF-8） */
  static encodeText(text: string, ecl: QrEcc): QrCode {
    const data = toUtf8Bytes(text);
    // 选最小可容纳版本
    let version = MIN_VERSION;
    let dataUsedBits = -1;
    for (; ; version++) {
      const dataCapacityBits = getNumDataCodewords(version, ecl) * 8;
      const ccBits = version < 10 ? 8 : 16;              // Byte 模式计数位
      const usedBits = 4 + ccBits + data.length * 8;
      if (usedBits <= dataCapacityBits) {
        dataUsedBits = usedBits;
        break;
      }
      if (version >= MAX_VERSION) {
        throw new Error('内容过长，无法编码');
      }
    }
    // 组装比特流：模式 0100 + 长度 + 数据
    const bb: number[] = [];
    const appendBits = (val: number, len: number): void => {
      for (let i = len - 1; i >= 0; i--) {
        bb.push((val >>> i) & 1);
      }
    };
    appendBits(4, 4);
    appendBits(data.length, version < 10 ? 8 : 16);
    for (const b of data) {
      appendBits(b, 8);
    }
    // 终止符与填充
    const dataCapacityBits = getNumDataCodewords(version, ecl) * 8;
    appendBits(0, Math.min(4, dataCapacityBits - bb.length));
    appendBits(0, (8 - bb.length % 8) % 8);
    for (let padByte = 0xEC; bb.length < dataCapacityBits; padByte ^= 0xEC ^ 0x11) {
      appendBits(padByte, 8);
    }
    // 比特 → 字节
    const dataCodewords: number[] = [];
    while (dataCodewords.length * 8 < bb.length) {
      dataCodewords.push(0);
    }
    bb.forEach((bit: number, i: number): void => {
      dataCodewords[i >>> 3] |= bit << (7 - (i & 7));
    });
    return new QrCode(version, ecl, dataCodewords, -1);
  }

  private constructor(version: number, ecl: QrEcc, dataCodewords: number[], msk: number) {
    this.version = version;
    this.size = version * 4 + 17;
    // 初始化网格
    for (let i = 0; i < this.size; i++) {
      const row: boolean[] = [];
      const frow: boolean[] = [];
      for (let j = 0; j < this.size; j++) {
        row.push(false);
        frow.push(false);
      }
      this.modules.push(row);
      this.isFunction.push(frow);
    }
    this.drawFunctionPatterns(ecl);
    const allCodewords = this.addEccAndInterleave(dataCodewords, ecl);
    this.drawCodewords(allCodewords);
    // 自动掩码：罚分最小
    if (msk === -1) {
      let minPenalty = 1000000000;
      for (let i = 0; i < 8; i++) {
        this.applyMask(i);
        this.drawFormatBits(ecl, i);
        const penalty = this.getPenaltyScore();
        if (penalty < minPenalty) {
          msk = i;
          minPenalty = penalty;
        }
        this.applyMask(i);   // 异或撤销
      }
    }
    this.mask = msk;
    this.applyMask(msk);
    this.drawFormatBits(ecl, msk);
    this.isFunction = [];
  }

  /** (x,y) 是否黑模块 */
  getModule(x: number, y: number): boolean {
    return x >= 0 && x < this.size && y >= 0 && y < this.size && this.modules[y][x];
  }

  private setFunctionModule(x: number, y: number, isDark: boolean): void {
    this.modules[y][x] = isDark;
    this.isFunction[y][x] = true;
  }

  private drawFunctionPatterns(ecl: QrEcc): void {
    // 时序线
    for (let i = 0; i < this.size; i++) {
      this.setFunctionModule(6, i, i % 2 === 0);
      this.setFunctionModule(i, 6, i % 2 === 0);
    }
    // 三个定位角
    this.drawFinderPattern(3, 3);
    this.drawFinderPattern(this.size - 4, 3);
    this.drawFinderPattern(3, this.size - 4);
    // 对齐图形
    const alignPatPos = this.getAlignmentPatternPositions();
    const numAlign = alignPatPos.length;
    for (let i = 0; i < numAlign; i++) {
      for (let j = 0; j < numAlign; j++) {
        if (!(i === 0 && j === 0 || i === 0 && j === numAlign - 1 || i === numAlign - 1 && j === 0)) {
          this.drawAlignmentPattern(alignPatPos[i], alignPatPos[j]);
        }
      }
    }
    this.drawFormatBits(ecl, 0);   // 占位（掩码定后重画）
    this.drawVersion();
  }

  private drawFormatBits(ecl: QrEcc, mask: number): void {
    const data = ecl.formatBits << 3 | mask;
    let rem = data;
    for (let i = 0; i < 10; i++) {
      rem = (rem << 1) ^ ((rem >>> 9) * 0x537);
    }
    const bits = (data << 10 | rem) ^ 0x5412;
    for (let i = 0; i <= 5; i++) {
      this.setFunctionModule(8, i, ((bits >>> i) & 1) !== 0);
    }
    this.setFunctionModule(8, 7, ((bits >>> 6) & 1) !== 0);
    this.setFunctionModule(8, 8, ((bits >>> 7) & 1) !== 0);
    this.setFunctionModule(7, 8, ((bits >>> 8) & 1) !== 0);
    for (let i = 9; i < 15; i++) {
      this.setFunctionModule(14 - i, 8, ((bits >>> i) & 1) !== 0);
    }
    for (let i = 0; i < 8; i++) {
      this.setFunctionModule(this.size - 1 - i, 8, ((bits >>> i) & 1) !== 0);
    }
    for (let i = 8; i < 15; i++) {
      this.setFunctionModule(8, this.size - 15 + i, ((bits >>> i) & 1) !== 0);
    }
    this.setFunctionModule(8, this.size - 8, true);
  }

  private drawVersion(): void {
    if (this.version < 7) {
      return;
    }
    let rem = this.version;
    for (let i = 0; i < 12; i++) {
      rem = (rem << 1) ^ ((rem >>> 11) * 0x1F25);
    }
    const bits = this.version << 12 | rem;
    for (let i = 0; i < 18; i++) {
      const color = ((bits >>> i) & 1) !== 0;
      const a = this.size - 11 + i % 3;
      const b = Math.floor(i / 3);
      this.setFunctionModule(a, b, color);
      this.setFunctionModule(b, a, color);
    }
  }

  private drawFinderPattern(x: number, y: number): void {
    for (let dy = -4; dy <= 4; dy++) {
      for (let dx = -4; dx <= 4; dx++) {
        const dist = Math.max(Math.abs(dx), Math.abs(dy));
        const xx = x + dx;
        const yy = y + dy;
        if (xx >= 0 && xx < this.size && yy >= 0 && yy < this.size) {
          this.setFunctionModule(xx, yy, dist !== 2 && dist !== 4);
        }
      }
    }
  }

  private drawAlignmentPattern(x: number, y: number): void {
    for (let dy = -2; dy <= 2; dy++) {
      for (let dx = -2; dx <= 2; dx++) {
        this.setFunctionModule(x + dx, y + dy, Math.max(Math.abs(dx), Math.abs(dy)) !== 1);
      }
    }
  }

  private getAlignmentPatternPositions(): number[] {
    if (this.version === 1) {
      return [];
    }
    const numAlign = Math.floor(this.version / 7) + 2;
    const step = this.version === 32 ? 26 :
      Math.ceil((this.version * 4 + 4) / (numAlign * 2 - 2)) * 2;
    const result: number[] = [6];
    for (let pos = this.size - 7; result.length < numAlign; pos -= step) {
      result.splice(1, 0, pos);
    }
    return result;
  }

  private addEccAndInterleave(data: number[], ecl: QrEcc): number[] {
    const ver = this.version;
    const numBlocks = NUM_ERROR_CORRECTION_BLOCKS[ecl.ordinal][ver];
    const blockEccLen = ECC_CODEWORDS_PER_BLOCK[ecl.ordinal][ver];
    const rawCodewords = Math.floor(getNumRawDataModules(ver) / 8);
    const numShortBlocks = numBlocks - rawCodewords % numBlocks;
    const shortBlockLen = Math.floor(rawCodewords / numBlocks);

    const blocks: number[][] = [];
    const rsDiv = reedSolomonComputeDivisor(blockEccLen);
    let k = 0;
    for (let i = 0; i < numBlocks; i++) {
      const dat = data.slice(k, k + shortBlockLen - blockEccLen + (i < numShortBlocks ? 0 : 1));
      k += dat.length;
      const ecc = reedSolomonComputeRemainder(dat, rsDiv);
      if (i < numShortBlocks) {
        dat.push(0);
      }
      blocks.push(dat.concat(ecc));
    }
    const result: number[] = [];
    for (let i = 0; i < blocks[0].length; i++) {
      blocks.forEach((block: number[], j: number): void => {
        if (i !== shortBlockLen - blockEccLen || j >= numShortBlocks) {
          result.push(block[i]);
        }
      });
    }
    return result;
  }

  private drawCodewords(data: number[]): void {
    let i = 0;
    for (let right = this.size - 1; right >= 1; right -= 2) {
      if (right === 6) {
        right = 5;
      }
      for (let vert = 0; vert < this.size; vert++) {
        for (let j = 0; j < 2; j++) {
          const x = right - j;
          const upward = ((right + 1) & 2) === 0;
          const y = upward ? this.size - 1 - vert : vert;
          if (!this.isFunction[y][x] && i < data.length * 8) {
            this.modules[y][x] = ((data[i >>> 3] >>> (7 - (i & 7))) & 1) !== 0;
            i++;
          }
        }
      }
    }
  }

  private applyMask(mask: number): void {
    for (let y = 0; y < this.size; y++) {
      for (let x = 0; x < this.size; x++) {
        let invert = false;
        if (mask === 0) { invert = (x + y) % 2 === 0; }
        else if (mask === 1) { invert = y % 2 === 0; }
        else if (mask === 2) { invert = x % 3 === 0; }
        else if (mask === 3) { invert = (x + y) % 3 === 0; }
        else if (mask === 4) { invert = (Math.floor(x / 3) + Math.floor(y / 2)) % 2 === 0; }
        else if (mask === 5) { invert = x * y % 2 + x * y % 3 === 0; }
        else if (mask === 6) { invert = (x * y % 2 + x * y % 3) % 2 === 0; }
        else { invert = ((x + y) % 2 + x * y % 3) % 2 === 0; }
        if (!this.isFunction[y][x] && invert) {
          this.modules[y][x] = !this.modules[y][x];
        }
      }
    }
  }

  private getPenaltyScore(): number {
    let result = 0;
    // 行/列连续同色
    for (let y = 0; y < this.size; y++) {
      let runColor = false;
      let runX = 0;
      const runHistory: number[] = [0, 0, 0, 0, 0, 0, 0];
      for (let x = 0; x < this.size; x++) {
        if (this.modules[y][x] === runColor) {
          runX++;
          if (runX === 5) {
            result += PENALTY_N1;
          } else if (runX > 5) {
            result++;
          }
        } else {
          this.finderPenaltyAddHistory(runX, runHistory);
          if (!runColor) {
            result += this.finderPenaltyCountPatterns(runHistory) * PENALTY_N3;
          }
          runColor = this.modules[y][x];
          runX = 1;
        }
      }
      result += this.finderPenaltyTerminateAndCount(runColor, runX, runHistory) * PENALTY_N3;
    }
    for (let x = 0; x < this.size; x++) {
      let runColor = false;
      let runY = 0;
      const runHistory: number[] = [0, 0, 0, 0, 0, 0, 0];
      for (let y = 0; y < this.size; y++) {
        if (this.modules[y][x] === runColor) {
          runY++;
          if (runY === 5) {
            result += PENALTY_N1;
          } else if (runY > 5) {
            result++;
          }
        } else {
          this.finderPenaltyAddHistory(runY, runHistory);
          if (!runColor) {
            result += this.finderPenaltyCountPatterns(runHistory) * PENALTY_N3;
          }
          runColor = this.modules[y][x];
          runY = 1;
        }
      }
      result += this.finderPenaltyTerminateAndCount(runColor, runY, runHistory) * PENALTY_N3;
    }
    // 2×2 同色块
    for (let y = 0; y < this.size - 1; y++) {
      for (let x = 0; x < this.size - 1; x++) {
        const color = this.modules[y][x];
        if (color === this.modules[y][x + 1] && color === this.modules[y + 1][x] && color === this.modules[y + 1][x + 1]) {
          result += PENALTY_N2;
        }
      }
    }
    // 黑白比例
    let dark = 0;
    for (const row of this.modules) {
      for (const cell of row) {
        if (cell) {
          dark++;
        }
      }
    }
    const total = this.size * this.size;
    const kk = Math.ceil(Math.abs(dark * 20 - total * 10) / total) - 1;
    result += kk * PENALTY_N4;
    return result;
  }

  private finderPenaltyCountPatterns(runHistory: number[]): number {
    const n = runHistory[1];
    const core = n > 0 && runHistory[2] === n && runHistory[3] === n * 3 && runHistory[4] === n && runHistory[5] === n;
    return (core && runHistory[0] >= n * 4 && runHistory[6] >= n ? 1 : 0) +
      (core && runHistory[6] >= n * 4 && runHistory[0] >= n ? 1 : 0);
  }

  private finderPenaltyTerminateAndCount(currentRunColor: boolean, currentRunLength: number, runHistory: number[]): number {
    if (currentRunColor) {
      this.finderPenaltyAddHistory(currentRunLength, runHistory);
      currentRunLength = 0;
    }
    currentRunLength += this.size;
    this.finderPenaltyAddHistory(currentRunLength, runHistory);
    return this.finderPenaltyCountPatterns(runHistory);
  }

  private finderPenaltyAddHistory(currentRunLength: number, runHistory: number[]): void {
    if (runHistory[0] === 0) {
      currentRunLength += this.size;
    }
    runHistory.pop();
    runHistory.unshift(currentRunLength);
  }
}
