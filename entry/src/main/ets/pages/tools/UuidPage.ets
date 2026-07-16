import { util } from '@kit.ArkTS';
import { pasteboard } from '@kit.BasicServicesKit';

@Component
export struct UuidPage {
  @State uuids: string[] = [];
  @State count: number = 5;
  @State upperCase: boolean = false;
  @State noDash: boolean = false;

  generate(): void {
    const list: string[] = [];
    for (let i = 0; i < this.count; i++) {
      let id = util.generateRandomUUID(true);
      if (this.noDash) {
        id = id.split('-').join('');
      }
      if (this.upperCase) {
        id = id.toUpperCase();
      }
      list.push(id);
    }
    this.uuids = list;
  }

  copyAll(): void {
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.uuids.join('\n'));
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: `已复制 ${this.uuids.length} 个 UUID`, duration: 1200 });
    }).catch((err: Error) => {
      console.error('copy failed:', err.message);
    });
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Column({ space: 6 }) {
          Row() {
            Text('生成数量').fontSize(14).fontColor($r('app.color.text_secondary'))
            Blank()
            Text(`${this.count}`).fontSize(14).fontColor($r('app.color.text_primary'))
          }.width('100%')
          Slider({ value: this.count, min: 1, max: 50, step: 1 })
            .onChange((v: number) => { this.count = v; })
        }
        .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))

        Row({ space: 10 }) {
          Text('大写')
            .fontSize(13)
            .fontColor(this.upperCase ? Color.White : $r('app.color.text_secondary'))
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .borderRadius(16)
            .backgroundColor(this.upperCase ? $r('app.color.accent') : $r('app.color.bg_card'))
            .onClick(() => { this.upperCase = !this.upperCase; })
          Text('去横线')
            .fontSize(13)
            .fontColor(this.noDash ? Color.White : $r('app.color.text_secondary'))
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .borderRadius(16)
            .backgroundColor(this.noDash ? $r('app.color.accent') : $r('app.color.bg_card'))
            .onClick(() => { this.noDash = !this.noDash; })
          Blank()
          if (this.uuids.length > 0) {
            Text('复制全部')
              .fontSize(13)
              .fontColor($r('app.color.accent'))
              .onClick(() => this.copyAll())
          }
        }
        .width('100%')

        Button('生成 UUID')
          .width('100%').height(50)
          .fontSize(16).fontWeight(FontWeight.Bold)
          .backgroundColor($r('app.color.accent'))
          .onClick(() => this.generate())

        List({ space: 8 }) {
          ForEach(this.uuids, (id: string) => {
            ListItem() {
              Text(id)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .padding(14)
                .borderRadius(12)
                .backgroundColor($r('app.color.bg_card'))
                .copyOption(CopyOptions.LocalDevice)
            }
          }, (id: string) => id)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('UUID 生成')
    .backgroundColor($r('app.color.bg_page'))
  }
}
