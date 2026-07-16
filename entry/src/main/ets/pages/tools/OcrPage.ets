import { textRecognition } from '@kit.CoreVisionKit';
import { pasteboard } from '@kit.BasicServicesKit';
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
    try {
      const request: textRecognition.VisionInfo = { pixelMap: img.pixelMap };
      const result = await textRecognition.recognizeText(request);
      this.resultText = result.value.length > 0 ? result.value : '（未识别到文字）';
    } catch (err) {
      console.error('ocr failed:', JSON.stringify(err));
      this.resultText = '识别失败，请重试';
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
