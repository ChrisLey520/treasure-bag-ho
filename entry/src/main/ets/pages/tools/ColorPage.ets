function hsbToRgb(h: number, s: number, b: number): number[] {
  const c = b * s;
  const x = c * (1 - Math.abs((h / 60) % 2 - 1));
  const m = b - c;
  let r = 0, g = 0, bl = 0;
  if (h < 60) { r = c; g = x; bl = 0; }
  else if (h < 120) { r = x; g = c; bl = 0; }
  else if (h < 180) { r = 0; g = c; bl = x; }
  else if (h < 240) { r = 0; g = x; bl = c; }
  else if (h < 300) { r = x; g = 0; bl = c; }
  else { r = c; g = 0; bl = x; }
  return [Math.round((r + m) * 255), Math.round((g + m) * 255), Math.round((bl + m) * 255)];
}

@Component
export struct ColorPage {
  @State hue: number = 220;
  @State sat: number = 80;
  @State bri: number = 90;

  rgb(): number[] {
    return hsbToRgb(this.hue, this.sat / 100, this.bri / 100);
  }

  hex(): string {
    const rgb = this.rgb();
    return '#' + rgb.map(v => v.toString(16).padStart(2, '0').toUpperCase()).join('');
  }

  @Builder
  sliderRow(label: string, value: number, max: number, onChange: (v: number) => void) {
    Column({ space: 4 }) {
      Row() {
        Text(label).fontSize(14).fontColor($r('app.color.text_secondary'))
        Blank()
        Text(value.toFixed(0)).fontSize(14).fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      Slider({ value: value, min: 0, max: max, style: SliderStyle.OutSet })
        .onChange((v: number) => onChange(v))
    }
  }

  build() {
    NavDestination() {
      Column({ space: 18 }) {
        Column()
          .width('100%')
          .height(140)
          .borderRadius(20)
          .backgroundColor(this.hex())
          .shadow({ radius: 16, color: this.hex() + '66', offsetY: 6 })

        Column({ space: 14 }) {
          this.sliderRow('色相 H', this.hue, 360, (v) => { this.hue = v; })
          this.sliderRow('饱和度 S', this.sat, 100, (v) => { this.sat = v; })
          this.sliderRow('亮度 B', this.bri, 100, (v) => { this.bri = v; })
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor($r('app.color.bg_card'))

        Row() {
          Text('HEX').fontSize(14).fontColor($r('app.color.text_secondary')).width(70)
          Text(this.hex())
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1).textAlign(TextAlign.End)
            .copyOption(CopyOptions.LocalDevice)
        }
        .width('100%').padding(16).borderRadius(14)
        .backgroundColor($r('app.color.bg_card'))

        Row() {
          Text('RGB').fontSize(14).fontColor($r('app.color.text_secondary')).width(70)
          Text(`rgb(${this.rgb().join(', ')})`)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1).textAlign(TextAlign.End)
            .copyOption(CopyOptions.LocalDevice)
        }
        .width('100%').padding(16).borderRadius(14)
        .backgroundColor($r('app.color.bg_card'))
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('颜色转换')
    .backgroundColor($r('app.color.bg_page'))
  }
}
