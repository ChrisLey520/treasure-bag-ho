import { display } from '@kit.ArkUI';

@Component
export struct RulerPage {
  @State pxPerMm: number = 0;
  @State markerMm: number = 30; // 拖动游标位置

  aboutToAppear(): void {
    try {
      const d = display.getDefaultDisplaySync();
      // densityDPI: 每英寸像素数；1 英寸 = 25.4mm
      this.pxPerMm = d.densityDPI / 25.4 / d.densityPixels; // vp per mm
    } catch (err) {
      console.error('display failed:', JSON.stringify(err));
      this.pxPerMm = 160 / 25.4 / 1; // 兜底
    }
  }

  build() {
    NavDestination() {
      Row() {
        // ── 左侧刻度尺（纵向，0-15cm）──
        Stack() {
          Column() {
            ForEach(Array.from<number, number>({ length: 151 }, (_: number, i: number) => i), (mm: number) => {
              Row() {
                Column()
                  .width(mm % 10 === 0 ? 34 : (mm % 5 === 0 ? 24 : 14))
                  .height(1)
                  .backgroundColor($r('app.color.text_primary'))
                if (mm % 10 === 0) {
                  Text(`${mm / 10}`)
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.text_primary'))
                    .margin({ left: 5 })
                }
              }
              .width('100%')
              .height(this.pxPerMm)
              .alignItems(VerticalAlign.Top)
            }, (mm: number) => mm.toString())
          }
          .alignItems(HorizontalAlign.Start)

          // 拖动游标线
          Row() {
            Column()
              .width('100%')
              .height(2)
              .backgroundColor('#F5576C')
          }
          .width('100%')
          .position({ y: this.markerMm * this.pxPerMm })
        }
        .layoutWeight(1)
        .height('100%')
        .gesture(PanGesture({ direction: PanDirection.Vertical })
          .onActionUpdate((event: GestureEvent) => {
            const mm = this.markerMm + event.offsetY / this.pxPerMm / 10;
            this.markerMm = Math.max(0, Math.min(150, mm));
          }))

        // ── 右侧读数 ──
        Column({ space: 8 }) {
          Text('游标读数')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
          Text(`${(this.markerMm / 10).toFixed(2)}`)
            .fontSize(44)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F5576C')
          Text('厘米')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Text(`${this.markerMm.toFixed(1)} mm`)
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
          Text('拖动屏幕移动红线')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 20 })
        }
        .width(130)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
    .title('屏幕直尺')
    .backgroundColor($r('app.color.bg_page'))
  }
}
