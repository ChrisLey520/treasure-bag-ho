let storageWeather = new LocalStorage();

/**
 * 天气服务卡片（2×2）：城市 + 当前温度 + 天气 + 今日范围。
 * 数据由 EntryFormAbility 拉取 Open-Meteo（onUpdateForm 异步刷新），
 * 城市偏好与 WeatherPage 共用 preferences（weather_city）。
 */
@Entry(storageWeather)
@Component
struct WeatherCard {
  @LocalStorageProp('city') city: string = '';
  @LocalStorageProp('temp') temp: string = '';
  @LocalStorageProp('desc') desc: string = '';
  @LocalStorageProp('range') range: string = '';
  @LocalStorageProp('updated') updated: string = '';

  build() {
    Column({ space: 4 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('🌤️')
          .fontSize(12)
        Text(this.city.length > 0 ? this.city : '天气')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        if (this.updated.length > 0) {
          Text(this.updated)
            .fontSize(9)
            .fontColor('#B3FFFFFF')
        }
      }
      .width('100%')

      Blank()

      if (this.temp.length > 0) {
        Row() {
          Text(this.temp)
            .fontSize(42)
            .fontWeight(FontWeight.Bolder)
            .fontColor(Color.White)
          Text('°C')
            .fontSize(15)
            .fontColor('#CCFFFFFF')
            .margin({ top: 8 })
        }
        .alignItems(VerticalAlign.Top)

        Text(this.desc)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#EEFFFFFF')

        if (this.range.length > 0) {
          Text(this.range)
            .fontSize(10)
            .fontColor('#B3FFFFFF')
        }
      } else {
        Column({ space: 4 }) {
          Text('🌦️')
            .fontSize(30)
          Text('等待刷新…')
            .fontSize(11)
            .fontColor('#CCFFFFFF')
          Text('点击进 App 查询')
            .fontSize(9)
            .fontColor('#B3FFFFFF')
        }
        .alignItems(HorizontalAlign.Center)
      }

      Blank()
    }
    .padding(12)
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 135, colors: [['#2980B9', 0], ['#6DD5FA', 1]] })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: { targetTool: 'weather' }
      });
    })
  }
}
