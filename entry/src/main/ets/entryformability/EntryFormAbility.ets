import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { HttpUtil } from '../utils/HttpUtil';
import { fetchCityWeather } from '../utils/WeatherFetch';

const FOCUS_MINUTES = 25;
const PREF_NAME = 'treasure_bag_tools';
const KEY_CARD_END = 'focus_card_end';   // 卡片专注结束时间戳
const KEY_FOCUS = 'focus';               // rounds|date（与 FocusPage 共用）
const KEY_WATER = 'water';               // 与 WaterPage 共用的 JSON
const KEY_ANNI = 'anniversaries';        // 与 AnniversaryPage 共用的 JSON 数组
const KEY_HABITS = 'habits';             // 与 HabitPage 共用的 JSON 数组
const KEY_TODOS = 'todos';               // 与 TodoPage 共用的 JSON 数组
const KEY_WOODFISH = 'woodfish';         // 与 WoodFishPage 共用 total|date|today
const KEY_LEDGER = 'ledger';             // 与 LedgerPage 共用的 JSON 数组
const KEY_SCHEDULE = 'schedule';         // 与 SchedulePage 共用的 JSON
const KEY_FORM_PREFIX = 'card_type_';    // formId → formName 映射（数据类卡片刷新时区分）
/** 数据类卡片（添加时记录类型、onUpdateForm 按类型刷新） */
const DATA_CARDS: string[] = ['widget_water', 'widget_anniversary',
  'widget_habit', 'widget_todo', 'widget_woodfish', 'widget_ledger', 'widget_calendar', 'widget_schedule'];
/** 网络卡片（onUpdateForm 异步拉取后回推） */
const NET_CARDS: string[] = ['widget_weather', 'widget_news'];

interface CardData {
  running: boolean;
  endText: string;
}

interface WaterData {
  date: string;
  cups: number;
  goal: number;
  intervalMin: number;
  reminderOn: boolean;
}

interface WaterCardData {
  cups: number;
  goal: number;
}

interface Anniversary {
  id: number;
  name: string;
  date: string;
}

interface AnniCardData {
  name: string;
  dayText: string;
  dateText: string;
}

interface Habit {
  id: number;
  name: string;
  emoji: string;
  dates: string[];
}

interface HabitCardData {
  name: string;
  emoji: string;
  streak: number;
  doneToday: boolean;
}

interface TodoItem {
  id: number;
  text: string;
  done: boolean;
}

interface TodoCardData {
  id0: number;
  text0: string;
  id1: number;
  text1: string;
  id2: number;
  text2: string;
  id3: number;
  text3: string;
  remain: number;
}

interface WoodfishCardData {
  today: number;
  total: number;
}

interface LedgerRecord {
  id: number;
  amount: number;
  note: string;
  category: string;
  date: string;
}

interface LedgerCardData {
  expense: string;
  income: string;
  monthText: string;
}

interface StampData {
  stamp: number;
}

interface SchedCourseBase {
  id: number;
  courseName: string;
}

interface SchedCourseDetail {
  id: number;
  day: number;
  room: string;
  startNode: number;
  step: number;
  startWeek: number;
  endWeek: number;
  type: number;
}

interface SchedTable {
  startDate: string;
  maxWeek: number;
}

interface SchedData {
  table: SchedTable;
  courses: SchedCourseBase[];
  details: SchedCourseDetail[];
  times?: string[][];
}

interface ScheduleCardData {
  weekText: string;
  t0: string;
  c0: string;
  r0: string;
  t1: string;
  c1: string;
  r1: string;
  t2: string;
  c2: string;
  r2: string;
  t3: string;
  c3: string;
  r3: string;
  more: number;
}

interface WeatherCardData {
  city: string;
  temp: string;
  desc: string;
  range: string;
  updated: string;
}

interface NewsCardData {
  date: string;
  n0: string;
  n1: string;
  n2: string;
  n3: string;
}

interface NewsData {
  news?: string[];
  date?: string;
}

interface NewsResponse {
  data?: NewsData;
}

function fmtHm(ts: number): string {
  const d = new Date(ts);
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}

function todayStrPadded(): string {
  const d = new Date();
  return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
}

function daysBetween(dateStr: string): number {
  const parts = dateStr.split('-');
  const target = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  return Math.round((target.getTime() - today.getTime()) / 86400000);
}

/** 连续打卡天数（与 HabitPage.streak 同构） */
function habitStreak(dates: string[]): number {
  if (dates.length === 0) {
    return 0;
  }
  const set = new Set<string>(dates);
  let count = 0;
  const cursor = new Date();
  const fmt = (d: Date): string =>
    `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
  if (!set.has(fmt(cursor))) {
    cursor.setDate(cursor.getDate() - 1);
  }
  while (set.has(fmt(cursor))) {
    count += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return count;
}

/** 金额展示：整数不带小数，最长保留 2 位 */
function fmtAmount(v: number): string {
  const r = Math.round(v * 100) / 100;
  return Number.isInteger(r) ? r.toString() : r.toFixed(2);
}

export default class EntryFormAbility extends FormExtensionAbility {
  private getPref(): preferences.Preferences {
    return preferences.getPreferencesSync(this.context, { name: PREF_NAME });
  }

  private bind(data: CardData): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(data);
  }

  // ── 喝水卡片数据 ──
  private waterData(pref: preferences.Preferences): WaterCardData {
    const saved = pref.getSync(KEY_WATER, '') as string;
    let cups = 0;
    let goal = 8;
    if (saved.length > 0) {
      try {
        const data = JSON.parse(saved) as WaterData;
        goal = data.goal;
        cups = data.date === todayStrPadded() ? data.cups : 0;   // 跨天清零
      } catch (err) {
        console.error('parse water failed:', JSON.stringify(err));
      }
    }
    return { cups: cups, goal: goal };
  }

  // ── 纪念日卡片数据：取最近的一条（未来最近优先，否则最近过去） ──
  private anniData(pref: preferences.Preferences): AnniCardData {
    const saved = pref.getSync(KEY_ANNI, '[]') as string;
    let items: Anniversary[] = [];
    try {
      items = JSON.parse(saved) as Anniversary[];
    } catch (err) {
      items = [];
    }
    if (items.length === 0) {
      return { name: '', dayText: '', dateText: '' };
    }
    let best = items[0];
    let bestScore = Number.MAX_VALUE;
    for (const a of items) {
      const diff = daysBetween(a.date);
      // 未来（含今天）按天数排序优先；过去的排在所有未来之后、按距今近排序
      const score = diff >= 0 ? diff : 100000 - diff;
      if (score < bestScore) {
        bestScore = score;
        best = a;
      }
    }
    const diff = daysBetween(best.date);
    const dayText = diff === 0 ? '就是今天 🎉' : (diff > 0 ? `还有 ${diff} 天` : `已经 ${-diff} 天`);
    return { name: best.name, dayText: dayText, dateText: best.date };
  }

  // ── 习惯卡片数据：取第一个习惯 ──
  private habitData(pref: preferences.Preferences): HabitCardData {
    const saved = pref.getSync(KEY_HABITS, '[]') as string;
    let habits: Habit[] = [];
    try {
      habits = JSON.parse(saved) as Habit[];
    } catch (err) {
      habits = [];
    }
    if (habits.length === 0) {
      return { name: '', emoji: '🌱', streak: 0, doneToday: false };
    }
    const h = habits[0];
    return {
      name: h.name,
      emoji: h.emoji,
      streak: habitStreak(h.dates),
      doneToday: h.dates.includes(todayStrPadded())
    };
  }

  // ── 待办卡片数据：前 4 条未完成（扁平字段下发） ──
  private todoData(pref: preferences.Preferences): TodoCardData {
    const saved = pref.getSync(KEY_TODOS, '[]') as string;
    let items: TodoItem[] = [];
    try {
      items = JSON.parse(saved) as TodoItem[];
    } catch (err) {
      items = [];
    }
    const pending = items.filter((t: TodoItem): boolean => !t.done);
    const top = pending.slice(0, 4);
    return {
      id0: top.length > 0 ? top[0].id : -1,
      text0: top.length > 0 ? top[0].text : '',
      id1: top.length > 1 ? top[1].id : -1,
      text1: top.length > 1 ? top[1].text : '',
      id2: top.length > 2 ? top[2].id : -1,
      text2: top.length > 2 ? top[2].text : '',
      id3: top.length > 3 ? top[3].id : -1,
      text3: top.length > 3 ? top[3].text : '',
      remain: pending.length
    };
  }

  // ── 木鱼卡片数据 ──
  private woodfishData(pref: preferences.Preferences): WoodfishCardData {
    const saved = pref.getSync(KEY_WOODFISH, '') as string;
    let total = 0;
    let today = 0;
    if (saved.length > 0) {
      const parts = saved.split('|'); // total|date|today
      total = parseInt(parts[0]) || 0;
      today = (parts[1] ?? '') === todayStr() ? (parseInt(parts[2]) || 0) : 0;
    }
    return { today: today, total: total };
  }

  // ── 记账卡片数据：本月支出/收入汇总 ──
  private ledgerData(pref: preferences.Preferences): LedgerCardData {
    const saved = pref.getSync(KEY_LEDGER, '[]') as string;
    let records: LedgerRecord[] = [];
    try {
      records = JSON.parse(saved) as LedgerRecord[];
    } catch (err) {
      records = [];
    }
    const d = new Date();
    const monthPrefix = `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}`;
    let expense = 0;
    let income = 0;
    for (const r of records) {
      if (r.date.startsWith(monthPrefix)) {
        if (r.amount < 0) {
          expense += -r.amount;
        } else {
          income += r.amount;
        }
      }
    }
    return {
      expense: fmtAmount(expense),
      income: fmtAmount(income),
      monthText: `${d.getMonth() + 1} 月`
    };
  }

  // ── 今日课程卡片数据：今天 + 当前周 + 单双周过滤，按节次排序取前 4 ──
  private scheduleData(pref: preferences.Preferences): ScheduleCardData {
    const empty: ScheduleCardData = {
      weekText: '', t0: '', c0: '', r0: '', t1: '', c1: '', r1: '',
      t2: '', c2: '', r2: '', t3: '', c3: '', r3: '', more: 0
    };
    const saved = pref.getSync(KEY_SCHEDULE, '') as string;
    if (saved.length === 0) {
      return empty;
    }
    let data: SchedData | undefined = undefined;
    try {
      data = JSON.parse(saved) as SchedData;
    } catch (err) {
      return empty;
    }
    // 当前周
    const parts = data.table.startDate.split('-');
    const start = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const week = Math.max(1, Math.min(data.table.maxWeek,
      Math.floor(Math.floor((today.getTime() - start.getTime()) / 86400000) / 7) + 1));
    const weekday = now.getDay() === 0 ? 7 : now.getDay();
    // 今天该上的课
    const nameOf = (id: number): string => {
      for (const c of data!.courses) {
        if (c.id === id) {
          return c.courseName;
        }
      }
      return '';
    };
    const todays: SchedCourseDetail[] = [];
    for (const dt of data.details) {
      if (dt.day !== weekday || week < dt.startWeek || week > dt.endWeek) {
        continue;
      }
      if (dt.type === 1 && week % 2 === 0) {
        continue;
      }
      if (dt.type === 2 && week % 2 === 1) {
        continue;
      }
      todays.push(dt);
    }
    todays.sort((a: SchedCourseDetail, b: SchedCourseDetail): number => a.startNode - b.startNode);
    const top = todays.slice(0, 4);
    // 有作息则显示上课时刻，否则显示节次
    const times = data.times ?? [];
    const timeStr = (dt: SchedCourseDetail): string => {
      if (dt.startNode - 1 < times.length && times[dt.startNode - 1].length === 2) {
        return times[dt.startNode - 1][0];
      }
      return dt.step > 1 ? `${dt.startNode}-${dt.startNode + dt.step - 1}节` : `${dt.startNode}节`;
    };
    return {
      weekText: `第${week}周 ${week % 2 === 1 ? '单' : '双'}`,
      t0: top.length > 0 ? timeStr(top[0]) : '',
      c0: top.length > 0 ? nameOf(top[0].id) : '',
      r0: top.length > 0 ? top[0].room : '',
      t1: top.length > 1 ? timeStr(top[1]) : '',
      c1: top.length > 1 ? nameOf(top[1].id) : '',
      r1: top.length > 1 ? top[1].room : '',
      t2: top.length > 2 ? timeStr(top[2]) : '',
      c2: top.length > 2 ? nameOf(top[2].id) : '',
      r2: top.length > 2 ? top[2].room : '',
      t3: top.length > 3 ? timeStr(top[3]) : '',
      c3: top.length > 3 ? nameOf(top[3].id) : '',
      r3: top.length > 3 ? top[3].room : '',
      more: Math.max(0, todays.length - 4)
    };
  }

  /** 数据类卡片按类型组装数据 */
  private dataFor(formName: string, pref: preferences.Preferences): formBindingData.FormBindingData {
    if (formName === 'widget_water') {
      return formBindingData.createFormBindingData(this.waterData(pref));
    }
    if (formName === 'widget_anniversary') {
      return formBindingData.createFormBindingData(this.anniData(pref));
    }
    if (formName === 'widget_habit') {
      return formBindingData.createFormBindingData(this.habitData(pref));
    }
    if (formName === 'widget_todo') {
      return formBindingData.createFormBindingData(this.todoData(pref));
    }
    if (formName === 'widget_woodfish') {
      return formBindingData.createFormBindingData(this.woodfishData(pref));
    }
    if (formName === 'widget_calendar') {
      // 万年历卡片自算日期，仅推刷新信号触发重渲染
      return formBindingData.createFormBindingData({ stamp: Date.now() } as StampData);
    }
    if (formName === 'widget_schedule') {
      return formBindingData.createFormBindingData(this.scheduleData(pref));
    }
    return formBindingData.createFormBindingData(this.ledgerData(pref));
  }

  /** 天气卡片：城市偏好 → Open-Meteo 两跳请求（失败静默保留旧数据） */
  private async fetchWeather(pref: preferences.Preferences): Promise<WeatherCardData | undefined> {
    const city = (pref.getSync('weather_city', '北京') as string).trim();
    const w = await fetchCityWeather(city);
    if (w === undefined) {
      return undefined;
    }
    const d = new Date();
    return {
      city: w.city,
      temp: w.temp,
      desc: w.desc,
      range: w.range,
      updated: `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`
    };
  }

  /** 早报卡片：60s API 前 4 条标题 */
  private async fetchNews(): Promise<NewsCardData | undefined> {
    const text = await HttpUtil.getText('https://60s.viki.moe/v2/60s', 8000);
    if (text === undefined) {
      return undefined;
    }
    try {
      const parsed = JSON.parse(text) as NewsResponse;
      const news = parsed.data?.news ?? [];
      if (news.length === 0) {
        return undefined;
      }
      return {
        date: parsed.data?.date ?? '',
        n0: news.length > 0 ? news[0] : '',
        n1: news.length > 1 ? news[1] : '',
        n2: news.length > 2 ? news[2] : '',
        n3: news.length > 3 ? news[3] : ''
      };
    } catch (err) {
      console.error('fetch news failed:', JSON.stringify(err));
      return undefined;
    }
  }

  /** 网络卡片刷新：异步拉取成功才回推（失败保留卡面旧数据） */
  private refreshNetCard(formId: string, formName: string, pref: preferences.Preferences): void {
    if (formName === 'widget_weather') {
      this.fetchWeather(pref).then((data: WeatherCardData | undefined): void => {
        if (data !== undefined) {
          formProvider.updateForm(formId, formBindingData.createFormBindingData(data))
            .catch((err: Error) => console.error('updateForm failed:', err.message));
        }
      });
      return;
    }
    this.fetchNews().then((data: NewsCardData | undefined): void => {
      if (data !== undefined) {
        formProvider.updateForm(formId, formBindingData.createFormBindingData(data))
          .catch((err: Error) => console.error('updateForm failed:', err.message));
      }
    });
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const formName = want.parameters?.['ohos.extra.param.key.form_name'] as string;
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    const pref = this.getPref();
    // 记录 formId → 卡片类型（定时刷新时区分数据类/网络类卡片）
    if (formId !== undefined && (DATA_CARDS.includes(formName) || NET_CARDS.includes(formName))) {
      pref.putSync(`${KEY_FORM_PREFIX}${formId}`, formName);
      pref.flush();
    }
    // 纯本地状态卡片：空数据
    if (formName === 'widget_calc' || formName === 'widget_supercalc' ||
      formName === 'widget_answer' || formName === 'widget_decision' || formName === 'widget_score' ||
      formName === 'widget_coindice' || formName === 'widget_rainbow') {
      return formBindingData.createFormBindingData({});
    }
    if (DATA_CARDS.includes(formName)) {
      return this.dataFor(formName, pref);
    }
    if (NET_CARDS.includes(formName)) {
      // 网络卡片：先返回占位，异步拉取后回推
      if (formId !== undefined) {
        this.refreshNetCard(formId, formName, pref);
      }
      return formBindingData.createFormBindingData({});
    }
    // 专注卡片：添加时恢复进行中的专注（若有）
    const endTs = pref.getSync(KEY_CARD_END, 0) as number;
    if (endTs > Date.now()) {
      return this.bind({ running: true, endText: fmtHm(endTs) });
    }
    return this.bind({ running: false, endText: '' });
  }

  onRemoveForm(formId: string): void {
    const pref = this.getPref();
    pref.deleteSync(`${KEY_FORM_PREFIX}${formId}`);
    pref.flush();
  }

  onFormEvent(formId: string, message: string): void {
    let action = '';
    let todoId = '';
    try {
      const msg = JSON.parse(message) as Record<string, string>;
      action = (msg.action as string) ?? '';
      todoId = (msg.todoId as string) ?? '';
    } catch (err) {
      console.error('parse card message failed:', JSON.stringify(err));
      return;
    }
    const pref = this.getPref();

    if (action === 'start') {
      const endTs = Date.now() + FOCUS_MINUTES * 60 * 1000;
      pref.putSync(KEY_CARD_END, endTs);
      pref.flush();
      formProvider.updateForm(formId, this.bind({ running: true, endText: fmtHm(endTs) }))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
      // 到点后系统拉起 onUpdateForm 结算（系统最短刷新间隔 5 分钟，25 分钟满足）
      formProvider.setFormNextRefreshTime(formId, FOCUS_MINUTES)
        .catch((err: Error) => console.error('setNextRefresh failed:', err.message));
    } else if (action === 'stop') {
      pref.putSync(KEY_CARD_END, 0);
      pref.flush();
      formProvider.updateForm(formId, this.bind({ running: false, endText: '' }))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
    } else if (action === 'drink') {
      // 喝水打卡：读取 → 跨天清零 → +1 → 落库（与 App 内同一存储）→ 回推
      const saved = pref.getSync(KEY_WATER, '') as string;
      let data: WaterData = { date: todayStrPadded(), cups: 0, goal: 8, intervalMin: 60, reminderOn: false };
      if (saved.length > 0) {
        try {
          data = JSON.parse(saved) as WaterData;
        } catch (err) {
          console.error('parse water failed:', JSON.stringify(err));
        }
      }
      if (data.date !== todayStrPadded()) {
        data.date = todayStrPadded();
        data.cups = 0;
      }
      data.cups += 1;
      pref.putSync(KEY_WATER, JSON.stringify(data));
      pref.flush();
      formProvider.updateForm(formId,
        formBindingData.createFormBindingData({ cups: data.cups, goal: data.goal } as WaterCardData))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
    } else if (action === 'habitCheckIn') {
      // 第一个习惯打卡（与 HabitPage 同库；已打则不重复）
      const saved = pref.getSync(KEY_HABITS, '[]') as string;
      let habits: Habit[] = [];
      try {
        habits = JSON.parse(saved) as Habit[];
      } catch (err) {
        habits = [];
      }
      if (habits.length > 0) {
        const today = todayStrPadded();
        if (!habits[0].dates.includes(today)) {
          habits[0].dates.push(today);
          pref.putSync(KEY_HABITS, JSON.stringify(habits));
          pref.flush();
        }
      }
      formProvider.updateForm(formId, formBindingData.createFormBindingData(this.habitData(pref)))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
    } else if (action === 'todoDone') {
      // 勾选完成一条待办
      const saved = pref.getSync(KEY_TODOS, '[]') as string;
      let items: TodoItem[] = [];
      try {
        items = JSON.parse(saved) as TodoItem[];
      } catch (err) {
        items = [];
      }
      const id = parseInt(todoId);
      items = items.map((t: TodoItem): TodoItem =>
        t.id === id ? { id: t.id, text: t.text, done: true } as TodoItem : t);
      pref.putSync(KEY_TODOS, JSON.stringify(items));
      pref.flush();
      formProvider.updateForm(formId, formBindingData.createFormBindingData(this.todoData(pref)))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
    } else if (action === 'knock') {
      // 木鱼功德 +1（与 WoodFishPage 同库：total|date|today）
      const saved = pref.getSync(KEY_WOODFISH, '') as string;
      let total = 0;
      let today = 0;
      if (saved.length > 0) {
        const parts = saved.split('|');
        total = parseInt(parts[0]) || 0;
        today = (parts[1] ?? '') === todayStr() ? (parseInt(parts[2]) || 0) : 0;
      }
      total += 1;
      today += 1;
      pref.putSync(KEY_WOODFISH, `${total}|${todayStr()}|${today}`);
      pref.flush();
      formProvider.updateForm(formId,
        formBindingData.createFormBindingData({ today: today, total: total } as WoodfishCardData))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
    }
  }

  onUpdateForm(formId: string): void {
    const pref = this.getPref();
    // 数据/网络类卡片：按记录的类型刷新
    const cardType = pref.getSync(`${KEY_FORM_PREFIX}${formId}`, '') as string;
    if (DATA_CARDS.includes(cardType)) {
      formProvider.updateForm(formId, this.dataFor(cardType, pref))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
      return;
    }
    if (NET_CARDS.includes(cardType)) {
      this.refreshNetCard(formId, cardType, pref);
      return;
    }
    // 专注卡片
    const endTs = pref.getSync(KEY_CARD_END, 0) as number;
    if (endTs > 0 && Date.now() >= endTs) {
      // 专注完成：累加今日轮次（与 App 内专注时钟共用记录）
      const saved = pref.getSync(KEY_FOCUS, '') as string;
      let rounds = 0;
      const parts = saved.split('|');
      if (parts.length === 2 && parts[1] === todayStr()) {
        rounds = parseInt(parts[0]) || 0;
      }
      pref.putSync(KEY_FOCUS, `${rounds + 1}|${todayStr()}`);
      pref.putSync(KEY_CARD_END, 0);
      pref.flush();
      formProvider.updateForm(formId, this.bind({ running: false, endText: '' }))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
    } else if (endTs > 0) {
      // 仍在专注中（例如系统提前刷新）
      formProvider.updateForm(formId, this.bind({ running: true, endText: fmtHm(endTs) }))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
    } else {
      formProvider.updateForm(formId, this.bind({ running: false, endText: '' }))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
    }
  }
}
