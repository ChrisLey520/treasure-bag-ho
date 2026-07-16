import { sensor } from '@kit.SensorServiceKit';

const DIRECTIONS: string[] = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];

@Component
export struct CompassPage {
  @State degree: number = 0;
  @State available: boolean = true;

  aboutToAppear(): void {
    try {
      sensor.on(sensor.SensorId.ORIENTATION, (data: sensor.OrientationResponse) => {
        this.degree = data.alpha;
      }, { interval: 60000000 }); // 60ms
    } catch (err) {
      console.error('orientation sensor failed:', JSON.stringify(err));
      this.available = false;
    }
  }

  aboutToDisappear(): void {
    try {
      sensor.off(sensor.SensorId.ORIENTATION);
    } catch (err) {
      console.error('sensor off failed:', JSON.stringify(err));
    }
  }

  directionName(): string {
    const idx = Math.round(this.degree / 45) % 8;
    return DIRECTIONS[idx];
  }

  build() {
    NavDestination() {
      Column({ space: 30 }) {
        Blank()

        if (this.available) {
          // 表盘：刻度盘随方位反向旋转，指针固定朝上
          Stack() {
            // 刻度盘
            Stack() {
              ForEach([0, 45, 90, 135, 180, 225, 270, 315], (deg: number, i: number) => {
                Text(DIRECTIONS[i])
                  .fontSize(deg % 90 === 0 ? 22 : 14)
                  .fontWeight(deg % 90 === 0 ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(deg === 0 ? '#F5576C' : $r('app.color.text_primary'))
                  .position({ x: '50%', y: '50%' })
                  .markAnchor({ x: '50%', y: '50%' })
                  .translate({
                    x: Math.sin(deg * Math.PI / 180) * 110,
                    y: -Math.cos(deg * Math.PI / 180) * 110
                  })
              }, (deg: number) => deg.toString())
            }
            .width(280)
            .height(280)
            .borderRadius(140)
            .backgroundColor($r('app.color.bg_card'))
            .rotate({ angle: -this.degree })

            // 中心读数
            Column({ space: 2 }) {
              Text(`${Math.round(this.degree)}°`)
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              Text(this.directionName())
                .fontSize(18)
                .fontColor($r('app.color.accent'))
            }

            // 顶部指针
            Text('▼')
              .fontSize(24)
              .fontColor('#F5576C')
              .position({ x: '50%', y: 0 })
              .markAnchor({ x: '50%', y: '50%' })
          }
          .width(280)
          .height(280)

          Text('远离磁铁、金属物体以获得准确读数\n8 字晃动手机可校准')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .lineHeight(22)
        } else {
          Text('😢 当前设备不支持方向传感器\n（模拟器通常无此传感器，请用真机体验）')
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
    .title('指南针')
    .backgroundColor($r('app.color.bg_page'))
  }
}
