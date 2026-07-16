@Component
export struct BmiPage {
  @State heightCm: number = 170;
  @State weightKg: number = 60;

  bmi(): number {
    const h = this.heightCm / 100;
    return this.weightKg / (h * h);
  }

  level(): string {
    const v = this.bmi();
    if (v < 18.5) { return '偏瘦'; }
    if (v < 24) { return '正常'; }
    if (v < 28) { return '超重'; }
    return '肥胖';
  }

  levelColor(): string {
    const v = this.bmi();
    if (v < 18.5) { return '#4FACFE'; }
    if (v < 24) { return '#43E97B'; }
    if (v < 28) { return '#FEE140'; }
    return '#F5576C';
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Column({ space: 6 }) {
          Text('你的 BMI')
            .fontSize(13)
            .fontColor('#CCFFFFFF')
          Text(this.bmi().toFixed(1))
            .fontSize(52)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(this.level())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ left: 16, right: 16, top: 4, bottom: 4 })
            .borderRadius(14)
            .backgroundColor('#33FFFFFF')
        }
        .width('100%')
        .padding(28)
        .borderRadius(20)
        .linearGradient({ angle: 135, colors: [[this.levelColor(), 0], ['#330867', 1]] })
        .animation({ duration: 300, curve: Curve.EaseOut })

        Column({ space: 6 }) {
          Row() {
            Text('身高').fontSize(14).fontColor($r('app.color.text_secondary'))
            Blank()
            Text(`${this.heightCm.toFixed(0)} cm`).fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          }.width('100%')
          Slider({ value: this.heightCm, min: 100, max: 230 })
            .onChange((v: number) => { this.heightCm = v; })
        }
        .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))

        Column({ space: 6 }) {
          Row() {
            Text('体重').fontSize(14).fontColor($r('app.color.text_secondary'))
            Blank()
            Text(`${this.weightKg.toFixed(1)} kg`).fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          }.width('100%')
          Slider({ value: this.weightKg, min: 25, max: 200, step: 0.5 })
            .onChange((v: number) => { this.weightKg = v; })
        }
        .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))

        Column({ space: 8 }) {
          Text('参考标准（中国成人）').fontSize(13).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
          Text('偏瘦 < 18.5   |   正常 18.5 ~ 23.9\n超重 24 ~ 27.9   |   肥胖 ≥ 28')
            .fontSize(13)
            .fontColor($r('app.color.text_primary'))
            .lineHeight(22)
        }
        .width('100%')
        .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))
        .alignItems(HorizontalAlign.Start)
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('BMI 计算')
    .backgroundColor($r('app.color.bg_page'))
  }
}
