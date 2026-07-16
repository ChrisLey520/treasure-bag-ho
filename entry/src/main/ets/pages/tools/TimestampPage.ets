@Component
export struct TimestampPage {
  @State tsInput: string = '';
  @State dateInput: string = '';
  @State nowTs: number = Math.floor(Date.now() / 1000);
  private timerId: number = -1;

  aboutToAppear(): void {
    this.timerId = setInterval(() => {
      this.nowTs = Math.floor(Date.now() / 1000);
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
    }
  }

  fmt(ms: number): string {
    const d = new Date(ms);
    if (isNaN(d.getTime())) {
      return '—';
    }
    const p = (n: number): string => n.toString().padStart(2, '0');
    return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`;
  }

  tsToDate(): string {
    const v = parseInt(this.tsInput.trim());
    if (isNaN(v)) {
      return '—';
    }
    // 10 位按秒，13 位按毫秒
    return this.fmt(this.tsInput.trim().length > 10 ? v : v * 1000);
  }

  dateToTs(): string {
    const d = new Date(this.dateInput.trim().replace(' ', 'T'));
    if (isNaN(d.getTime())) {
      return '—';
    }
    return Math.floor(d.getTime() / 1000).toString();
  }

  @Builder
  resultRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(14).fontColor($r('app.color.text_secondary')).width(90)
      Text(value)
        .fontSize(16).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1).textAlign(TextAlign.End)
        .copyOption(CopyOptions.LocalDevice)
    }
    .width('100%').padding(16).borderRadius(14)
    .backgroundColor($r('app.color.bg_card'))
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 14 }) {
          Column({ space: 4 }) {
            Text('当前时间戳（秒）').fontSize(13).fontColor('#CCFFFFFF')
            Text(this.nowTs.toString())
              .fontSize(32).fontWeight(FontWeight.Bold).fontColor(Color.White)
              .copyOption(CopyOptions.LocalDevice)
            Text(this.fmt(this.nowTs * 1000)).fontSize(13).fontColor('#CCFFFFFF')
          }
          .width('100%').padding(20).borderRadius(20)
          .linearGradient({ angle: 135, colors: [['#A8EDEA', 0], ['#5B6BF5', 1]] })

          Text('时间戳 → 日期').fontSize(14).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
          TextInput({ placeholder: '输入 10 位或 13 位时间戳', text: this.tsInput })
            .type(InputType.Number)
            .height(48).borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onChange((v: string) => { this.tsInput = v; })
          this.resultRow('日期', this.tsToDate())

          Text('日期 → 时间戳').fontSize(14).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
          TextInput({ placeholder: '如 2026-07-15 20:00:00', text: this.dateInput })
            .height(48).borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onChange((v: string) => { this.dateInput = v; })
          this.resultRow('时间戳（秒）', this.dateToTs())
        }
        .padding(20)
      }
      .width('100%').height('100%')
      .scrollBar(BarState.Off)
    }
    .title('时间戳转换')
    .backgroundColor($r('app.color.bg_page'))
  }
}
