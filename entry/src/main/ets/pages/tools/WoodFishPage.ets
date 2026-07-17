import { vibrator } from '@kit.SensorServiceKit';
import { ToolStore } from '../../utils/ToolStore';
import { WoodfishIcon } from '../../components/WoodfishIcon';

const STORE_KEY = 'woodfish';

@Component
export struct WoodFishPage {
  @State total: number = 0;
  @State today: number = 0;
  @State todayDate: string = '';
  @State knocking: boolean = false;
  @State floatKey: number = 0;

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    const saved = await ToolStore.get(ctx, STORE_KEY, '');
    if (saved.length > 0) {
      try {
        const parts = saved.split('|'); // total|date|today
        this.total = parseInt(parts[0]) || 0;
        const date = parts[1] ?? '';
        const today = this.dateStr();
        this.today = date === today ? (parseInt(parts[2]) || 0) : 0;
      } catch (err) {
        console.error('parse woodfish failed:', JSON.stringify(err));
      }
    }
    this.todayDate = this.dateStr();
  }

  dateStr(): string {
    const d = new Date();
    return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
  }

  knock(): void {
    this.total += 1;
    this.today += 1;
    this.floatKey += 1;
    this.knocking = true;
    setTimeout(() => {
      this.knocking = false;
    }, 100);
    // 短振动反馈
    try {
      vibrator.startVibration({
        type: 'time',
        duration: 30
      }, {
        id: 0,
        usage: 'touch'
      });
    } catch (err) {
      console.error('vibrate failed:', JSON.stringify(err));
    }
    ToolStore.save(STORE_KEY, `${this.total}|${this.dateStr()}|${this.today}`);
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Row({ space: 30 }) {
          Column({ space: 4 }) {
            Text('今日功德')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.today}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D4AF37')
          }
          Column({ space: 4 }) {
            Text('累计功德')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.total}`)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          }
        }
        .margin({ top: 30 })

        Blank()

        Stack() {
          // 功德 +1 飘字
          if (this.floatKey > 0) {
            Text('功德 +1')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D4AF37')
              .transition(TransitionEffect.asymmetric(
                TransitionEffect.move(TransitionEdge.BOTTOM).combine(TransitionEffect.OPACITY)
                  .animation({ duration: 600, curve: Curve.EaseOut }),
                TransitionEffect.OPACITY.animation({ duration: 200 })
              ))
              .position({ x: '50%', y: 0 })
              .markAnchor({ x: '50%' })
              .id(`float${this.floatKey}`)
          }

          Column() {
            WoodfishIcon(130)
          }
          .scale({ x: this.knocking ? 0.92 : 1, y: this.knocking ? 0.92 : 1 })
          .animation({ duration: 80, curve: Curve.Sharp })
          .margin({ top: 40 })
        }
        .width(220)
        .height(240)
        .onClick(() => this.knock())

        Text('点击木鱼 · 功德 +1 · 烦恼 -1')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))

        Blank()
        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('电子木鱼')
    .backgroundColor($r('app.color.bg_page'))
  }
}
