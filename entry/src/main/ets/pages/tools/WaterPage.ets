import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { ToolStore } from '../../utils/ToolStore';

interface WaterData {
  date: string;       // 'YYYY-MM-DD'
  cups: number;
  goal: number;
  intervalMin: number;
  reminderOn: boolean;
}

const STORE_KEY = 'water';

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
}

@Component
export struct WaterPage {
  @State cups: number = 0;
  @State goal: number = 8;
  @State intervalMin: number = 60;
  @State reminderOn: boolean = false;
  @State ripple: boolean = false;
  private reminderId: number = -1;

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    const saved = await ToolStore.get(ctx, STORE_KEY, '');
    if (saved.length > 0) {
      try {
        const data = JSON.parse(saved) as WaterData;
        this.goal = data.goal;
        this.intervalMin = data.intervalMin;
        this.reminderOn = data.reminderOn;
        // 跨天清零
        this.cups = data.date === todayStr() ? data.cups : 0;
      } catch (err) {
        console.error('parse water data failed:', JSON.stringify(err));
      }
    }
  }

  persist(): void {
    const data: WaterData = {
      date: todayStr(),
      cups: this.cups,
      goal: this.goal,
      intervalMin: this.intervalMin,
      reminderOn: this.reminderOn
    };
    ToolStore.save(STORE_KEY, JSON.stringify(data));
  }

  drink(): void {
    this.cups += 1;
    this.ripple = !this.ripple;
    this.persist();
    if (this.reminderOn) {
      // 喝完一杯重新计时
      this.scheduleNext();
    }
    if (this.cups === this.goal) {
      this.getUIContext().getPromptAction().showToast({
        message: '🎉 今日目标达成！继续保持',
        duration: 2000
      });
    }
  }

  async scheduleNext(): Promise<void> {
    await this.cancelReminder();
    try {
      const reminder: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: this.intervalMin * 60,
        title: '💧 该喝水啦',
        content: `今天已喝 ${this.cups}/${this.goal} 杯，起来喝一杯吧`,
        notificationId: 10001,
        slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION
      };
      this.reminderId = await reminderAgentManager.publishReminder(reminder);
    } catch (err) {
      console.error('publish reminder failed:', JSON.stringify(err));
      this.getUIContext().getPromptAction().showToast({
        message: '提醒设置失败，请在设置中允许本应用通知',
        duration: 2000
      });
      this.reminderOn = false;
      this.persist();
    }
  }

  async cancelReminder(): Promise<void> {
    if (this.reminderId >= 0) {
      try {
        await reminderAgentManager.cancelReminder(this.reminderId);
      } catch (err) {
        console.error('cancel reminder failed:', JSON.stringify(err));
      }
      this.reminderId = -1;
    }
  }

  async toggleReminder(on: boolean): Promise<void> {
    this.reminderOn = on;
    if (on) {
      // 首次需要申请通知授权
      try {
        await notificationManager.requestEnableNotification();
      } catch (err) {
        console.error('notification not granted:', JSON.stringify(err));
      }
      await this.scheduleNext();
    } else {
      await this.cancelReminder();
    }
    this.persist();
  }

  progress(): number {
    return Math.min(100, this.cups / this.goal * 100);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          // 进度环 + 打卡
          Stack() {
            Progress({ value: this.progress(), total: 100, type: ProgressType.Ring })
              .width(220).height(220)
              .style({ strokeWidth: 16 })
              .color('#4FACFE')

            Column({ space: 4 }) {
              Text('💧')
                .fontSize(44)
                .scale({ x: this.ripple ? 1.2 : 1, y: this.ripple ? 1.2 : 1 })
                .animation({ duration: 300, curve: Curve.EaseOut })
              Text(`${this.cups} / ${this.goal}`)
                .fontSize(30)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              Text('今日杯数')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
            }
          }
          .margin({ top: 10 })

          Button('+1 杯（约 250ml）')
            .width(220).height(54)
            .fontSize(17).fontWeight(FontWeight.Bold)
            .linearGradient({ angle: 135, colors: [['#4FACFE', 0], ['#00F2FE', 1]] })
            .onClick(() => this.drink())

          if (this.cups > 0) {
            Text('喝多了？点我 -1')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .onClick(() => {
                this.cups = Math.max(0, this.cups - 1);
                this.persist();
              })
          }

          // 目标设置
          Column({ space: 6 }) {
            Row() {
              Text('每日目标').fontSize(14).fontColor($r('app.color.text_secondary'))
              Blank()
              Text(`${this.goal} 杯`).fontSize(14).fontColor($r('app.color.text_primary'))
            }.width('100%')
            Slider({ value: this.goal, min: 4, max: 16, step: 1 })
              .onChange((v: number) => {
                this.goal = v;
                this.persist();
              })
          }
          .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))

          // 定时提醒
          Column({ space: 10 }) {
            Row() {
              Column({ space: 2 }) {
                Text('喝水提醒').fontSize(15).fontColor($r('app.color.text_primary'))
                Text('通过系统通知提醒，喝一杯后自动续上')
                  .fontSize(11).fontColor($r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.reminderOn })
                .selectedColor('#4FACFE')
                .onChange((v: boolean) => this.toggleReminder(v))
            }
            .width('100%')

            if (this.reminderOn) {
              Row() {
                Text('提醒间隔').fontSize(14).fontColor($r('app.color.text_secondary'))
                Blank()
                Text(`${this.intervalMin} 分钟`).fontSize(14).fontColor($r('app.color.text_primary'))
              }.width('100%')
              Slider({ value: this.intervalMin, min: 30, max: 180, step: 15 })
                .onChange((v: number, mode: SliderChangeMode) => {
                  this.intervalMin = v;
                  this.persist();
                  if (mode === SliderChangeMode.End && this.reminderOn) {
                    this.scheduleNext();
                  }
                })
            }
          }
          .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))
        }
        .padding(20)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('喝水提醒')
    .backgroundColor($r('app.color.bg_page'))
  }
}
