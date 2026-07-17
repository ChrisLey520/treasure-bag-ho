let storageTodo = new LocalStorage();

/**
 * 待办事项服务卡片（2×4）：展示前 4 条未完成待办，点圆圈完成。
 * 数据由 EntryFormAbility 与 TodoPage 共用 preferences（todos JSON）。
 * 卡片数据通道只支持基本类型：4 条以扁平字段下发（id/text × 4）。
 */
@Entry(storageTodo)
@Component
struct TodoCard {
  @LocalStorageProp('id0') id0: number = -1;
  @LocalStorageProp('text0') text0: string = '';
  @LocalStorageProp('id1') id1: number = -1;
  @LocalStorageProp('text1') text1: string = '';
  @LocalStorageProp('id2') id2: number = -1;
  @LocalStorageProp('text2') text2: string = '';
  @LocalStorageProp('id3') id3: number = -1;
  @LocalStorageProp('text3') text3: string = '';
  @LocalStorageProp('remain') remain: number = 0;

  private itemAt(i: number): string {
    if (i === 0) { return this.text0; }
    if (i === 1) { return this.text1; }
    if (i === 2) { return this.text2; }
    return this.text3;
  }

  private idAt(i: number): number {
    if (i === 0) { return this.id0; }
    if (i === 1) { return this.id1; }
    if (i === 2) { return this.id2; }
    return this.id3;
  }

  @Builder
  todoRow(i: number) {
    Row({ space: 8 }) {
      // 完成圆圈
      Text('')
        .width(16)
        .height(16)
        .borderRadius(8)
        .border({ width: 1.5, color: $r('app.color.text_secondary') })
        .onClick(() => {
          postCardAction(this, {
            action: 'message',
            params: { action: 'todoDone', todoId: this.idAt(i).toString() }
          });
        })
      Text(this.itemAt(i))
        .fontSize(12)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 5, bottom: 5 })
  }

  build() {
    Column({ space: 4 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('📝')
          .fontSize(12)
        Text('待办事项')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        if (this.remain > 0) {
          Text(`剩 ${this.remain} 项`)
            .fontSize(10)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .width('100%')

      if (this.id0 < 0) {
        Blank()
        Column({ space: 4 }) {
          Text('🎉 全部完成')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text('点击添加新待办')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        Blank()
      } else {
        Column({ space: 0 }) {
          this.todoRow(0)
          if (this.id1 >= 0) {
            this.todoRow(1)
          }
          if (this.id2 >= 0) {
            this.todoRow(2)
          }
          if (this.id3 >= 0) {
            this.todoRow(3)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Start)
      }
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetTool: 'todo' }
      });
    })
  }
}
