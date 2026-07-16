import { SciParser, fmtResult } from '../../utils/SciParser';

let storageSuper = new LocalStorage();

const KEYS: string[][] = [
  ['sin', 'cos', 'tan', 'π', '⌫'],
  ['ln', 'log', '√', '^', '÷'],
  ['7', '8', '9', '(', '×'],
  ['4', '5', '6', ')', '−'],
  ['1', '2', '3', '%', '+'],
  ['C', '0', '.', 'ANS', '=']
];

@Entry(storageSuper)
@Component
struct SuperCalcCard {
  @State expression: string = '';
  @State result: string = '';
  @State degMode: boolean = true;
  private ans: number = 0;
  private parser: SciParser = new SciParser();

  onKey(k: string): void {
    if (k === 'C') {
      this.expression = '';
      this.result = '';
      return;
    }
    if (k === '⌫') {
      // 函数名整体删除
      const fns: string[] = ['sin', 'cos', 'tan', 'ln', 'log', 'ANS'];
      let cut = 1;
      for (const fn of fns) {
        if (this.expression.endsWith(fn)) {
          cut = fn.length;
          break;
        }
      }
      this.expression = this.expression.slice(0, -cut);
      this.result = '';
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
    if ((k >= '0' && k <= '9') || k === '.') {
      return $r('app.color.bg_card');
    }
    return '#2E3140';
  }

  keyFg(k: string): ResourceColor {
    if (k === '=') {
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

  build() {
    Column({ space: 6 }) {
      // 品牌行：自绘徽标（深紫渐变方块 + √）+ DEG/RAD 切换
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

      // 显示区：上行表达式，下行结果（与百宝计算器卡片同构）
      Column({ space: 2 }) {
        Text(this.expression.length > 0 ? this.expression : ' ')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.End)
          .width('100%')
        Text(this.result.length > 0 ? `= ${this.result}` : (this.expression.length > 0 ? '…' : '0'))
          .fontSize(this.result.length > 14 ? 15 : 20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.result.length > 0 ? $r('app.color.accent') : $r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.End)
          .width('100%')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(12)
      .backgroundColor($r('app.color.bg_card'))
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetTool: 'supercalc' }
        });
      })

      // 键盘
      Column({ space: 4 }) {
        ForEach(KEYS, (row: string[]) => {
          Row({ space: 4 }) {
            ForEach(row, (k: string) => {
              Text(k)
                .fontSize(k.length > 2 ? 11 : 14)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.keyFg(k))
                .textAlign(TextAlign.Center)
                .layoutWeight(1)
                .height('100%')
                .borderRadius(8)
                .backgroundColor(this.keyBg(k))
                .onClick(() => this.onKey(k))
            }, (k: string) => k)
          }
          .width('100%')
          .layoutWeight(1)
        }, (row: string[]) => row.join(''))
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
