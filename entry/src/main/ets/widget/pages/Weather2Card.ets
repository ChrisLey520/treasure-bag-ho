let storageWeather2 = new LocalStorage();

/**
 * 双城天气服务卡片（2×4）：两个城市并排展示。
 * 城市 A 与 WeatherPage/单城卡共用 weather_city，城市 B 用 weather_city2
 * （卡片上点 B 城名可在常用城市间轮换）。
 * 数据由 ExtraFormAbility 并发拉取 Open-Meteo 下发。
 */
@Entry(storageWeather2)
@Component
struct Weather2Card {
  @LocalStorageProp('cityA') cityA: string = '';
  @LocalStorageProp('tempA') tempA: string = '';
  @LocalStorageProp('descA') descA: string = '';
  @LocalStorageProp('rangeA') rangeA: string = '';
  @LocalStorageProp('cityB') cityB: string = '';
  @LocalStorageProp('tempB') tempB: string = '';
  @LocalStorageProp('descB') descB: string = '';
  @LocalStorageProp('rangeB') rangeB: string = '';
  @LocalStorageProp('updated') updated: string = '';

  private cityAt(i: number): string {
    return i === 0 ? this.cityA : this.cityB;
  }

  private tempAt(i: number): string {
    return i === 0 ? this.tempA : this.tempB;
  }

  private descAt(i: number): string {
    return i === 0 ? this.descA : this.descB;
  }

  private rangeAt(i: number): string {
    return i === 0 ? this.rangeA : this.rangeB;
  }

  /** 单城面板 */
  @Builder
  cityPanel(i: number) {
    Column({ space: 2 }) {
      Text(this.cityAt(i).length > 0 ? this.cityAt(i) : (i === 0 ? '城市一' : '城市二'))
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CCFFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.tempAt(i).length > 0) {
        Row() {
          Text(this.tempAt(i))
            .fontSize(32)
            .fontWeight(FontWeight.Bolder)
            .fontColor(Color.White)
          Text('°C')
            .fontSize(12)
            .fontColor('#CCFFFFFF')
            .margin({ top: 5 })
        }
        .alignItems(VerticalAlign.Top)

        Text(this.descAt(i))
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#EEFFFFFF')
          .maxLines(1)

        if (this.rangeAt(i).length > 0) {
          Text(this.rangeAt(i))
            .fontSize(9)
            .fontColor('#B3FFFFFF')
        }
      } else {
        Text('🌦️')
          .fontSize(22)
        Text('等待刷新…')
          .fontSize(9)
          .fontColor('#B3FFFFFF')
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(8)
    .layoutWeight(1)
    .height('100%')
    .borderRadius(12)
    .backgroundColor('#1AFFFFFF')
  }

  build() {
    Column({ space: 6 }) {
      // 品牌行
      Row({ space: 5 }) {
        Text('🌤️')
          .fontSize(12)
        Text('双城天气')
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#CCFFFFFF')
        Blank()
        if (this.updated.length > 0) {
          Text(this.updated)
            .fontSize(9)
            .fontColor('#B3FFFFFF')
        }
      }
      .width('100%')

      Row({ space: 8 }) {
        this.cityPanel(0)
        this.cityPanel(1)
      }
      .width('100%')
      .layoutWeight(1)
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
