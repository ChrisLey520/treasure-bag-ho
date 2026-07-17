let storageScheduleBig = new LocalStorage();

/**
 * 今日课程大卡（4×4）：今天全部课程时间线，对齐 App 内课程块样式
 * （课程色块 + 起止时刻 + 课程/地点/教师）。
 * 数据由 ExtraFormAbility 下发（扁平字段最多 8 条）。
 */
@Entry(storageScheduleBig)
@Component
struct ScheduleBigCard {
  @LocalStorageProp('weekText') weekText: string = '';
  @LocalStorageProp('dayText') dayText: string = '';
  @LocalStorageProp('count') count: number = 0;
  @LocalStorageProp('s0') s0: string = '';
  @LocalStorageProp('e0') e0: string = '';
  @LocalStorageProp('c0') c0: string = '';
  @LocalStorageProp('r0') r0: string = '';
  @LocalStorageProp('p0') p0: string = '';
  @LocalStorageProp('k0') k0: string = '#4FACFE';
  @LocalStorageProp('s1') s1: string = '';
  @LocalStorageProp('e1') e1: string = '';
  @LocalStorageProp('c1') c1: string = '';
  @LocalStorageProp('r1') r1: string = '';
  @LocalStorageProp('p1') p1: string = '';
  @LocalStorageProp('k1') k1: string = '#4FACFE';
  @LocalStorageProp('s2') s2: string = '';
  @LocalStorageProp('e2') e2: string = '';
  @LocalStorageProp('c2') c2: string = '';
  @LocalStorageProp('r2') r2: string = '';
  @LocalStorageProp('p2') p2: string = '';
  @LocalStorageProp('k2') k2: string = '#4FACFE';
  @LocalStorageProp('s3') s3: string = '';
  @LocalStorageProp('e3') e3: string = '';
  @LocalStorageProp('c3') c3: string = '';
  @LocalStorageProp('r3') r3: string = '';
  @LocalStorageProp('p3') p3: string = '';
  @LocalStorageProp('k3') k3: string = '#4FACFE';
  @LocalStorageProp('s4') s4: string = '';
  @LocalStorageProp('e4') e4: string = '';
  @LocalStorageProp('c4') c4: string = '';
  @LocalStorageProp('r4') r4: string = '';
  @LocalStorageProp('p4') p4: string = '';
  @LocalStorageProp('k4') k4: string = '#4FACFE';
  @LocalStorageProp('s5') s5: string = '';
  @LocalStorageProp('e5') e5: string = '';
  @LocalStorageProp('c5') c5: string = '';
  @LocalStorageProp('r5') r5: string = '';
  @LocalStorageProp('p5') p5: string = '';
  @LocalStorageProp('k5') k5: string = '#4FACFE';
  @LocalStorageProp('s6') s6: string = '';
  @LocalStorageProp('e6') e6: string = '';
  @LocalStorageProp('c6') c6: string = '';
  @LocalStorageProp('r6') r6: string = '';
  @LocalStorageProp('p6') p6: string = '';
  @LocalStorageProp('k6') k6: string = '#4FACFE';
  @LocalStorageProp('s7') s7: string = '';
  @LocalStorageProp('e7') e7: string = '';
  @LocalStorageProp('c7') c7: string = '';
  @LocalStorageProp('r7') r7: string = '';
  @LocalStorageProp('p7') p7: string = '';
  @LocalStorageProp('k7') k7: string = '#4FACFE';

  private startAt(i: number): string {
    const arr: string[] = [this.s0, this.s1, this.s2, this.s3, this.s4, this.s5, this.s6, this.s7];
    return arr[i];
  }

  private endAt(i: number): string {
    const arr: string[] = [this.e0, this.e1, this.e2, this.e3, this.e4, this.e5, this.e6, this.e7];
    return arr[i];
  }

  private nameAt(i: number): string {
    const arr: string[] = [this.c0, this.c1, this.c2, this.c3, this.c4, this.c5, this.c6, this.c7];
    return arr[i];
  }

  private roomAt(i: number): string {
    const arr: string[] = [this.r0, this.r1, this.r2, this.r3, this.r4, this.r5, this.r6, this.r7];
    return arr[i];
  }

  private teacherAt(i: number): string {
    const arr: string[] = [this.p0, this.p1, this.p2, this.p3, this.p4, this.p5, this.p6, this.p7];
    return arr[i];
  }

  private colorAt(i: number): string {
    const arr: string[] = [this.k0, this.k1, this.k2, this.k3, this.k4, this.k5, this.k6, this.k7];
    return arr[i];
  }

  /** 课程行：左时间轴 + 课程色块（对齐 App 内课程块样式） */
  @Builder
  courseRow(i: number) {
    Row({ space: 8 }) {
      // 时间轴
      Column({ space: 1 }) {
        Text(this.startAt(i))
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        if (this.endAt(i).length > 0) {
          Text(this.endAt(i))
            .fontSize(9)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .alignItems(HorizontalAlign.End)
      .width(40)

      // 课程色块
      Column({ space: 2 }) {
        Text(this.nameAt(i))
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 6 }) {
          if (this.roomAt(i).length > 0) {
            Text(`@${this.roomAt(i)}`)
              .fontSize(10)
              .fontColor('#E6FFFFFF')
              .maxLines(1)
          }
          if (this.teacherAt(i).length > 0) {
            Text(this.teacherAt(i))
              .fontSize(10)
              .fontColor('#CCFFFFFF')
              .maxLines(1)
          }
        }
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .layoutWeight(1)
      .borderRadius(10)
      .backgroundColor(this.colorAt(i))
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: 3, bottom: 3 })
  }

  build() {
    Column({ space: 6 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('📚')
          .fontSize(14)
        Text('今日课程')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        if (this.dayText.length > 0) {
          Text(this.dayText)
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
        }
        Blank()
        if (this.weekText.length > 0) {
          Text(this.weekText)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('#7B88FF')
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(8)
            .backgroundColor('#1A7B88FF')
        }
      }
      .width('100%')

      if (this.count === 0) {
        Blank()
        Column({ space: 6 }) {
          Text('🎉')
            .fontSize(40)
          Text('今天没有课')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text('好好休息，点击查看完整课表')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        Blank()
      } else {
        // 全天课程时间线（4×4 高度约可容 8 行）
        List({ space: 0 }) {
          ListItem() {
            Column({ space: 0 }) {
              if (this.count > 0) {
                this.courseRow(0)
              }
              if (this.count > 1) {
                this.courseRow(1)
              }
              if (this.count > 2) {
                this.courseRow(2)
              }
              if (this.count > 3) {
                this.courseRow(3)
              }
              if (this.count > 4) {
                this.courseRow(4)
              }
              if (this.count > 5) {
                this.courseRow(5)
              }
              if (this.count > 6) {
                this.courseRow(6)
              }
              if (this.count > 7) {
                this.courseRow(7)
              }
            }
            .width('100%')
          }
        }
        .layoutWeight(1)
        .width('100%')
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .padding(14)
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
