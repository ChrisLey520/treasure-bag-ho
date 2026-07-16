import { ToolStore } from '../../utils/ToolStore';

interface TodoItem {
  id: number;
  text: string;
  done: boolean;
}

const STORE_KEY = 'todos';

@Component
export struct TodoPage {
  @State items: TodoItem[] = [];
  @State input: string = '';

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    const saved = await ToolStore.get(ctx, STORE_KEY, '[]');
    try {
      this.items = JSON.parse(saved) as TodoItem[];
    } catch (err) {
      this.items = [];
    }
  }

  persist(): void {
    ToolStore.save(STORE_KEY, JSON.stringify(this.items));
  }

  add(): void {
    const text = this.input.trim();
    if (text.length === 0) {
      return;
    }
    const maxId = this.items.reduce((m, t) => Math.max(m, t.id), 0);
    this.items = [{ id: maxId + 1, text: text, done: false }, ...this.items];
    this.input = '';
    this.persist();
  }

  toggle(id: number): void {
    this.items = this.items.map((t): TodoItem =>
      t.id === id ? { id: t.id, text: t.text, done: !t.done } : t);
    this.persist();
  }

  remove(id: number): void {
    this.items = this.items.filter(t => t.id !== id);
    this.persist();
  }

  remaining(): number {
    return this.items.filter(t => !t.done).length;
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Row({ space: 10 }) {
          TextInput({ placeholder: '要做点什么？', text: this.input })
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

        if (this.items.length > 0) {
          Text(`还剩 ${this.remaining()} 件未完成`)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .alignSelf(ItemAlign.Start)
        }

        List({ space: 8 }) {
          ForEach(this.items, (item: TodoItem) => {
            ListItem() {
              Row({ space: 12 }) {
                Text(item.done ? '✅' : '⭕')
                  .fontSize(20)
                  .onClick(() => this.toggle(item.id))
                Text(item.text)
                  .fontSize(15)
                  .fontColor(item.done ? $r('app.color.text_secondary') : $r('app.color.text_primary'))
                  .decoration({ type: item.done ? TextDecorationType.LineThrough : TextDecorationType.None })
                  .layoutWeight(1)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text('🗑️')
                  .fontSize(16)
                  .opacity(0.6)
                  .onClick(() => this.remove(item.id))
              }
              .width('100%')
              .padding(14)
              .borderRadius(14)
              .backgroundColor($r('app.color.bg_card'))
            }
            .transition(TransitionEffect.OPACITY.animation({ duration: 200 }))
          }, (item: TodoItem) => `${item.id}-${item.done}`)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        if (this.items.length === 0) {
          Column({ space: 8 }) {
            Text('📝').fontSize(48)
            Text('暂无待办，添加一件吧')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
          .margin({ bottom: 100 })
        }
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('待办事项')
    .backgroundColor($r('app.color.bg_page'))
  }
}
