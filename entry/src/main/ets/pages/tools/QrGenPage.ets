import { generateBarcode, scanCore } from '@kit.ScanKit';
import { image } from '@kit.ImageKit';
import { ImageUtil } from '../../utils/ImageUtil';

@Component
export struct QrGenPage {
  @State content: string = '';
  @State qrPixelMap?: image.PixelMap = undefined;
  @State working: boolean = false;

  async generate(): Promise<void> {
    const text = this.content.trim();
    if (text.length === 0 || this.working) {
      return;
    }
    this.working = true;
    try {
      const options: generateBarcode.CreateOptions = {
        scanType: scanCore.ScanType.QR_CODE,
        height: 600,
        width: 600,
        margin: 2
      };
      const pm = await generateBarcode.createBarcode(text, options);
      this.qrPixelMap?.release();
      this.qrPixelMap = pm;
    } catch (err) {
      console.error('generate qr failed:', JSON.stringify(err));
      this.getUIContext().getPromptAction().showToast({ message: '生成失败，内容可能过长', duration: 1500 });
    }
    this.working = false;
  }

  async save(): Promise<void> {
    if (this.qrPixelMap === undefined || this.working) {
      return;
    }
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    this.working = true;
    const ok = await ImageUtil.saveToAlbum(ctx, this.qrPixelMap, 100);
    this.working = false;
    this.getUIContext().getPromptAction().showToast({
      message: ok ? '已保存到相册 ✅' : '保存失败',
      duration: 1500
    });
  }

  build() {
    NavDestination() {
      Column({ space: 18 }) {
        TextArea({ placeholder: '输入文本 / 网址…', text: this.content })
          .height(110)
          .borderRadius(14)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.content = v; })

        Button(this.working ? '生成中…' : '生成二维码')
          .width('100%').height(50)
          .fontSize(16).fontWeight(FontWeight.Bold)
          .backgroundColor($r('app.color.accent'))
          .enabled(!this.working && this.content.trim().length > 0)
          .onClick(() => this.generate())

        if (this.qrPixelMap !== undefined) {
          Column({ space: 16 }) {
            Image(this.qrPixelMap)
              .width(240).height(240)
              .borderRadius(12)
              .backgroundColor(Color.White)
              .padding(10)
            Button('保存到相册')
              .width(200).height(46)
              .linearGradient({ angle: 135, colors: [['#11998E', 0], ['#38EF7D', 1]] })
              .enabled(!this.working)
              .onClick(() => this.save())
          }
          .width('100%')
          .padding(24)
          .borderRadius(20)
          .backgroundColor($r('app.color.bg_card'))
        } else {
          Column({ space: 8 }) {
            Text('▦').fontSize(56).fontColor($r('app.color.text_secondary'))
            Text('二维码将显示在这里')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .padding(40)
          .borderRadius(20)
          .backgroundColor($r('app.color.bg_card'))
        }

        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('二维码生成')
    .backgroundColor($r('app.color.bg_page'))
    .onWillDisappear(() => {
      this.qrPixelMap?.release();
    })
  }
}
