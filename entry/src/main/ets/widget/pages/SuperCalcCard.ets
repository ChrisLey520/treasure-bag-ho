import { SciParser, fmtResult, normalizeFx } from '../../utils/SciParser';
import { RItem, EditState, buildRenderItems, insertTextAt, insertTemplateAt,
  backspaceAt, moveCursorBy, hasOperandBeforeAt } from '../../utils/CalcRender';

let storageSuper = new LocalStorage();

/** 与 App 内超级计算器对齐的键盘（□ 为占位块模板键），卡片空间取基础区+函数行 */
const CARD_KEYS: string[][] = [
  ['log□', '□^□', '√□', '□/□', '÷'],
  ['x', '7', '8', '9', '×'],
  ['y', '4', '5', '6', '−'],
  ['z', '1', '2', '3', '+'],
  ['(', ')', '0', '.', '='],
  ['sin', 'cos', 'tan', 'π', 'e']
];

@Entry(storageSuper)
@Component
struct SuperCalcCard {
  @State expression: string = '';
  @State cursor: number = 0;
  @State result: string = '';
  @State degMode: boolean = true;
  private ans: number = 0;
  private parser: SciParser = new SciParser();

  // ── 光标编辑（与 App 内共用 CalcRender 核心）──
  insertText(s: string): void {
    this.consumeTrailingEq();
    const st = insertTextAt(this.expression, this.cursor, s);
    this.expression = st.expr;
    this.cursor = st.cursor;
    this.result = '';
  }

  insertTemplate(s: string): void {
    this.consumeTrailingEq();
    const st = insertTemplateAt(this.expression, this.cursor, s);
    this.expression = st.expr;
    this.cursor = st.cursor;
    this.result = '';
  }

  /** 出结果后继续输入：式尾待求的 = 被新内容替换（与 App 内一致） */
  private consumeTrailingEq(): void {
    if (this.expression.endsWith('=')) {
      this.expression = this.expression.substring(0, this.expression.length - 1);
      if (this.cursor > this.expression.length) {
        this.cursor = this.expression.length;
      }
    }
  }

  /** = 键：式尾补显 = 并求值（与 App 内一致；方程求解请进 App） */
  private onEquals(): void {
    const body = this.expression.endsWith('=')
      ? this.expression.substring(0, this.expression.length - 1).trim()
      : this.expression.trim();
    if (body.length === 0) {
      return;
    }
    if (body.includes('□')) {
      this.cursor = this.expression.indexOf('□');
      this.result = '请先填写参数块';
      return;
    }
    if (!this.expression.endsWith('=')) {
      this.expression += '=';
      this.cursor = this.expression.length;
    }
    if (/[xyz]/.test(body.replace(/sin|cos|tan|ans/gi, ''))) {
      this.result = '方程请进 App 求解';
      return;
    }
    try {
      const v = this.parser.parse(normalizeFx(body), this.degMode, this.ans);
      this.result = `= ${fmtResult(v)}`;
      this.ans = v;
    } catch (err) {
      this.result = (err as Error).message;
    }
  }

  onKey(k: string): void {
    if (k.length === 0) {
      return;
    }
    if (k === '=') {
      this.onEquals();
      return;
    }
    // 模板键 → 插入 □ 占位块，光标落在首个 □（与 App 内一致）
    if (k === 'log□') {
      this.insertTemplate('log(□,□)');
      return;
    }
    if (k === '□^□') {
      if (hasOperandBeforeAt(this.expression, this.cursor)) {
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
      if (hasOperandBeforeAt(this.expression, this.cursor)) {
        this.insertTemplate('÷□');
      } else {
        this.insertTemplate('□÷□');
      }
      return;
    }
    if (k === 'sin' || k === 'cos' || k === 'tan') {
      this.insertTemplate(`${k}(□)`);
      return;
    }
    this.insertText(k);
  }

  private isPlainKey(k: string): boolean {
    if ((k >= '0' && k <= '9') || k === '.') {
      return true;
    }
    return k === 'x' || k === 'y' || k === 'z' || k === '(' || k === ')';
  }

  keyBg(k: string): ResourceColor {
    if (k === '=') {
      return $r('app.color.accent');
    }
    return this.isPlainKey(k) ? $r('app.color.bg_card') : '#2E3140';
  }

  keyFg(k: string): ResourceColor {
    if (k === '=') {
      return Color.White;
    }
    return this.isPlainKey(k) ? $r('app.color.text_primary') : '#7B88FF';
  }

  /** 按键图标里的参数输入块（与 App 内 pbox 同构，卡片缩小） */
  @Builder
  pbox(w: number, h: number) {
    Text('')
      .width(w)
      .height(h)
      .borderRadius(2)
      .backgroundColor('#4D8A8F9C')
  }

  /** 按键面：模板键在参数对应位置画输入块（与 App 内 keyFace 对齐） */
  @Builder
  keyFace(k: string) {
    if (k === 'log□') {
      Row() {
        Text('log').fontSize(11).fontColor('#7B88FF')
        this.pbox(5, 5)
        Row() {
          this.pbox(8, 9)
        }.margin({ left: 2 })
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '□^□') {
      Row() {
        this.pbox(9, 10)
        Row() {
          this.pbox(5, 6)
        }.margin({ left: 2 }).offset({ x: 0, y: -5 })
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '√□') {
      Row() {
        Text('√').fontSize(15).fontColor('#7B88FF')
        this.pbox(8, 9)
      }
      .alignItems(VerticalAlign.Center)
    } else if (k === '□/□') {
      Column({ space: 1 }) {
        this.pbox(7, 6)
        Text('').width(12).height(1).backgroundColor('#7B88FF')
        this.pbox(7, 6)
      }
      .alignItems(HorizontalAlign.Center)
    } else {
      Text(k)
        .fontSize(k.length > 2 ? 10 : 13)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.keyFg(k))
    }
  }

  build() {
    Column({ space: 5 }) {
      // 品牌行：徽标 + DEG/RAD 切换（点击品牌进 App）
      Row({ space: 6 }) {
        Text('√')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width(16)
          .height(16)
          .borderRadius(5)
          .linearGradient({ angle: 135, colors: [['#42275A', 0], ['#734B6D', 1]] })
        Text('超级计算器')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text(this.degMode ? 'DEG' : 'RAD')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#7B88FF')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
          .backgroundColor('#2E3140')
          .onClick(() => {
            this.degMode = !this.degMode;
          })
      }
      .width('100%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetTool: 'supercalc' }
        });
      })

      // 显示区：数学式富渲染（上下标、参数块、点击定位光标）+ 结果
      Column({ space: 2 }) {
        Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap,
          justifyContent: FlexAlign.End, alignItems: ItemAlign.Center }) {
          if (this.expression.length === 0) {
            Text('输入算式…')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Text('').width(2).height(16).borderRadius(1).backgroundColor($r('app.color.accent'))
          } else {
            ForEach(buildRenderItems(this.expression, this.cursor), (it: RItem, idx: number) => {
              if (it.cb) {
                Text('')
                  .width(2)
                  .height(it.level === 0 ? 16 : 10)
                  .borderRadius(1)
                  .backgroundColor($r('app.color.accent'))
                  .margin({ left: 1, right: 1 })
                  .offset({ x: 0, y: it.level === 1 ? -5 : (it.level === 2 ? 5 : 0) })
              }
              if (it.box) {
                Row() {
                  if (it.sel) {
                    Text('').width(2).height(it.level === 0 ? 12 : 7).borderRadius(1).backgroundColor('#FF9F43')
                  }
                }
                .justifyContent(FlexAlign.Center)
                .width(it.level === 0 ? 14 : 9)
                .height(it.level === 0 ? 16 : 10)
                .borderRadius(3)
                .backgroundColor(it.sel ? '#66FF9F43' : '#2EFF9F43')
                .border({ width: 1, color: it.sel ? '#FF9F43' : '#66FF9F43' })
                .margin({ left: 1, right: 1 })
                .offset({ x: 0, y: it.level === 1 ? -5 : (it.level === 2 ? 5 : 0) })
                .onClick(() => {
                  this.cursor = it.start;
                })
              } else if (it.s.length > 0) {
                Text(it.s)
                  .fontSize(it.level === 0 ? 15 : 9)
                  .fontColor($r('app.color.text_primary'))
                  .offset({ x: 0, y: it.level === 1 ? -5 : (it.level === 2 ? 5 : 0) })
                  .onClick(() => {
                    this.cursor = it.end;
                  })
              }
            }, (it: RItem, idx: number) => `${idx}-${it.s}-${it.box}-${it.level}-${it.cb}-${it.sel}`)
          }
        }
        .width('100%')

        Text(this.result.length > 0 ? this.result : ' ')
          .fontSize(this.result.length > 14 ? 12 : 15)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.accent'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.End)
          .width('100%')
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .borderRadius(12)
      .backgroundColor($r('app.color.bg_card'))

      // 编辑工具条：清空 ◀ ▶ 退格（与 App 内工具条对齐）
      Row({ space: 4 }) {
        Text('🗑')
          .fontSize(11)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(22)
          .borderRadius(7)
          .backgroundColor('#33F5576C')
          .onClick(() => {
            this.expression = '';
            this.cursor = 0;
            this.result = '';
          })
        Text('◀')
          .fontSize(11)
          .fontColor($r('app.color.text_primary'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(22)
          .borderRadius(7)
          .backgroundColor($r('app.color.bg_card'))
          .onClick(() => {
            this.cursor = moveCursorBy(this.expression, this.cursor, -1);
          })
        Text('▶')
          .fontSize(11)
          .fontColor($r('app.color.text_primary'))
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(22)
          .borderRadius(7)
          .backgroundColor($r('app.color.bg_card'))
          .onClick(() => {
            this.cursor = moveCursorBy(this.expression, this.cursor, 1);
          })
        Text('⌫')
          .fontSize(12)
          .fontColor('#7B88FF')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(22)
          .borderRadius(7)
          .backgroundColor('#2E3140')
          .onClick(() => {
            const st = backspaceAt(this.expression, this.cursor);
            this.expression = st.expr;
            this.cursor = st.cursor;
            this.result = '';
          })
      }
      .width('100%')

      // 键盘：与 App 内基础面板同构（模板键带参数位输入块图标）
      Column({ space: 4 }) {
        ForEach(CARD_KEYS, (row: string[]) => {
          Row({ space: 4 }) {
            ForEach(row, (k: string) => {
              Row() {
                this.keyFace(k)
              }
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
              .layoutWeight(1)
              .height('100%')
              .borderRadius(8)
              .backgroundColor(this.keyBg(k))
              .onClick(() => this.onKey(k))
            }, (k: string, j: number) => `${k}-${j}`)
          }
          .width('100%')
          .layoutWeight(1)
        }, (row: string[], i: number) => `r${i}`)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .padding(10)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
