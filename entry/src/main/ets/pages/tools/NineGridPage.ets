import { image } from '@kit.ImageKit';
import { ImageUtil, PickedImage } from '../../utils/ImageUtil';

@Component
export struct NineGridPage {
  @State picked?: PickedImage = undefined;
  @State loading: boolean = false;
  @State working: boolean = false;
  @State progress: number = 0;
  @State tiles: image.PixelMap[] = [];

  async choose(): Promise<void> {
    this.loading = true;
    const img = await ImageUtil.pick(false);
    if (img !== undefined) {
      this.releaseTiles();
      this.picked?.pixelMap.release();
      this.picked = img;
    }
    this.loading = false;
  }

  releaseTiles(): void {
    for (const t of this.tiles) {
      t.release();
    }
    this.tiles = [];
  }

  async cut(): Promise<void> {
    if (this.picked === undefined || this.working) {
      return;
    }
    this.working = true;
    this.releaseTiles();
    try {
      // 原图编码一次，再按 desiredRegion 分区域解码出 9 块
      const buf = await ImageUtil.encodeJpeg(this.picked.pixelMap, 95);
      if (buf === undefined) {
        this.working = false;
        return;
      }
      const side = Math.min(this.picked.width, this.picked.height);
      const offX = Math.floor((this.picked.width - side) / 2);
      const offY = Math.floor((this.picked.height - side) / 2);
      const tile = Math.floor(side / 3);
      const source = image.createImageSource(buf);
      const list: image.PixelMap[] = [];
      for (let row = 0; row < 3; row++) {
        for (let col = 0; col < 3; col++) {
          const pm = await source.createPixelMap({
            desiredRegion: {
              x: offX + col * tile,
              y: offY + row * tile,
              size: { width: tile, height: tile }
            }
          });
          list.push(pm);
        }
      }
      source.release();
      this.tiles = list;
    } catch (err) {
      console.error('cut failed:', JSON.stringify(err));
      this.getUIContext().getPromptAction().showToast({ message: '切图失败', duration: 1500 });
    }
    this.working = false;
  }

  async saveAll(): Promise<void> {
    if (this.tiles.length === 0 || this.working) {
      return;
    }
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    this.working = true;
    this.progress = 0;
    let ok = 0;
    for (let i = 0; i < this.tiles.length; i++) {
      const saved = await ImageUtil.saveToAlbum(ctx, this.tiles[i], 95);
      if (saved) {
        ok += 1;
      }
      this.progress = i + 1;
    }
    this.working = false;
    this.getUIContext().getPromptAction().showToast({
      message: ok === 9 ? '9 张已全部保存到相册 ✅' : `保存完成：成功 ${ok}/9`,
      duration: 1800
    });
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        if (this.picked !== undefined) {
          if (this.tiles.length === 9) {
            // 3×3 预览
            Grid() {
              ForEach(this.tiles, (t: image.PixelMap, i: number) => {
                GridItem() {
                  Image(t)
                    .objectFit(ImageFit.Cover)
                    .width('100%')
                    .aspectRatio(1)
                    .borderRadius(6)
                }
              }, (t: image.PixelMap, i: number) => i.toString())
            }
            .columnsTemplate('1fr 1fr 1fr')
            .columnsGap(4)
            .rowsGap(4)
            .width('100%')
            .aspectRatio(1)
          } else {
            Image(this.picked.pixelMap)
              .objectFit(ImageFit.Contain)
              .width('100%')
              .layoutWeight(1)
              .borderRadius(16)
          }

          if (this.working && this.progress > 0) {
            Progress({ value: this.progress, total: 9, type: ProgressType.Linear })
              .width('100%')
              .color($r('app.color.accent'))
          }

          Row({ space: 10 }) {
            Button('换一张')
              .layoutWeight(1).height(48)
              .backgroundColor($r('app.color.bg_card'))
              .fontColor($r('app.color.text_primary'))
              .enabled(!this.working)
              .onClick(() => this.choose())
            if (this.tiles.length === 9) {
              Button(this.working ? `保存中 ${this.progress}/9` : '保存 9 张到相册')
                .layoutWeight(2).height(48)
                .fontWeight(FontWeight.Bold)
                .linearGradient({ angle: 135, colors: [['#11998E', 0], ['#38EF7D', 1]] })
                .enabled(!this.working)
                .onClick(() => this.saveAll())
            } else {
              Button(this.working ? '切图中…' : '✂️ 切九宫格')
                .layoutWeight(2).height(48)
                .fontWeight(FontWeight.Bold)
                .backgroundColor($r('app.color.accent'))
                .enabled(!this.working)
                .onClick(() => this.cut())
            }
          }
          .width('100%')
        } else {
          Blank()
          Text('🖼️').fontSize(60)
          Text('将图片切成 3×3 九宫格\n发朋友圈的仪式感')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .lineHeight(24)
          Button(this.loading ? '打开中…' : '选择图片')
            .width(200).height(52)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .linearGradient({ angle: 135, colors: [['#FC5C7D', 0], ['#6A82FB', 1]] })
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
    .title('九宫格切图')
    .backgroundColor($r('app.color.bg_page'))
    .onWillDisappear(() => {
      this.releaseTiles();
      this.picked?.pixelMap.release();
    })
  }
}
