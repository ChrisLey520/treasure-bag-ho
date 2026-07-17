let storageSchedule = new LocalStorage();

/**
 * 课程表服务卡片（2×4）：今日课程列表（节次时间 + 课程 + 地点）。
 * 数据由 EntryFormAbility 从 preferences（schedule）按今天+当前周+单双周过滤下发，
 * 每日 00:05 定时刷新；条目扁平字段 c0-3 下发。
 */
@Entry(storageSchedule)
@Component
struct ScheduleCard {
  @LocalStorageProp('weekText') weekText: string = '';
  @LocalStorageProp('t0') t0: string = '';   // 节次时间，如 "1-2节"
  @LocalStorageProp('c0') c0: string = '';   // 课程名
  @LocalStorageProp('r0') r0: string = '';   // 地点
  @LocalStorageProp('t1') t1: string = '';
  @LocalStorageProp('c1') c1: string = '';
  @LocalStorageProp('r1') r1: string = '';
  @LocalStorageProp('t2') t2: string = '';
  @LocalStorageProp('c2') c2: string = '';
  @LocalStorageProp('r2') r2: string = '';
  @LocalStorageProp('t3') t3: string = '';
  @LocalStorageProp('c3') c3: string = '';
  @LocalStorageProp('r3') r3: string = '';
  @LocalStorageProp('more') more: number = 0;

  private timeAt(i: number): string {
    if (i === 0) { return this.t0; }
    if (i === 1) { return this.t1; }
    if (i === 2) { return this.t2; }
    return this.t3;
  }

  private nameAt(i: number): string {
    if (i === 0) { return this.c0; }
    if (i === 1) { return this.c1; }
    if (i === 2) { return this.c2; }
    return this.c3;
  }

  private roomAt(i: number): string {
    if (i === 0) { return this.r0; }
    if (i === 1) { return this.r1; }
    if (i === 2) { return this.r2; }
    return this.r3;
  }

  @Builder
  courseRow(i: number) {
    Row({ space: 8 }) {
      Text(this.timeAt(i))
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor('#7B88FF')
        .width(38)
      Text(this.nameAt(i))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
      if (this.roomAt(i).length > 0) {
        Text(this.roomAt(i))
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }

  build() {
    Column({ space: 4 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('📚')
          .fontSize(12)
        Text('今日课程')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        if (this.weekText.length > 0) {
          Text(this.weekText)
            .fontSize(9)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .width('100%')

      if (this.c0.length === 0) {
        Blank()
        Column({ space: 4 }) {
          Text('🎉 今天没有课')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text('点击查看完整课表')
            .fontSize(10)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        Blank()
      } else {
        Column({ space: 0 }) {
          this.courseRow(0)
          if (this.c1.length > 0) {
            this.courseRow(1)
          }
          if (this.c2.length > 0) {
            this.courseRow(2)
          }
          if (this.c3.length > 0) {
            this.courseRow(3)
          }
          if (this.more > 0) {
            Text(`还有 ${this.more} 节…`)
              .fontSize(9)
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 2 })
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
        params: { targetTool: 'schedule' }
      });
    })
  }
}
