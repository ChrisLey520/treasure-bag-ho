import { textRecognition } from '@kit.CoreVisionKit';
import { pasteboard, BusinessError } from '@kit.BasicServicesKit';
import { ImageUtil, PickedImage } from '../../utils/ImageUtil';

@Component
export struct OcrPage {
  @State picked?: PickedImage = undefined;
  @State resultText: string = '';
  @State working: boolean = false;

  async chooseAndRecognize(): Promise<void> {
    if (this.working) {
      return;
    }
    this.working = true;
    const img = await ImageUtil.pick(false);
    if (img === undefined) {
      this.working = false;
      return;
    }
    this.picked?.pixelMap.release();
    this.picked = img;
    this.resultText = '';
    let inited = false;
    try {
      // 文字识别器需先 init（否则部分设备/版本首调直接抛错）
      await textRecognition.init();
      inited = true;
      const request: textRecognition.VisionInfo = { pixelMap: img.pixelMap };
      const config: textRecognition.TextRecognitionConfiguration = { isDirectionDetectionSupported: false };
      const result = await textRecognition.recognizeText(request, config);
      this.resultText = result.value.length > 0 ? result.value : '（未识别到文字）';
    } catch (err) {
      const e = err as BusinessError;
      console.error('ocr failed:', JSON.stringify(err));
      if (e.code === 1008601001) {
        this.resultText = '当前设备不支持文字识别\n（需华为设备 + HMS Core，模拟器不可用）';
      } else if (e.code === 1008601002) {
        this.resultText = '图片过大或格式不支持，请换一张';
      } else {
        this.resultText = `识别失败（错误码 ${e.code ?? '未知'}）\n${e.message ?? ''}`;
      }
    } finally {
      if (inited) {
        try {
          await textRecognition.release();
        } catch (err) {
          console.error('ocr release failed:', JSON.stringify(err));
        }
      }
    }
    this.working = false;
  }

  copyAll(): void {
    if (this.resultText.length === 0) {
      return;
    }
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.resultText);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: '已复制全部文字', duration: 1200 });
    }).catch((err: Error) => {
      console.error('copy failed:', err.message);
    });
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        if (this.picked !== undefined) {
          Image(this.picked.pixelMap)
            .objectFit(ImageFit.Contain)
            .width('100%')
            .height(200)
            .borderRadius(16)

          Row() {
            Text('识别结果')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
            Blank()
            if (this.resultText.length > 0) {
              Text('复制全部')
                .fontSize(13)
                .fontColor($r('app.color.accent'))
                .onClick(() => this.copyAll())
            }
          }
          .width('100%')

          Scroll() {
            Text(this.working ? '识别中…' : this.resultText)
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
              .lineHeight(26)
              .width('100%')
              .copyOption(CopyOptions.LocalDevice)
          }
          .layoutWeight(1)
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.bg_card'))
          .align(Alignment.TopStart)

          Button(this.working ? '处理中…' : '换一张图')
            .width('100%').height(48)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .enabled(!this.working)
            .onClick(() => this.chooseAndRecognize())
        } else {
          Blank()
          Text('🔤').fontSize(60)
          Text('本地 AI 识别图片中的文字\n无需网络，隐私安全')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .textAlign(TextAlign.Center)
            .lineHeight(24)
          Button(this.working ? '处理中…' : '选择图片识别')
            .width(200).height(52)
            .fontSize(16).fontWeight(FontWeight.Bold)
            .linearGradient({ angle: 135, colors: [['#8E2DE2', 0], ['#4A00E0', 1]] })
            .enabled(!this.working)
            .onClick(() => this.chooseAndRecognize())
          Blank()
          Blank()
        }
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('OCR 文字识别')
    .backgroundColor($r('app.color.bg_page'))
    .onWillDisappear(() => {
      this.picked?.pixelMap.release();
    })
  }
}
