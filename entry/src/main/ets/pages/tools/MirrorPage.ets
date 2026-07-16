import { ImageUtil, PickedImage } from '../../utils/ImageUtil';

@Component
export struct MirrorPage {
  @State picked?: PickedImage = undefined;
  @State loading: boolean = false;
  @State saving: boolean = false;
  @State flippedH: boolean = false;
  @State flippedV: boolean = false;
  @State rotation: number = 0;

  async choose(): Promise<void> {
    this.loading = true;
    const img = await ImageUtil.pick(true);
    if (img !== undefined) {
      this.picked?.pixelMap.release();
      this.picked = img;
      this.flippedH = false;
      this.flippedV = false;
      this.rotation = 0;
    }
    this.loading = false;
  }

  async flip(horizontal: boolean): Promise<void> {
    if (this.picked === undefined) {
      return;
    }
    try {
      await this.picked.pixelMap.flip(horizontal, !horizontal);
      if (horizontal) {
        this.flippedH = !this.flippedH;
      } else {
        this.flippedV = !this.flippedV;
      }
      // 触发刷新
      const p = this.picked;
      this.picked = undefined;
      this.picked = p;
    } catch (err) {
      console.error('flip failed:', JSON.stringify(err));
    }
  }

  async rotate90(): Promise<void> {
    if (this.picked === undefined) {
      return;
    }
    try {
      await this.picked.pixelMap.rotate(90);
      this.rotation = (this.rotation + 90) % 360;
      const p = this.picked;
      this.picked = undefined;
      this.picked = p;
    } catch (err) {
      console.error('rotate failed:', JSON.stringify(err));
    }
  }

  async save(): Promise<void> {
    if (this.picked === undefined || this.saving) {
      return;
    }
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    this.saving = true;
    const ok = await ImageUtil.saveToAlbum(ctx, this.picked.pixelMap, 95);
    this.saving = false;
    this.getUIContext().getPromptAction().showToast({
      message: ok ? '已保存到相册 ✅' : '保存失败',
      duration: 1500
    });
  }

  @Builder
  opButton(label: string, action: () => void) {
    Button(label)
      .layoutWeight(1)
      .height(46)
      .fontSize(14)
      .backgroundColor($r('app.color.bg_card'))
      .fontColor($r('app.color.text_primary'))
      .onClick(action)
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        if (this.picked !== undefined) {
          Image(this.picked.pixelMap)
            .objectFit(ImageFit.Contain)
            .width('100%')
            .layoutWeight(1)
            .borderRadius(16)

          Row({ space: 10 }) {
            this.opButton('↔️ 水平翻转', () => { this.flip(true); })
            this.opButton('↕️ 垂直翻转', () => { this.flip(false); })
            this.opButton('🔄 旋转 90°', () => { this.rotate90(); })
          }
          .width('100%')

          Row({ space: 10 }) {
            Button('换一张')
              .layoutWeight(1).height(48)
              .backgroundColor($r('app.color.bg_card'))
              .fontColor($r('app.color.text_primary'))
              .onClick(() => this.choose())
            Button(this.saving ? '保存中…' : '保存到相册')
              .layoutWeight(2).height(48)
              .fontWeight(FontWeight.Bold)
              .backgroundColor($r('app.color.accent'))
              .enabled(!this.saving)
              .onClick(() => this.save())
          }
          .width('100%')
        } else {
          Blank()
          Text('🪞').fontSize(60)
          Text('翻转 / 旋转图片，保存到相册')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Button(this.loading ? '打开中…' : '选择图片')
            .width(200).height(52)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .linearGradient({ angle: 135, colors: [['#4FACFE', 0], ['#00F2FE', 1]] })
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
    .title('图片镜像')
    .backgroundColor($r('app.color.bg_page'))
    .onWillDisappear(() => {
      this.picked?.pixelMap.release();
    })
  }
}
