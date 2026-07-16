import { HttpUtil } from '../../utils/HttpUtil';

interface GeoResult {
  name: string;
  latitude: number;
  longitude: number;
  admin1?: string;
}

interface GeoResponse {
  results?: GeoResult[];
}

interface CurrentWeather {
  temperature_2m: number;
  relative_humidity_2m: number;
  apparent_temperature: number;
  weather_code: number;
  wind_speed_10m: number;
}

interface DailyWeather {
  time: string[];
  weather_code: number[];
  temperature_2m_max: number[];
  temperature_2m_min: number[];
}

interface WeatherResponse {
  current?: CurrentWeather;
  daily?: DailyWeather;
}

const WMO_CODES: Record<string, string> = {
  '0': '☀️ 晴', '1': '🌤️ 大部晴朗', '2': '⛅ 多云', '3': '☁️ 阴',
  '45': '🌫️ 雾', '48': '🌫️ 冻雾',
  '51': '🌦️ 毛毛雨', '53': '🌦️ 小雨', '55': '🌧️ 中雨',
  '61': '🌧️ 小雨', '63': '🌧️ 中雨', '65': '🌧️ 大雨',
  '66': '🌨️ 冻雨', '67': '🌨️ 强冻雨',
  '71': '🌨️ 小雪', '73': '🌨️ 中雪', '75': '❄️ 大雪', '77': '❄️ 雪粒',
  '80': '🌦️ 阵雨', '81': '🌧️ 强阵雨', '82': '⛈️ 暴雨',
  '85': '🌨️ 阵雪', '86': '❄️ 强阵雪',
  '95': '⛈️ 雷暴', '96': '⛈️ 雷暴冰雹', '99': '⛈️ 强雷暴冰雹'
};

function wmoText(code: number): string {
  return WMO_CODES[code.toString()] ?? `未知 (${code})`;
}

@Component
export struct WeatherPage {
  @State city: string = '北京';
  @State cityShown: string = '';
  @State current?: CurrentWeather = undefined;
  @State daily?: DailyWeather = undefined;
  @State loading: boolean = false;
  @State error: string = '';

  async query(): Promise<void> {
    const city = this.city.trim();
    if (city.length === 0 || this.loading) {
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      // 1. 城市名 → 经纬度（Open-Meteo 地理编码，免 key）
      const geoText = await HttpUtil.getText(
        `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(city)}&count=1&language=zh`);
      if (geoText === undefined) {
        this.error = '网络请求失败，请检查网络';
        this.loading = false;
        return;
      }
      const geo = JSON.parse(geoText) as GeoResponse;
      if (geo.results === undefined || geo.results.length === 0) {
        this.error = `未找到城市「${city}」`;
        this.loading = false;
        return;
      }
      const loc = geo.results[0];
      // 2. 经纬度 → 天气（Open-Meteo 预报，免 key）
      const wxText = await HttpUtil.getText(
        `https://api.open-meteo.com/v1/forecast?latitude=${loc.latitude}&longitude=${loc.longitude}` +
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m' +
        '&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=7');
      if (wxText === undefined) {
        this.error = '天气数据获取失败';
        this.loading = false;
        return;
      }
      const wx = JSON.parse(wxText) as WeatherResponse;
      this.current = wx.current;
      this.daily = wx.daily;
      this.cityShown = loc.admin1 !== undefined && loc.admin1 !== loc.name ? `${loc.admin1} · ${loc.name}` : loc.name;
    } catch (err) {
      this.error = '数据解析失败';
      console.error('weather failed:', JSON.stringify(err));
    }
    this.loading = false;
  }

  weekdayOf(dateStr: string): string {
    const names: string[] = ['日', '一', '二', '三', '四', '五', '六'];
    const parts = dateStr.split('-');
    const d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
    return '周' + names[d.getDay()];
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 14 }) {
          Row({ space: 10 }) {
            TextInput({ placeholder: '输入城市名，如：上海', text: this.city })
              .layoutWeight(1)
              .height(46)
              .borderRadius(14)
              .backgroundColor($r('app.color.bg_card'))
              .fontColor($r('app.color.text_primary'))
              .onChange((v: string) => { this.city = v; })
              .onSubmit(() => this.query())
            Button(this.loading ? '…' : '查询')
              .height(46)
              .backgroundColor($r('app.color.accent'))
              .enabled(!this.loading)
              .onClick(() => this.query())
          }
          .width('100%')

          if (this.error.length > 0) {
            Text(this.error)
              .fontSize(13).fontColor('#F5576C')
              .width('100%').padding(12)
              .borderRadius(10).backgroundColor('#1AF5576C')
          }

          if (this.current !== undefined) {
            Column({ space: 8 }) {
              Text(this.cityShown).fontSize(15).fontColor('#CCFFFFFF')
              Text(`${Math.round(this.current.temperature_2m)}°`)
                .fontSize(64).fontWeight(FontWeight.Bold).fontColor(Color.White)
              Text(wmoText(this.current.weather_code))
                .fontSize(17).fontColor(Color.White)
              Row({ space: 20 }) {
                Text(`体感 ${Math.round(this.current.apparent_temperature)}°`)
                  .fontSize(13).fontColor('#CCFFFFFF')
                Text(`湿度 ${this.current.relative_humidity_2m}%`)
                  .fontSize(13).fontColor('#CCFFFFFF')
                Text(`风速 ${this.current.wind_speed_10m} km/h`)
                  .fontSize(13).fontColor('#CCFFFFFF')
              }
            }
            .width('100%')
            .padding(28)
            .borderRadius(24)
            .linearGradient({ angle: 160, colors: [['#4FACFE', 0], ['#00F2FE', 1]] })
            .shadow({ radius: 16, color: '#4FACFE55', offsetY: 6 })
          }

          if (this.daily !== undefined) {
            Column({ space: 2 }) {
              ForEach(this.daily.time, (day: string, i: number) => {
                Row() {
                  Text(i === 0 ? '今天' : this.weekdayOf(day))
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                    .width(56)
                  Text(wmoText(this.daily!.weather_code[i]))
                    .fontSize(14)
                    .fontColor($r('app.color.text_secondary'))
                    .layoutWeight(1)
                  Text(`${Math.round(this.daily!.temperature_2m_min[i])}° / ${Math.round(this.daily!.temperature_2m_max[i])}°`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                }
                .width('100%')
                .padding({ top: 12, bottom: 12, left: 16, right: 16 })
              }, (day: string) => day)
            }
            .width('100%')
            .borderRadius(16)
            .backgroundColor($r('app.color.bg_card'))
          }

          if (this.current === undefined && this.error.length === 0) {
            Column({ space: 8 }) {
              Text('🌤️').fontSize(56)
              Text('输入城市查询 7 日天气\n数据来源 Open-Meteo（免费开源）')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .textAlign(TextAlign.Center)
                .lineHeight(22)
            }
            .margin({ top: 80 })
          }
        }
        .padding(20)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('天气查询')
    .backgroundColor($r('app.color.bg_page'))
  }
}
