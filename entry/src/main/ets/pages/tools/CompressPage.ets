import { ImageUtil, PickedImage } from '../../utils/ImageUtil';

@Component
export struct CompressPage {
  @State picked?: PickedImage = undefined;
  @State loading: boolean = false;
  @State working: boolean = false;
  @State quality: number = 60;
  @State scalePercent: number = 100;
  @State resultBytes: number = 0;
  private resultBuf?: ArrayBuffer;

  async choose(): Promise<void> {
    this.loading = true;
    const img = await ImageUtil.pick(true);
    if (img !== undefined) {
      this.picked?.pixelMap.release();
      this.picked = img;
      this.resultBytes = 0;
      this.resultBuf = undefined;
    }
    this.loading = false;
  }

  async compress(): Promise<void> {
    if (this.picked === undefined || this.working) {
      return;
    }
    this.working = true;
    try {
      let pm = this.picked.pixelMap;
      if (this.scalePercent < 100) {
        // scale 会修改原 PixelMap，按比例缩小
        const factor = this.scalePercent / 100;
        await pm.scale(factor, factor);
      }
      const buf = await ImageUtil.encodeJpeg(pm, this.quality);
      if (buf !== undefined) {
        this.resultBuf = buf;
        this.resultBytes = buf.byteLength;
      }
    } catch (err) {
      console.error('compress failed:', JSON.stringify(err));
    }
    this.working = false;
  }

  async save(): Promise<void> {
    if (this.resultBuf === undefined || this.working) {
      return;
    }
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    this.working = true;
    const ok = await ImageUtil.saveBufferToAlbum(ctx, this.resultBuf);
    this.working = false;
    this.getUIContext().getPromptAction().showToast({
      message: ok ? '已保存到相册 ✅' : '保存失败',
      duration: 1500
    });
  }

  ratio(): string {
    if (this.picked === undefined || this.resultBytes === 0) {
      return '';
    }
    return `${(100 - this.resultBytes / this.picked.sizeBytes * 100).toFixed(0)}%`;
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        if (this.picked !== undefined) {
          Image(this.picked.pixelMap)
            .objectFit(ImageFit.Contain)
            .width('100%')
            .layoutWeight(1)
            .borderRadius(16)

          Row() {
            Column({ space: 2 }) {
              Text('原图').fontSize(12).fontColor($r('app.color.text_secondary'))
              Text(ImageUtil.fmtSize(this.picked.sizeBytes))
                .fontSize(16).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              Text(`${this.picked.width}×${this.picked.height}`)
                .fontSize(11).fontColor($r('app.color.text_secondary'))
            }
            Blank()
            if (this.resultBytes > 0) {
              Text('→').fontSize(20).fontColor($r('app.color.text_secondary'))
              Blank()
              Column({ space: 2 }) {
                Text(`压缩后（省 ${this.ratio()}）`).fontSize(12).fontColor('#43E97B')
                Text(ImageUtil.fmtSize(this.resultBytes))
                  .fontSize(16).fontWeight(FontWeight.Bold)
                  .fontColor('#43E97B')
              }
            }
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))

          Column({ space: 6 }) {
            Row() {
              Text('JPEG 质量').fontSize(13).fontColor($r('app.color.text_secondary'))
              Blank()
              Text(`${this.quality}`).fontSize(13).fontColor($r('app.color.text_primary'))
            }.width('100%')
            Slider({ value: this.quality, min: 10, max: 100, step: 5 })
              .onChange((v: number) => { this.quality = v; })
            Row() {
              Text('分辨率缩放').fontSize(13).fontColor($r('app.color.text_secondary'))
              Blank()
              Text(`${this.scalePercent}%`).fontSize(13).fontColor($r('app.color.text_primary'))
            }.width('100%')
            Slider({ value: this.scalePercent, min: 20, max: 100, step: 10 })
              .onChange((v: number) => { this.scalePercent = v; })
          }
          .padding(16).borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))

          Row({ space: 10 }) {
            Button('换一张')
              .layoutWeight(1).height(48)
              .backgroundColor($r('app.color.bg_card'))
              .fontColor($r('app.color.text_primary'))
              .onClick(() => this.choose())
            Button(this.working ? '处理中…' : '压缩')
              .layoutWeight(1).height(48)
              .fontWeight(FontWeight.Bold)
              .backgroundColor($r('app.color.accent'))
              .enabled(!this.working)
              .onClick(() => this.compress())
            if (this.resultBytes > 0) {
              Button('保存')
                .layoutWeight(1).height(48)
                .fontWeight(FontWeight.Bold)
                .linearGradient({ angle: 135, colors: [['#11998E', 0], ['#38EF7D', 1]] })
                .enabled(!this.working)
                .onClick(() => this.save())
            }
          }
          .width('100%')
        } else {
          Blank()
          Text('🗜️').fontSize(60)
          Text('调节质量与分辨率，压缩图片体积')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Button(this.loading ? '打开中…' : '选择图片')
            .width(200).height(52)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .linearGradient({ angle: 135, colors: [['#667EEA', 0], ['#764BA2', 1]] })
            .enabled(!this.loading)
            .onClick(() => this.choose())
          Blank()
          Blank()
        }
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('图片压缩')
    .backgroundColor($r('app.color.bg_page'))
    .onWillDisappear(() => {
      this.picked?.pixelMap.release();
    })
  }
}
