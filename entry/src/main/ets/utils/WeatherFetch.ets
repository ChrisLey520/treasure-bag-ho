import { HttpUtil } from './HttpUtil';

/**
 * 城市天气拉取（Open-Meteo 两跳：地理编码 → 预报，免 key）。
 * EntryFormAbility（单城卡）与 ExtraFormAbility（双城卡）共用。
 */

interface GeoResult {
  name: string;
  latitude: number;
  longitude: number;
}

interface GeoResponse {
  results?: GeoResult[];
}

interface WxCurrent {
  temperature_2m: number;
  weather_code: number;
}

interface WxDaily {
  temperature_2m_max: number[];
  temperature_2m_min: number[];
}

interface WxResponse {
  current?: WxCurrent;
  daily?: WxDaily;
}

export interface CityWeather {
  city: string;
  temp: string;
  desc: string;
  range: string;
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

export async function fetchCityWeather(city: string): Promise<CityWeather | undefined> {
  if (city.trim().length === 0) {
    return undefined;
  }
  const geoText = await HttpUtil.getText(
    `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(city.trim())}&count=1&language=zh`, 8000);
  if (geoText === undefined) {
    return undefined;
  }
  try {
    const geo = JSON.parse(geoText) as GeoResponse;
    if (geo.results === undefined || geo.results.length === 0) {
      return undefined;
    }
    const loc = geo.results[0];
    const wxText = await HttpUtil.getText(
      `https://api.open-meteo.com/v1/forecast?latitude=${loc.latitude}&longitude=${loc.longitude}` +
      '&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min' +
      '&timezone=auto&forecast_days=1', 8000);
    if (wxText === undefined) {
      return undefined;
    }
    const wx = JSON.parse(wxText) as WxResponse;
    if (wx.current === undefined) {
      return undefined;
    }
    let range = '';
    if (wx.daily !== undefined && wx.daily.temperature_2m_min.length > 0) {
      range = `${Math.round(wx.daily.temperature_2m_min[0])}° ~ ${Math.round(wx.daily.temperature_2m_max[0])}°`;
    }
    return {
      city: loc.name,
      temp: Math.round(wx.current.temperature_2m).toString(),
      desc: WMO_CODES[wx.current.weather_code.toString()] ?? '—',
      range: range
    };
  } catch (err) {
    console.error('fetch weather failed:', JSON.stringify(err));
    return undefined;
  }
}
