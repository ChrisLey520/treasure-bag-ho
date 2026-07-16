@Component
export struct RadixPage {
  @State input: string = '';
  @State fromRadix: number = 10;
  private radixList: number[] = [2, 8, 10, 16];

  convert(to: number): string {
    const v = parseInt(this.input.trim(), this.fromRadix);
    if (isNaN(v)) {
      return '—';
    }
    return v.toString(to).toUpperCase();
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Text('输入数值')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)

        TextInput({ placeholder: '请输入数字', text: this.input })
          .height(50)
          .borderRadius(14)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.input = v; })

        Row({ space: 10 }) {
          ForEach(this.radixList, (r: number) => {
            Text(`${r} 进制`)
              .fontSize(14)
              .fontColor(this.fromRadix === r ? Color.White : $r('app.color.text_secondary'))
              .padding({ left: 14, right: 14, top: 8, bottom: 8 })
              .borderRadius(16)
              .backgroundColor(this.fromRadix === r ? $r('app.color.accent') : $r('app.color.bg_card'))
              .onClick(() => { this.fromRadix = r; })
          }, (r: number) => r.toString())
        }
        .alignSelf(ItemAlign.Start)

        Divider().margin({ top: 8, bottom: 8 })

        ForEach(this.radixList, (r: number) => {
          Row() {
            Text(`${r} 进制`)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .width(70)
            Text(this.convert(r))
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
              .textAlign(TextAlign.End)
              .copyOption(CopyOptions.LocalDevice)
          }
          .width('100%')
          .padding(16)
          .borderRadius(14)
          .backgroundColor($r('app.color.bg_card'))
        }, (r: number) => 'out' + r.toString())
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('进制转换')
    .backgroundColor($r('app.color.bg_page'))
  }
}
