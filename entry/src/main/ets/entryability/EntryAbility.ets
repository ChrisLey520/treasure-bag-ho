import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

/** 解析服务卡片 router 带来的目标工具 id，存入 AppStorage 供 Index 消费 */
function saveTargetTool(want: Want): void {
  try {
    const raw = want.parameters?.params;
    if (typeof raw === 'string') {
      const params = JSON.parse(raw) as Record<string, string>;
      const target = params.targetTool as string;
      if (target !== undefined && target.length > 0) {
        AppStorage.setOrCreate('targetTool', target);
      }
    }
  } catch (err) {
    console.error('parse card params failed:', JSON.stringify(err));
  }
}

export default class EntryAbility extends UIAbility {
  private windowClass?: window.Window;

  onCreate(want: Want): void {
    saveTargetTool(want);
  }

  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    saveTargetTool(want);
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err) {
        return;
      }
      this.windowClass = windowStage.getMainWindowSync();
      this.windowClass.setWindowLayoutFullScreen(true);
    });
  }

  onDestroy(): void {
    this.windowClass = undefined;
  }
}
