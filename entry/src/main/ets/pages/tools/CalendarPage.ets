import { LunarDate, solarToLunar } from '../../utils/Lunar';


@Component
export struct CalendarPage {
  @State selected: Date = new Date();

  lunar(): LunarDate | undefined {
    return solarToLunar(this.selected);
  }

  weekday(): string {
    const names: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    return '星期' + names[this.selected.getDay()];
  }

  dayOfYear(): number {
    const start = new Date(this.selected.getFullYear(), 0, 1);
    return Math.floor((this.selected.getTime() - start.getTime()) / 86400000) + 1;
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          // 农历卡片
          Column({ space: 8 }) {
            Text(`${this.selected.getFullYear()} 年 ${this.selected.getMonth() + 1} 月 ${this.selected.getDate()} 日 · ${this.weekday()}`)
              .fontSize(14)
              .fontColor('#CCFFFFFF')
            Text(this.lunar()?.text ?? '超出范围')
              .fontSize(38)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            if (this.lunar() !== undefined) {
              Text(`${this.lunar()!.ganzhi}年 · 属${this.lunar()!.zodiac} · 今年第 ${this.dayOfYear()} 天`)
                .fontSize(13)
                .fontColor('#CCFFFFFF')
            }
          }
          .width('100%')
          .padding(26)
          .borderRadius(20)
          .linearGradient({ angle: 135, colors: [['#C33764', 0], ['#1D2671', 1]] })
          .shadow({ radius: 16, color: '#C3376455', offsetY: 6 })

          // 日期选择
          Column({ space: 8 }) {
            Text('选择日期').fontSize(13).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
            DatePicker({ selected: this.selected, start: new Date('1900-02-01'), end: new Date('2100-12-31') })
              .onDateChange((value: Date) => {
                this.selected = value;
              })
              .height(180)
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))

          Button('回到今天')
            .width('100%')
            .height(48)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => {
              this.selected = new Date();
            })
        }
        .padding(20)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('万年历')
    .backgroundColor($r('app.color.bg_page'))
  }
}
