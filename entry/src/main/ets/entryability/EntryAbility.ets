import { UIAbility } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  private windowClass?: window.Window;

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
