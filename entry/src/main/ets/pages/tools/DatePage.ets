@Component
export struct DatePage {
  @State startDate: Date = new Date();
  @State endDate: Date = new Date();

  diffDays(): number {
    const a = new Date(this.startDate.getFullYear(), this.startDate.getMonth(), this.startDate.getDate());
    const b = new Date(this.endDate.getFullYear(), this.endDate.getMonth(), this.endDate.getDate());
    return Math.round((b.getTime() - a.getTime()) / 86400000);
  }

  fmt(d: Date): string {
    return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
  }

  @Builder
  dateCard(label: string, date: Date, onSelect: (d: Date) => void) {
    Column({ space: 8 }) {
      Text(label).fontSize(13).fontColor($r('app.color.text_secondary'))
      Text(this.fmt(date))
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      DatePicker({ selected: date, start: new Date('1900-01-01'), end: new Date('2100-12-31') })
        .onDateChange((value: Date) => onSelect(value))
        .height(120)
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor($r('app.color.bg_card'))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          this.dateCard('起始日期', this.startDate, (d) => { this.startDate = d; })
          this.dateCard('结束日期', this.endDate, (d) => { this.endDate = d; })

          Column({ space: 6 }) {
            Text('相差天数').fontSize(13).fontColor('#CCFFFFFF')
            Text(`${Math.abs(this.diffDays())} 天`)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text(this.diffDays() >= 0 ? '结束日期在起始日期之后' : '结束日期在起始日期之前')
              .fontSize(12)
              .fontColor('#CCFFFFFF')
          }
          .width('100%')
          .padding(24)
          .borderRadius(20)
          .linearGradient({ angle: 135, colors: [['#43E97B', 0], ['#38F9D7', 1]] })
        }
        .padding(20)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('日期计算')
    .backgroundColor($r('app.color.bg_page'))
  }
}
