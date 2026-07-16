@Component
export struct JsonPage {
  @State input: string = '';
  @State output: string = '';
  @State error: string = '';

  format(indent: number): void {
    try {
      const obj: object = JSON.parse(this.input) as object;
      this.output = JSON.stringify(obj, null, indent);
      this.error = '';
    } catch (e) {
      this.error = '解析失败：' + (e as Error).message;
      this.output = '';
    }
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        TextArea({ placeholder: '粘贴 JSON 文本…', text: this.input })
          .layoutWeight(2)
          .borderRadius(14)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .fontSize(13)
          .onChange((v: string) => { this.input = v; })

        Row({ space: 10 }) {
          Button('格式化')
            .layoutWeight(1).height(46)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => this.format(2))
          Button('压缩')
            .layoutWeight(1).height(46)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onClick(() => this.format(0))
          Button('清空')
            .layoutWeight(1).height(46)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onClick(() => {
              this.input = '';
              this.output = '';
              this.error = '';
            })
        }
        .width('100%')

        if (this.error.length > 0) {
          Text(this.error)
            .fontSize(13)
            .fontColor('#F5576C')
            .width('100%')
            .padding(12)
            .borderRadius(10)
            .backgroundColor('#1AF5576C')
        }

        Scroll() {
          Text(this.output.length > 0 ? this.output : '结果将显示在这里')
            .fontSize(13)
            .fontColor(this.output.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
            .width('100%')
            .copyOption(CopyOptions.LocalDevice)
        }
        .layoutWeight(3)
        .width('100%')
        .padding(14)
        .borderRadius(14)
        .backgroundColor($r('app.color.bg_card'))
        .align(Alignment.TopStart)
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('JSON 格式化')
    .backgroundColor($r('app.color.bg_page'))
  }
}
