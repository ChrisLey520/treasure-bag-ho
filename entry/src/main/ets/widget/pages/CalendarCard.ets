import { LunarDate, solarToLunar } from '../../utils/Lunar';

let storageCalendar = new LocalStorage();

const WEEK_NAMES: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

/**
 * 万年历服务卡片（2×2）：今天大数字 + 星期 + 农历 + 干支生肖。
 * 纯本地计算，每日 00:05 由系统定时刷新触发重渲染。
 */
@Entry(storageCalendar)
@Component
struct CalendarCard {
  @LocalStorageProp('stamp') stamp: number = 0;   // 每日刷新信号（数据无实义）

  private lunarText(): string {
    const l = solarToLunar(new Date());
    return l !== undefined ? l.text : '';
  }

  private ganzhiText(): string {
    const l = solarToLunar(new Date());
    return l !== undefined ? `${l.ganzhi}${l.zodiac}年` : '';
  }

  build() {
    Column({ space: 2 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('🗓️')
          .fontSize(12)
        Text('万年历')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
        Blank()
        Text(`${new Date().getMonth() + 1} 月`)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#CCFFFFFF')
      }
      .width('100%')

      Blank()

      Text(new Date().getDate().toString())
        .fontSize(52)
        .fontWeight(FontWeight.Bolder)
        .fontColor(Color.White)

      Text(WEEK_NAMES[new Date().getDay()])
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#EEFFFFFF')

      if (this.lunarText().length > 0) {
        Text(this.lunarText())
          .fontSize(11)
          .fontColor('#CCFFFFFF')
        Text(this.ganzhiText())
          .fontSize(10)
          .fontColor('#B3FFFFFF')
      }

      Blank()
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#C33764', 0], ['#1D2671', 1]] })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetTool: 'calendar' }
      });
    })
  }
}
