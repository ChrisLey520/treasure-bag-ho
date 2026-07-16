import { util } from '@kit.ArkTS';

@Component
export struct EncodePage {
  @State input: string = '';
  @State output: string = '';
  @State error: string = '';

  private base64 = new util.Base64Helper();

  toBase64(): void {
    try {
      const bytes = new util.TextEncoder().encodeInto(this.input);
      this.output = this.base64.encodeToStringSync(bytes);
      this.error = '';
    } catch (e) {
      this.error = '编码失败：' + (e as Error).message;
    }
  }

  fromBase64(): void {
    try {
      const bytes = this.base64.decodeSync(this.input.trim());
      this.output = util.TextDecoder.create('utf-8').decodeToString(bytes);
      this.error = '';
    } catch (e) {
      this.error = '解码失败：不是合法的 Base64';
      this.output = '';
    }
  }

  toUrl(): void {
    this.output = encodeURIComponent(this.input);
    this.error = '';
  }

  fromUrl(): void {
    try {
      this.output = decodeURIComponent(this.input);
      this.error = '';
    } catch (e) {
      this.error = '解码失败：不是合法的 URL 编码';
      this.output = '';
    }
  }

  @Builder
  actionButton(label: string, primary: boolean, action: () => void) {
    Button(label)
      .layoutWeight(1)
      .height(46)
      .fontSize(14)
      .backgroundColor(primary ? $r('app.color.accent') : $r('app.color.bg_card'))
      .fontColor(primary ? Color.White : $r('app.color.text_primary'))
      .onClick(action)
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        TextArea({ placeholder: '输入文本…', text: this.input })
          .layoutWeight(1)
          .borderRadius(14)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.input = v; })

        Row({ space: 10 }) {
          this.actionButton('Base64 编码', true, () => this.toBase64())
          this.actionButton('Base64 解码', false, () => this.fromBase64())
        }
        .width('100%')

        Row({ space: 10 }) {
          this.actionButton('URL 编码', true, () => this.toUrl())
          this.actionButton('URL 解码', false, () => this.fromUrl())
        }
        .width('100%')

        if (this.error.length > 0) {
          Text(this.error)
            .fontSize(13).fontColor('#F5576C')
            .width('100%').padding(12)
            .borderRadius(10).backgroundColor('#1AF5576C')
        }

        Scroll() {
          Text(this.output.length > 0 ? this.output : '结果显示在这里，长按可复制')
            .fontSize(14)
            .fontColor(this.output.length > 0 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
            .width('100%')
            .copyOption(CopyOptions.LocalDevice)
        }
        .layoutWeight(1)
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
    .title('编码转换')
    .backgroundColor($r('app.color.bg_page'))
  }
}
