import { sensor } from '@kit.SensorServiceKit';

@Component
export struct LevelPage {
  @State angleX: number = 0; // 左右倾斜角
  @State angleY: number = 0; // 前后倾斜角
  @State available: boolean = true;

  aboutToAppear(): void {
    try {
      sensor.on(sensor.SensorId.GRAVITY, (data: sensor.GravityResponse) => {
        // 重力分量换算倾角
        const g = 9.81;
        this.angleX = Math.asin(Math.max(-1, Math.min(1, data.x / g))) * 180 / Math.PI;
        this.angleY = Math.asin(Math.max(-1, Math.min(1, data.y / g))) * 180 / Math.PI;
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

  isLevel(): boolean {
    return Math.abs(this.angleX) < 1 && Math.abs(this.angleY) < 1;
  }

  build() {
    NavDestination() {
      Column({ space: 30 }) {
        Blank()

        if (this.available) {
          // 气泡水平仪
          Stack() {
            // 外圈
            Column()
              .width(280).height(280).borderRadius(140)
              .backgroundColor($r('app.color.bg_card'))
              .border({ width: 2, color: this.isLevel() ? '#43E97B' : '#33888888' })
            // 中心十字准星
            Column().width(60).height(1).backgroundColor('#66888888')
            Column().width(1).height(60).backgroundColor('#66888888')
            Column().width(24).height(24).borderRadius(12)
              .border({ width: 1.5, color: '#88888888' })
            // 气泡（角度→位移，限制在盘内）
            Column()
              .width(40).height(40).borderRadius(20)
              .linearGradient({
                angle: 135,
                colors: this.isLevel() ? [['#43E97B', 0], ['#38F9D7', 1]] : [['#5B6BF5', 0], ['#7B88FF', 1]]
              })
              .shadow({ radius: 10, color: this.isLevel() ? '#43E97B88' : '#5B6BF588' })
              .translate({
                x: Math.max(-115, Math.min(115, -this.angleX * 4)),
                y: Math.max(-115, Math.min(115, this.angleY * 4))
              })
              .animation({ duration: 80, curve: Curve.Linear })
          }
          .width(280).height(280)

          Row({ space: 30 }) {
            Column({ space: 4 }) {
              Text('左右').fontSize(13).fontColor($r('app.color.text_secondary'))
              Text(`${this.angleX.toFixed(1)}°`)
                .fontSize(26).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
            }
            Column({ space: 4 }) {
              Text('前后').fontSize(13).fontColor($r('app.color.text_secondary'))
              Text(`${this.angleY.toFixed(1)}°`)
                .fontSize(26).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
            }
          }

          Text(this.isLevel() ? '✅ 水平！' : '将手机平放于被测表面')
            .fontSize(15)
            .fontWeight(this.isLevel() ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.isLevel() ? '#43E97B' : $r('app.color.text_secondary'))
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
    .title('水平仪')
    .backgroundColor($r('app.color.bg_page'))
  }
}
