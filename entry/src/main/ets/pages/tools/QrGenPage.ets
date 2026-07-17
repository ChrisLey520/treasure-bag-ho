import { image } from '@kit.ImageKit';
import { ImageUtil } from '../../utils/ImageUtil';
import { QrCode, QrEcc } from '../../utils/QrCodeGen';

@Component
export struct QrGenPage {
  @State content: string = '';
  @State qrPixelMap?: image.PixelMap = undefined;
  @State working: boolean = false;

  /**
   * 本地生成（不依赖 ScanKit 系统服务，模拟器/无 HMS 环境也可用）：
   * QrCodeGen 编码 → RGBA 像素 → PixelMap
   */
  async generate(): Promise<void> {
    const text = this.content.trim();
    if (text.length === 0 || this.working) {
      return;
    }
    this.working = true;
    try {
      const qr = QrCode.encodeText(text, QrEcc.MEDIUM);
      const border = 2;
      const dim = qr.size + border * 2;
      const scale = Math.max(4, Math.floor(600 / dim));
      const px = dim * scale;
      const buf = new ArrayBuffer(px * px * 4);
      const arr = new Uint8Array(buf);
      for (let y = 0; y < px; y++) {
        const my = Math.floor(y / scale) - border;
        for (let x = 0; x < px; x++) {
          const mx = Math.floor(x / scale) - border;
          const dark = qr.getModule(mx, my);
          const off = (y * px + x) * 4;
          const v = dark ? 0 : 255;
          arr[off] = v;
          arr[off + 1] = v;
          arr[off + 2] = v;
          arr[off + 3] = 255;
        }
      }
      const pm = await image.createPixelMap(buf, {
        size: { width: px, height: px },
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        alphaType: image.AlphaType.OPAQUE
      });
      this.qrPixelMap?.release();
      this.qrPixelMap = pm;
    } catch (err) {
      console.error('generate qr failed:', JSON.stringify(err));
      const msg = (err as Error).message ?? '';
      this.getUIContext().getPromptAction().showToast({
        message: msg.includes('过长') ? '内容过长，无法编码' : '生成失败',
        duration: 1500
      });
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
