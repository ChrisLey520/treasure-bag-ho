import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';

interface HashResult {
  algo: string;
  value: string;
}

const ALGORITHMS: string[] = ['MD5', 'SHA1', 'SHA256', 'SHA512'];

@Component
export struct HashPage {
  @State input: string = '';
  @State results: HashResult[] = [];
  @State computing: boolean = false;

  async compute(): Promise<void> {
    if (this.input.length === 0 || this.computing) {
      return;
    }
    this.computing = true;
    const bytes = new util.TextEncoder().encodeInto(this.input);
    const list: HashResult[] = [];
    for (const algo of ALGORITHMS) {
      try {
        const md = cryptoFramework.createMd(algo);
        await md.update({ data: bytes });
        const digest = await md.digest();
        let hex = '';
        for (const b of digest.data) {
          hex += b.toString(16).padStart(2, '0');
        }
        list.push({ algo: algo, value: hex });
      } catch (e) {
        list.push({ algo: algo, value: '计算失败' });
      }
    }
    this.results = list;
    this.computing = false;
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        TextArea({ placeholder: '输入要计算摘要的文本…', text: this.input })
          .height(140)
          .borderRadius(14)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.input = v; })

        Button(this.computing ? '计算中…' : '计算哈希')
          .width('100%').height(50)
          .fontSize(16).fontWeight(FontWeight.Bold)
          .backgroundColor($r('app.color.accent'))
          .enabled(!this.computing && this.input.length > 0)
          .onClick(() => {
            this.compute();
          })

        List({ space: 10 }) {
          ForEach(this.results, (r: HashResult) => {
            ListItem() {
              Column({ space: 6 }) {
                Text(r.algo)
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.accent'))
                Text(r.value)
                  .fontSize(13)
                  .fontColor($r('app.color.text_primary'))
                  .copyOption(CopyOptions.LocalDevice)
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding(14)
              .borderRadius(14)
              .backgroundColor($r('app.color.bg_card'))
            }
          }, (r: HashResult) => r.algo + r.value)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        if (this.results.length === 0) {
          Text('支持 MD5 / SHA1 / SHA256 / SHA512')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
        }
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('哈希计算')
    .backgroundColor($r('app.color.bg_page'))
  }
}
