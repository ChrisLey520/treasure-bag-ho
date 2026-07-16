import { ToolStore } from '../../utils/ToolStore';

interface Anniversary {
  id: number;
  name: string;
  date: string; // 'YYYY-MM-DD'
}

const STORE_KEY = 'anniversaries';
const CARD_GRADIENTS: string[][] = [
  ['#FA709A', '#FEE140'],
  ['#4FACFE', '#00F2FE'],
  ['#43E97B', '#38F9D7'],
  ['#F093FB', '#F5576C'],
  ['#5B247A', '#1BCEDF']
];

function daysBetween(dateStr: string): number {
  const parts = dateStr.split('-');
  const target = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return Math.round((target.getTime() - today.getTime()) / 86400000);
}

@Component
export struct AnniversaryPage {
  @State items: Anniversary[] = [];
  @State input: string = '';
  @State selectedDate: Date = new Date();
  @State showAdd: boolean = false;

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    const saved = await ToolStore.get(ctx, STORE_KEY, '[]');
    try {
      this.items = JSON.parse(saved) as Anniversary[];
    } catch (err) {
      this.items = [];
    }
  }

  persist(): void {
    ToolStore.save(STORE_KEY, JSON.stringify(this.items));
  }

  add(): void {
    const name = this.input.trim();
    if (name.length === 0) {
      return;
    }
    const d = this.selectedDate;
    const dateStr = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
    const maxId = this.items.reduce((m, a) => Math.max(m, a.id), 0);
    this.items = [...this.items, { id: maxId + 1, name: name, date: dateStr }];
    this.input = '';
    this.showAdd = false;
    this.persist();
  }

  remove(id: number): void {
    this.items = this.items.filter(a => a.id !== id);
    this.persist();
  }

  dayText(a: Anniversary): string {
    const diff = daysBetween(a.date);
    if (diff === 0) {
      return '就是今天 🎉';
    }
    if (diff > 0) {
      return `还有 ${diff} 天`;
    }
    return `已经 ${-diff} 天`;
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        if (this.showAdd) {
          Column({ space: 12 }) {
            TextInput({ placeholder: '事件名称，如：领证纪念日', text: this.input })
              .height(48).borderRadius(12)
              .backgroundColor($r('app.color.bg_page'))
              .fontColor($r('app.color.text_primary'))
              .onChange((v: string) => { this.input = v; })
            DatePicker({ selected: this.selectedDate, start: new Date('1900-01-01'), end: new Date('2100-12-31') })
              .onDateChange((value: Date) => { this.selectedDate = value; })
              .height(140)
            Row({ space: 10 }) {
              Button('取消')
                .layoutWeight(1).height(44)
                .backgroundColor($r('app.color.bg_page'))
                .fontColor($r('app.color.text_primary'))
                .onClick(() => { this.showAdd = false; })
              Button('保存')
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
          Button('+ 添加纪念日 / 倒数日')
            .width('100%').height(48)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => { this.showAdd = true; })
        }

        List({ space: 12 }) {
          ForEach(this.items, (a: Anniversary, i: number) => {
            ListItem() {
              Row() {
                Column({ space: 4 }) {
                  Text(a.name)
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                  Text(a.date)
                    .fontSize(12)
                    .fontColor('#CCFFFFFF')
                }
                .alignItems(HorizontalAlign.Start)
                Blank()
                Text(this.dayText(a))
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
              }
              .width('100%')
              .padding(20)
              .borderRadius(18)
              .linearGradient({
                angle: 135,
                colors: [[CARD_GRADIENTS[i % CARD_GRADIENTS.length][0], 0], [CARD_GRADIENTS[i % CARD_GRADIENTS.length][1], 1]]
              })
              .gesture(LongPressGesture().onAction(() => this.remove(a.id)))
            }
          }, (a: Anniversary) => a.id.toString())
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        if (this.items.length === 0 && !this.showAdd) {
          Column({ space: 8 }) {
            Text('💝').fontSize(48)
            Text('记录重要的日子\n生日、纪念日、考试倒计时…（长按卡片删除）')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
              .lineHeight(22)
          }
          .margin({ bottom: 100 })
        }
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('纪念日')
    .backgroundColor($r('app.color.bg_page'))
  }
}
