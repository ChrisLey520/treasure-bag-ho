import { ToolStore } from '../../utils/ToolStore';

interface Record {
  id: number;
  amount: number;    // 正=收入 负=支出
  note: string;
  category: string;
  date: string;      // 'YYYY-MM-DD'
}

const STORE_KEY = 'ledger';
const EXPENSE_CATS: string[] = ['🍜 餐饮', '🚇 交通', '🛒 购物', '🏠 居住', '🎮 娱乐', '💊 医疗', '📦 其他'];
const INCOME_CATS: string[] = ['💰 工资', '🧧 红包', '📈 理财', '📦 其他'];

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
}

@Component
export struct LedgerPage {
  @State records: Record[] = [];
  @State amountInput: string = '';
  @State noteInput: string = '';
  @State isExpense: boolean = true;
  @State catIndex: number = 0;
  @State showAdd: boolean = false;

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    const saved = await ToolStore.get(ctx, STORE_KEY, '[]');
    try {
      this.records = JSON.parse(saved) as Record[];
    } catch (err) {
      this.records = [];
    }
  }

  persist(): void {
    ToolStore.save(STORE_KEY, JSON.stringify(this.records));
  }

  cats(): string[] {
    return this.isExpense ? EXPENSE_CATS : INCOME_CATS;
  }

  add(): void {
    const amount = parseFloat(this.amountInput);
    if (isNaN(amount) || amount <= 0) {
      this.getUIContext().getPromptAction().showToast({ message: '请输入有效金额', duration: 1200 });
      return;
    }
    const maxId = this.records.reduce((m, r) => Math.max(m, r.id), 0);
    this.records = [{
      id: maxId + 1,
      amount: this.isExpense ? -amount : amount,
      note: this.noteInput.trim(),
      category: this.cats()[Math.min(this.catIndex, this.cats().length - 1)],
      date: todayStr()
    }, ...this.records];
    this.amountInput = '';
    this.noteInput = '';
    this.showAdd = false;
    this.persist();
  }

  remove(id: number): void {
    this.records = this.records.filter(r => r.id !== id);
    this.persist();
  }

  /** 本月支出、收入 */
  monthSummary(): [number, number] {
    const prefix = todayStr().substring(0, 7);
    let expense = 0;
    let income = 0;
    for (const r of this.records) {
      if (r.date.startsWith(prefix)) {
        if (r.amount < 0) {
          expense += -r.amount;
        } else {
          income += r.amount;
        }
      }
    }
    return [expense, income];
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        // 本月汇总
        Row() {
          Column({ space: 4 }) {
            Text('本月支出').fontSize(12).fontColor('#CCFFFFFF')
            Text(`¥ ${this.monthSummary()[0].toFixed(2)}`)
              .fontSize(24).fontWeight(FontWeight.Bold).fontColor(Color.White)
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Column({ space: 4 }) {
            Text('本月收入').fontSize(12).fontColor('#CCFFFFFF')
            Text(`¥ ${this.monthSummary()[1].toFixed(2)}`)
              .fontSize(24).fontWeight(FontWeight.Bold).fontColor(Color.White)
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding(20)
        .borderRadius(20)
        .linearGradient({ angle: 135, colors: [['#373B44', 0], ['#4286F4', 1]] })

        if (this.showAdd) {
          Column({ space: 12 }) {
            Row({ space: 10 }) {
              ForEach(['支出', '收入'], (label: string, i: number) => {
                Text(label)
                  .fontSize(14)
                  .fontColor((this.isExpense ? 0 : 1) === i ? Color.White : $r('app.color.text_secondary'))
                  .padding({ left: 18, right: 18, top: 8, bottom: 8 })
                  .borderRadius(16)
                  .backgroundColor((this.isExpense ? 0 : 1) === i
                    ? (i === 0 ? '#F5576C' : '#43E97B')
                    : $r('app.color.bg_page'))
                  .onClick(() => {
                    this.isExpense = i === 0;
                    this.catIndex = 0;
                  })
              }, (label: string) => label)
            }
            .alignSelf(ItemAlign.Start)

            TextInput({ placeholder: '金额', text: this.amountInput })
              .type(InputType.NUMBER_DECIMAL)
              .height(48).borderRadius(12)
              .backgroundColor($r('app.color.bg_page'))
              .fontColor($r('app.color.text_primary'))
              .onChange((v: string) => { this.amountInput = v; })

            Scroll() {
              Row({ space: 8 }) {
                ForEach(this.cats(), (c: string, i: number) => {
                  Text(c)
                    .fontSize(13)
                    .fontColor(this.catIndex === i ? Color.White : $r('app.color.text_secondary'))
                    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                    .borderRadius(15)
                    .backgroundColor(this.catIndex === i ? $r('app.color.accent') : $r('app.color.bg_page'))
                    .onClick(() => { this.catIndex = i; })
                }, (c: string) => c)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')

            TextInput({ placeholder: '备注（可选）', text: this.noteInput })
              .height(48).borderRadius(12)
              .backgroundColor($r('app.color.bg_page'))
              .fontColor($r('app.color.text_primary'))
              .onChange((v: string) => { this.noteInput = v; })

            Row({ space: 10 }) {
              Button('取消')
                .layoutWeight(1).height(44)
                .backgroundColor($r('app.color.bg_page'))
                .fontColor($r('app.color.text_primary'))
                .onClick(() => { this.showAdd = false; })
              Button('记一笔')
                .layoutWeight(1).height(44)
                .backgroundColor($r('app.color.accent'))
                .onClick(() => this.add())
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
        } else {
          Button('+ 记一笔')
            .width('100%').height(48)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => { this.showAdd = true; })
        }

        List({ space: 8 }) {
          ForEach(this.records.slice(0, 100), (r: Record) => {
            ListItem() {
              Row({ space: 12 }) {
                Text(r.category.split(' ')[0]).fontSize(24)
                Column({ space: 2 }) {
                  Text(r.note.length > 0 ? r.note : r.category.split(' ')[1])
                    .fontSize(15)
                    .fontColor($r('app.color.text_primary'))
                  Text(r.date)
                    .fontSize(11)
                    .fontColor($r('app.color.text_secondary'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text(`${r.amount < 0 ? '-' : '+'}¥${Math.abs(r.amount).toFixed(2)}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(r.amount < 0 ? '#F5576C' : '#43E97B')
              }
              .width('100%')
              .padding(14)
              .borderRadius(14)
              .backgroundColor($r('app.color.bg_card'))
              .gesture(LongPressGesture().onAction(() => this.remove(r.id)))
            }
          }, (r: Record) => r.id.toString())
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        if (this.records.length === 0 && !this.showAdd) {
          Column({ space: 8 }) {
            Text('📒').fontSize(48)
            Text('极简记账，长按记录可删除')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .margin({ bottom: 100 })
        }
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('极简记账')
    .backgroundColor($r('app.color.bg_page'))
  }
}
