import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const FOCUS_MINUTES = 25;
const PREF_NAME = 'treasure_bag_tools';
const KEY_CARD_END = 'focus_card_end';   // 卡片专注结束时间戳
const KEY_FOCUS = 'focus';               // rounds|date（与 FocusPage 共用）

interface CardData {
  running: boolean;
  endText: string;
}

function fmtHm(ts: number): string {
  const d = new Date(ts);
  return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
}

export default class EntryFormAbility extends FormExtensionAbility {
  private getPref(): preferences.Preferences {
    return preferences.getPreferencesSync(this.context, { name: PREF_NAME });
  }

  private bind(data: CardData): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(data);
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    // 计算器/答案之书/随机决定类卡片纯本地状态，无需绑定数据
    const formName = want.parameters?.['ohos.extra.param.key.form_name'] as string;
    if (formName === 'widget_calc' || formName === 'widget_supercalc' ||
      formName === 'widget_answer' || formName === 'widget_decision') {
      return formBindingData.createFormBindingData({});
    }
    // 专注卡片：添加时恢复进行中的专注（若有）
    const pref = this.getPref();
    const endTs = pref.getSync(KEY_CARD_END, 0) as number;
    if (endTs > Date.now()) {
      return this.bind({ running: true, endText: fmtHm(endTs) });
    }
    return this.bind({ running: false, endText: '' });
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
    }
  }

  onUpdateForm(formId: string): void {
    const pref = this.getPref();
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
