import { ToolStore } from '../../utils/ToolStore';

interface Habit {
  id: number;
  name: string;
  emoji: string;
  dates: string[]; // 'YYYY-MM-DD'
}

const STORE_KEY = 'habits';
const EMOJIS: string[] = ['💪', '📚', '🏃', '💧', '🧘', '🌱', '✍️', '🎸'];

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
}

function streak(dates: string[]): number {
  if (dates.length === 0) {
    return 0;
  }
  const set = new Set<string>(dates);
  let count = 0;
  const cursor = new Date();
  // 今天未打卡则从昨天起算
  const fmt = (d: Date): string =>
    `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
  if (!set.has(fmt(cursor))) {
    cursor.setDate(cursor.getDate() - 1);
  }
  while (set.has(fmt(cursor))) {
    count += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return count;
}

@Component
export struct HabitPage {
  @State habits: Habit[] = [];
  @State input: string = '';
  @State emojiIndex: number = 0;

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    const saved = await ToolStore.get(ctx, STORE_KEY, '[]');
    try {
      this.habits = JSON.parse(saved) as Habit[];
    } catch (err) {
      this.habits = [];
    }
  }

  persist(): void {
    ToolStore.save(STORE_KEY, JSON.stringify(this.habits));
  }

  add(): void {
    const name = this.input.trim();
    if (name.length === 0) {
      return;
    }
    const maxId = this.habits.reduce((m, h) => Math.max(m, h.id), 0);
    this.habits = [...this.habits, {
      id: maxId + 1,
      name: name,
      emoji: EMOJIS[this.emojiIndex],
      dates: []
    }];
    this.input = '';
    this.persist();
  }

  checkIn(id: number): void {
    const today = todayStr();
    this.habits = this.habits.map((h): Habit => {
      if (h.id !== id) {
        return h;
      }
      const dates = h.dates.includes(today)
        ? h.dates.filter(d => d !== today)   // 再点一次取消
        : [...h.dates, today];
      return { id: h.id, name: h.name, emoji: h.emoji, dates: dates };
    });
    this.persist();
  }

  remove(id: number): void {
    this.habits = this.habits.filter(h => h.id !== id);
    this.persist();
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Row({ space: 10 }) {
          Text(EMOJIS[this.emojiIndex])
            .fontSize(24)
            .width(48).height(48)
            .textAlign(TextAlign.Center)
            .borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
            .onClick(() => {
              this.emojiIndex = (this.emojiIndex + 1) % EMOJIS.length;
            })
          TextInput({ placeholder: '新习惯，如：早睡', text: this.input })
            .layoutWeight(1)
            .height(48)
            .borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onChange((v: string) => { this.input = v; })
            .onSubmit(() => this.add())
          Button('+')
            .width(48).height(48)
            .fontSize(24)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => this.add())
        }
        .width('100%')

        List({ space: 10 }) {
          ForEach(this.habits, (h: Habit) => {
            ListItem() {
              Row({ space: 14 }) {
                Text(h.emoji).fontSize(28)
                Column({ space: 4 }) {
                  Text(h.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                  Text(`连续 ${streak(h.dates)} 天 · 累计 ${h.dates.length} 天`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(h.dates.includes(todayStr()) ? '已打卡 ✅' : '打卡')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(h.dates.includes(todayStr()) ? '#43E97B' : Color.White)
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .borderRadius(20)
                  .backgroundColor(h.dates.includes(todayStr()) ? '#1A43E97B' : $r('app.color.accent'))
                  .onClick(() => this.checkIn(h.id))
              }
              .width('100%')
              .padding(16)
              .borderRadius(16)
              .backgroundColor($r('app.color.bg_card'))
              .gesture(LongPressGesture().onAction(() => this.remove(h.id)))
            }
          }, (h: Habit) => `${h.id}-${h.dates.length}`)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        if (this.habits.length === 0) {
          Column({ space: 8 }) {
            Text('🌱').fontSize(48)
            Text('添加一个习惯开始打卡\n（点左侧图标切换 emoji，长按习惯可删除）')
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
    .title('习惯打卡')
    .backgroundColor($r('app.color.bg_page'))
  }
}
