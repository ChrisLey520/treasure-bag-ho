import { formBindingData, FormExtensionAbility, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { buildTodayCourses, TodayInfo } from '../utils/ScheduleCardData';

const PREF_NAME = 'treasure_bag_tools';
const KEY_FORM_PREFIX = 'card_type_';

const WEEK_NAMES: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

interface BigScheduleCardData {
  weekText: string;
  dayText: string;
  count: number;
  s0: string; e0: string; c0: string; r0: string; p0: string; k0: string;
  s1: string; e1: string; c1: string; r1: string; p1: string; k1: string;
  s2: string; e2: string; c2: string; r2: string; p2: string; k2: string;
  s3: string; e3: string; c3: string; r3: string; p3: string; k3: string;
  s4: string; e4: string; c4: string; r4: string; p4: string; k4: string;
  s5: string; e5: string; c5: string; r5: string; p5: string; k5: string;
  s6: string; e6: string; c6: string; r6: string; p6: string; k6: string;
  s7: string; e7: string; c7: string; r7: string; p7: string; k7: string;
}

/**
 * 第二形态卡片 Ability：单个 FormExtensionAbility 最多 16 张卡，
 * 超出部分挂在这里：硬币骰子、彩虹屁（纯本地）+ 今日课程大卡（数据）。
 */
export default class ExtraFormAbility extends FormExtensionAbility {
  private getPref(): preferences.Preferences {
    return preferences.getPreferencesSync(this.context, { name: PREF_NAME });
  }

  private bigScheduleData(pref: preferences.Preferences): BigScheduleCardData {
    const info: TodayInfo = buildTodayCourses(pref);
    const d = new Date();
    const at = (i: number, field: number): string => {
      if (i >= info.courses.length) {
        return field === 5 ? '#4FACFE' : '';
      }
      const c = info.courses[i];
      if (field === 0) { return c.start; }
      if (field === 1) { return c.end; }
      if (field === 2) { return c.name; }
      if (field === 3) { return c.room; }
      if (field === 4) { return c.teacher; }
      return c.color;
    };
    return {
      weekText: info.weekText,
      dayText: WEEK_NAMES[d.getDay()],
      count: Math.min(info.courses.length, 8),
      s0: at(0, 0), e0: at(0, 1), c0: at(0, 2), r0: at(0, 3), p0: at(0, 4), k0: at(0, 5),
      s1: at(1, 0), e1: at(1, 1), c1: at(1, 2), r1: at(1, 3), p1: at(1, 4), k1: at(1, 5),
      s2: at(2, 0), e2: at(2, 1), c2: at(2, 2), r2: at(2, 3), p2: at(2, 4), k2: at(2, 5),
      s3: at(3, 0), e3: at(3, 1), c3: at(3, 2), r3: at(3, 3), p3: at(3, 4), k3: at(3, 5),
      s4: at(4, 0), e4: at(4, 1), c4: at(4, 2), r4: at(4, 3), p4: at(4, 4), k4: at(4, 5),
      s5: at(5, 0), e5: at(5, 1), c5: at(5, 2), r5: at(5, 3), p5: at(5, 4), k5: at(5, 5),
      s6: at(6, 0), e6: at(6, 1), c6: at(6, 2), r6: at(6, 3), p6: at(6, 4), k6: at(6, 5),
      s7: at(7, 0), e7: at(7, 1), c7: at(7, 2), r7: at(7, 3), p7: at(7, 4), k7: at(7, 5)
    };
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const formName = want.parameters?.['ohos.extra.param.key.form_name'] as string;
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    if (formName === 'widget_schedule_big') {
      const pref = this.getPref();
      if (formId !== undefined) {
        pref.putSync(`${KEY_FORM_PREFIX}${formId}`, formName);
        pref.flush();
      }
      return formBindingData.createFormBindingData(this.bigScheduleData(pref));
    }
    // 纯本地状态卡片（硬币骰子/彩虹屁），无需绑定数据
    return formBindingData.createFormBindingData({});
  }

  onRemoveForm(formId: string): void {
    const pref = this.getPref();
    pref.deleteSync(`${KEY_FORM_PREFIX}${formId}`);
    pref.flush();
  }

  onUpdateForm(formId: string): void {
    const pref = this.getPref();
    const cardType = pref.getSync(`${KEY_FORM_PREFIX}${formId}`, '') as string;
    if (cardType === 'widget_schedule_big') {
      formProvider.updateForm(formId, formBindingData.createFormBindingData(this.bigScheduleData(pref)))
        .catch((err: Error) => console.error('updateForm failed:', err.message));
    }
  }
}
