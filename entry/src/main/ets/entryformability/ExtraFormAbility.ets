import { formBindingData, FormExtensionAbility } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

/**
 * 第二形态卡片 Ability：单个 FormExtensionAbility 最多 16 张卡，
 * 超出部分（纯本地状态卡：彩虹屁、硬币骰子）挂在这里。
 */
export default class ExtraFormAbility extends FormExtensionAbility {
  onAddForm(_want: Want): formBindingData.FormBindingData {
    // 纯本地状态卡片，无需绑定数据
    return formBindingData.createFormBindingData({});
  }
}
