import { scanBarcode, scanCore } from '@kit.ScanKit';
import { pasteboard } from '@kit.BasicServicesKit';

@Component
export struct QrScanPage {
  @State results: string[] = [];
  @State scanning: boolean = false;

  async scan(): Promise<void> {
    if (this.scanning) {
      return;
    }
    this.scanning = true;
    try {
      const ctx = this.getUIContext().getHostContext();
      if (ctx === undefined) {
        this.scanning = false;
        return;
      }
      // defaultScanUI：系统扫码界面，自带相机权限处理与相册识码
      const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.ALL],
        enableMultiMode: false,
        enableAlbum: true
      };
      const result = await scanBarcode.startScanForResult(ctx, options);
      if (result.originalValue.length > 0) {
        this.results = [result.originalValue, ...this.results].slice(0, 20);
      }
    } catch (err) {
      // 用户取消也会抛错，静默处理
      console.error('scan failed or cancelled:', JSON.stringify(err));
    }
    this.scanning = false;
  }

  copy(text: string): void {
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: '已复制', duration: 1200 });
    }).catch((err: Error) => {
      console.error('copy failed:', err.message);
    });
  }

  build() {
    NavDestination() {
      Column({ space: 16 }) {
        Button(this.scanning ? '扫码中…' : '📷 开始扫码')
          .width('100%').height(54)
          .fontSize(17).fontWeight(FontWeight.Bold)
          .linearGradient({ angle: 135, colors: [['#0F2027', 0], ['#2C5364', 1]] })
          .enabled(!this.scanning)
          .onClick(() => this.scan())

        Text('支持二维码 / 条形码，扫码界面内可从相册选图识别')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))

        if (this.results.length > 0) {
          Text('识别历史（点击复制）')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .alignSelf(ItemAlign.Start)
        }

        List({ space: 8 }) {
          ForEach(this.results, (r: string, i: number) => {
            ListItem() {
              Text(r)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .padding(14)
                .borderRadius(12)
                .backgroundColor($r('app.color.bg_card'))
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .onClick(() => this.copy(r))
            }
          }, (r: string, i: number) => `${i}-${r}`)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        if (this.results.length === 0) {
          Column({ space: 8 }) {
            Text('📷').fontSize(48)
            Text('扫码结果显示在这里')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
          }
          .margin({ bottom: 120 })
        }
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('扫码识别')
    .backgroundColor($r('app.color.bg_page'))
  }
}
