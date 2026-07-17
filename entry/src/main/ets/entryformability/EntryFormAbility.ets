import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

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
const KEY_FORM_PREFIX = 'card_type_';    // formId → formName 映射（数据类卡片刷新时区分）
/** 数据类卡片（添加时记录类型、onUpdateForm 按类型刷新） */
const DATA_CARDS: string[] = ['widget_water', 'widget_anniversary',
  'widget_habit', 'widget_todo', 'widget_woodfish', 'widget_ledger', 'widget_calendar'];

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
    return formBindingData.createFormBindingData(this.ledgerData(pref));
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const formName = want.parameters?.['ohos.extra.param.key.form_name'] as string;
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    const pref = this.getPref();
    // 记录 formId → 卡片类型（定时刷新时区分数据类卡片）
    if (formId !== undefined && DATA_CARDS.includes(formName)) {
      pref.putSync(`${KEY_FORM_PREFIX}${formId}`, formName);
      pref.flush();
    }
    // 纯本地状态卡片：空数据
    if (formName === 'widget_calc' || formName === 'widget_supercalc' ||
      formName === 'widget_answer' || formName === 'widget_decision' || formName === 'widget_score') {
      return formBindingData.createFormBindingData({});
    }
    if (DATA_CARDS.includes(formName)) {
      return this.dataFor(formName, pref);
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
    // 数据类卡片：按记录的类型刷新
    const cardType = pref.getSync(`${KEY_FORM_PREFIX}${formId}`, '') as string;
    if (DATA_CARDS.includes(cardType)) {
      formProvider.updateForm(formId, this.dataFor(cardType, pref))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
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
