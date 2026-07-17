import { image } from '@kit.ImageKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { ImageUtil, PickedImage } from '../../utils/ImageUtil';

@Component
export struct ColorPickerPage {
  @State picked?: PickedImage = undefined;
  @State hex: string = '';
  @State rgbText: string = '';
  @State loading: boolean = false;
  @State markX: number = -1;   // 取色点标记（容器坐标）
  @State markY: number = -1;
  private imgW: number = 0;   // 容器显示宽 vp
  private imgH: number = 0;

  async choose(): Promise<void> {
    this.loading = true;
    const img = await ImageUtil.pick(false);
    if (img !== undefined) {
      this.picked?.pixelMap.release();
      this.picked = img;
      this.hex = '';
      this.rgbText = '';
      this.markX = -1;
      this.markY = -1;
    }
    this.loading = false;
  }

  async pickColor(x: number, y: number): Promise<void> {
    if (this.picked === undefined || this.imgW === 0 || this.imgH === 0) {
      return;
    }
    // Contain 模式：图片按比例缩放居中，容器两侧/上下有留白，
    // 必须先算出图片实际显示矩形再映射，否则坐标整体偏移（取色不准的根因）
    const scale = Math.min(this.imgW / this.picked.width, this.imgH / this.picked.height);
    const dispW = this.picked.width * scale;
    const dispH = this.picked.height * scale;
    const offX = (this.imgW - dispW) / 2;
    const offY = (this.imgH - dispH) / 2;
    if (x < offX || x > offX + dispW || y < offY || y > offY + dispH) {
      return;   // 点在留白处
    }
    const px = Math.max(0, Math.min(this.picked.width - 1, Math.floor((x - offX) / scale)));
    const py = Math.max(0, Math.min(this.picked.height - 1, Math.floor((y - offY) / scale)));
    try {
      const buf = new ArrayBuffer(4);
      const area: image.PositionArea = {
        pixels: buf,
        offset: 0,
        stride: 4,
        region: { size: { width: 1, height: 1 }, x: px, y: py }
      };
      await this.picked.pixelMap.readPixels(area);
      const bytes = new Uint8Array(buf);
      // 按实际像素格式取通道（BGRA 红蓝对调过一次，务必判断格式）
      const fmt = this.picked.pixelMap.getImageInfoSync().pixelFormat;
      let r = 0;
      let g = 0;
      let b = 0;
      if (fmt === image.PixelMapFormat.BGRA_8888) {
        b = bytes[0];
        g = bytes[1];
        r = bytes[2];
      } else {
        r = bytes[0];
        g = bytes[1];
        b = bytes[2];
      }
      this.hex = '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0').toUpperCase()).join('');
      this.rgbText = `rgb(${r}, ${g}, ${b})`;
      this.markX = x;
      this.markY = y;
    } catch (err) {
      console.error('readPixels failed:', JSON.stringify(err));
    }
  }

  copyHex(): void {
    if (this.hex.length === 0) {
      return;
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.hex);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: `已复制 ${this.hex}`, duration: 1200 });
    }).catch((err: Error) => {
      console.error('copy failed:', err.message);
    });
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        if (this.picked !== undefined) {
          Stack({ alignContent: Alignment.TopStart }) {
            Image(this.picked.pixelMap)
              .objectFit(ImageFit.Contain)
              .width('100%')
              .height('100%')
              .borderRadius(16)
            // 取色点标记：环形准星
            if (this.markX >= 0) {
              Column()
                .width(18)
                .height(18)
                .borderRadius(9)
                .border({ width: 3, color: Color.White })
                .shadow({ radius: 4, color: '#66000000' })
                .position({ x: this.markX - 9, y: this.markY - 9 })
              Column()
                .width(10)
                .height(10)
                .borderRadius(5)
                .border({ width: 2, color: '#1A1D26' })
                .position({ x: this.markX - 5, y: this.markY - 5 })
            }
          }
          .width('100%')
          .layoutWeight(1)
          .onAreaChange((_old: Area, area: Area) => {
            this.imgW = area.width as number;
            this.imgH = area.height as number;
          })
          .onClick((event: ClickEvent) => {
            this.pickColor(event.x, event.y);
          })

          Row({ space: 14 }) {
            Column()
              .width(56).height(56).borderRadius(14)
              .backgroundColor(this.hex.length > 0 ? this.hex : '#33888888')
              .border({ width: 1, color: '#33888888' })
            Column({ space: 4 }) {
              Text(this.hex.length > 0 ? this.hex : '点击图片取色')
                .fontSize(20).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              if (this.rgbText.length > 0) {
                Text(this.rgbText)
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            if (this.hex.length > 0) {
              Text('复制')
                .fontSize(14).fontColor($r('app.color.accent'))
                .onClick(() => this.copyHex())
            }
          }
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))

          Button('换一张图')
            .width('100%').height(46)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onClick(() => this.choose())
        } else {
          Blank()
          Text('🎨').fontSize(60)
          Text('从相册选择图片，点击图片任意位置取色')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Button(this.loading ? '打开中…' : '选择图片')
            .width(200).height(52)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .linearGradient({ angle: 135, colors: [['#F093FB', 0], ['#F5576C', 1]] })
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
    .title('图片取色器')
    .backgroundColor($r('app.color.bg_page'))
    .onWillDisappear(() => {
      this.picked?.pixelMap.release();
    })
  }
}
