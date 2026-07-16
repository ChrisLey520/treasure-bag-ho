import { sensor } from '@kit.SensorServiceKit';

/**
 * 角度尺：手机竖立侧靠在被测面上，用重力分量算出手机绕屏幕法线的滚转角。
 */
@Component
export struct ProtractorPage {
  @State angle: number = 0;        // 0~180 显示角
  @State rawRoll: number = 0;      // -180~180
  @State available: boolean = true;
  @State locked: boolean = false;
  @State lockedAngle: number = 0;

  aboutToAppear(): void {
    try {
      sensor.on(sensor.SensorId.GRAVITY, (data: sensor.GravityResponse) => {
        if (this.locked) {
          return;
        }
        // 屏幕平面内的重力方向 → 滚转角
        const roll = Math.atan2(data.x, data.y) * 180 / Math.PI;
        this.rawRoll = roll;
        this.angle = Math.abs(roll);
      }, { interval: 60000000 });
    } catch (err) {
      console.error('gravity sensor failed:', JSON.stringify(err));
      this.available = false;
    }
  }

  aboutToDisappear(): void {
    try {
      sensor.off(sensor.SensorId.GRAVITY);
    } catch (err) {
      console.error('sensor off failed:', JSON.stringify(err));
    }
  }

  shownAngle(): number {
    return this.locked ? this.lockedAngle : this.angle;
  }

  build() {
    NavDestination() {
      Column({ space: 24 }) {
        Blank()

        if (this.available) {
          // 半圆量角器
          Stack() {
            // 外弧
            Column()
              .width(280).height(280).borderRadius(140)
              .backgroundColor($r('app.color.bg_card'))
              .clip(true)

            // 刻度文字
            ForEach([0, 30, 60, 90, 120, 150, 180], (deg: number) => {
              Text(`${deg}`)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .position({ x: '50%', y: '50%' })
                .markAnchor({ x: '50%', y: '50%' })
                .translate({
                  x: -Math.cos(deg * Math.PI / 180) * 115,
                  y: -Math.sin(deg * Math.PI / 180) * 115
                })
            }, (deg: number) => deg.toString())

            // 指针
            Column()
              .width(4)
              .height(120)
              .borderRadius(2)
              .linearGradient({ angle: 0, colors: [['#F5576C', 0], ['#F5576C88', 1]] })
              .markAnchor({ x: '50%', y: '100%' })
              .position({ x: '50%', y: '50%' })
              .rotate({ angle: this.locked ? (this.lockedAngle - 90) : (this.rawRoll > 0 ? this.angle - 90 : 90 - this.angle) })
              .animation({ duration: 80, curve: Curve.Linear })

            // 中心点
            Column()
              .width(14).height(14).borderRadius(7)
              .backgroundColor('#F5576C')
              .position({ x: '50%', y: '50%' })
              .markAnchor({ x: '50%', y: '50%' })
          }
          .width(280).height(280)

          Text(`${this.shownAngle().toFixed(1)}°`)
            .fontSize(52)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.locked ? '#F5576C' : $r('app.color.text_primary'))

          Button(this.locked ? '🔓 解除锁定' : '🔒 锁定读数')
            .width(180).height(48)
            .backgroundColor(this.locked ? '#F5576C' : $r('app.color.accent'))
            .onClick(() => {
              if (!this.locked) {
                this.lockedAngle = this.angle;
              }
              this.locked = !this.locked;
            })

          Text('将手机侧边紧贴被测角的一条边\n屏幕朝向自己，读取角度')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .lineHeight(22)
        } else {
          Text('😢 当前设备不支持重力传感器\n（模拟器通常无此传感器，请用真机体验）')
            .fontSize(15)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .lineHeight(26)
        }

        Blank()
        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('角度尺')
    .backgroundColor($r('app.color.bg_page'))
  }
}
