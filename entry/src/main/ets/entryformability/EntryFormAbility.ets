import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const FOCUS_MINUTES = 25;
const PREF_NAME = 'treasure_bag_tools';
const KEY_CARD_END = 'focus_card_end';   // 卡片专注结束时间戳
const KEY_FOCUS = 'focus';               // rounds|date（与 FocusPage 共用）
const KEY_WATER = 'water';               // 与 WaterPage 共用的 JSON
const KEY_ANNI = 'anniversaries';        // 与 AnniversaryPage 共用的 JSON 数组
const KEY_FORM_PREFIX = 'card_type_';    // formId → formName 映射（数据类卡片刷新时区分）

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

  onAddForm(want: Want): formBindingData.FormBindingData {
    const formName = want.parameters?.['ohos.extra.param.key.form_name'] as string;
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    const pref = this.getPref();
    // 记录 formId → 卡片类型（定时刷新时区分数据类卡片）
    if (formId !== undefined && (formName === 'widget_water' || formName === 'widget_anniversary')) {
      pref.putSync(`${KEY_FORM_PREFIX}${formId}`, formName);
      pref.flush();
    }
    // 纯本地状态卡片：空数据
    if (formName === 'widget_calc' || formName === 'widget_supercalc' ||
      formName === 'widget_answer' || formName === 'widget_decision' || formName === 'widget_score') {
      return formBindingData.createFormBindingData({});
    }
    if (formName === 'widget_water') {
      return formBindingData.createFormBindingData(this.waterData(pref));
    }
    if (formName === 'widget_anniversary') {
      return formBindingData.createFormBindingData(this.anniData(pref));
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
    try {
      const msg = JSON.parse(message) as Record<string, string>;
      action = (msg.action as string) ?? '';
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
    }
  }

  onUpdateForm(formId: string): void {
    const pref = this.getPref();
    // 数据类卡片：按记录的类型刷新
    const cardType = pref.getSync(`${KEY_FORM_PREFIX}${formId}`, '') as string;
    if (cardType === 'widget_water') {
      formProvider.updateForm(formId, formBindingData.createFormBindingData(this.waterData(pref)))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
      return;
    }
    if (cardType === 'widget_anniversary') {
      formProvider.updateForm(formId, formBindingData.createFormBindingData(this.anniData(pref)))
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
