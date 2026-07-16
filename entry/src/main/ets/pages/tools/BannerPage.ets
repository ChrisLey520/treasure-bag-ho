import { display } from '@kit.ArkUI';

const BG_COLORS: string[] = ['#000000', '#F5576C', '#5B6BF5', '#43E97B', '#FEE140', '#FFFFFF'];
const TEXT_COLORS: string[] = ['#FFFFFF', '#FFD700', '#00F2FE', '#FF512F', '#1A1D26'];

function toHex(v: number): string {
  return Math.round(v).toString(16).padStart(2, '0').toUpperCase();
}

/** 解析 #RGB / #RRGGBB → [r, g, b]，非法返回 undefined */
function parseHex(input: string): number[] | undefined {
  let s = input.trim().replace('#', '');
  if (s.length === 3) {
    s = s[0] + s[0] + s[1] + s[1] + s[2] + s[2];
  }
  if (s.length !== 6) {
    return undefined;
  }
  const r = parseInt(s.substring(0, 2), 16);
  const g = parseInt(s.substring(2, 4), 16);
  const b = parseInt(s.substring(4, 6), 16);
  if (isNaN(r) || isNaN(g) || isNaN(b)) {
    return undefined;
  }
  return [r, g, b];
}

/** RGB 调色面板：滑杆 + 十六进制输入，双向同步 */
@Component
struct RgbPicker {
  @Link hexColor: string;
  @State r: number = 0;
  @State g: number = 0;
  @State b: number = 0;
  @State hexInput: string = '';

  aboutToAppear(): void {
    const rgb = parseHex(this.hexColor);
    if (rgb !== undefined) {
      this.r = rgb[0];
      this.g = rgb[1];
      this.b = rgb[2];
    }
    this.hexInput = this.hexColor;
  }

  sync(): void {
    this.hexColor = `#${toHex(this.r)}${toHex(this.g)}${toHex(this.b)}`;
    this.hexInput = this.hexColor;
  }

  @Builder
  channel(label: string, value: number, barColor: string, onChangeValue: (v: number) => void) {
    Row({ space: 10 }) {
      Text(label).fontSize(13).fontColor($r('app.color.text_secondary')).width(16)
      Slider({ value: value, min: 0, max: 255, step: 1 })
        .layoutWeight(1)
        .selectedColor(barColor)
        .onChange((v: number) => onChangeValue(v))
      Text(Math.round(value).toString())
        .fontSize(12).fontColor($r('app.color.text_primary'))
        .width(32).textAlign(TextAlign.End)
    }
    .width('100%')
  }

  build() {
    Column({ space: 4 }) {
      this.channel('R', this.r, '#F5576C', (v) => {
        this.r = v;
        this.sync();
      })
      this.channel('G', this.g, '#43E97B', (v) => {
        this.g = v;
        this.sync();
      })
      this.channel('B', this.b, '#5B6BF5', (v) => {
        this.b = v;
        this.sync();
      })

      Row({ space: 10 }) {
        Text('HEX').fontSize(13).fontColor($r('app.color.text_secondary'))
        TextInput({ placeholder: '#RRGGBB', text: this.hexInput })
          .layoutWeight(1)
          .height(40).borderRadius(10)
          .fontSize(14)
          .backgroundColor($r('app.color.bg_page'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => {
            this.hexInput = v;
            const rgb = parseHex(v);
            if (rgb !== undefined) {
              this.r = rgb[0];
              this.g = rgb[1];
              this.b = rgb[2];
              this.hexColor = `#${toHex(rgb[0])}${toHex(rgb[1])}${toHex(rgb[2])}`;
            }
          })
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .width('100%')
  }
}

@Component
export struct BannerPage {
  @State text: string = '前面的朋友你好！';
  @State bgIndex: number = 0;
  @State textIndex: number = 0;
  @State customBg: string = '#7B2FF7';   // 自定义背景色（bgIndex === -1 时生效）
  @State customText: string = '#00FFCC'; // 自定义文字色（textIndex === -1 时生效）
  @State fontSize: number = 120;
  @State speed: number = 5;
  @State playing: boolean = false;
  @State offsetX: number = 0;
  private timerId: number = -1;
  private screenW: number = 720;

  aboutToDisappear(): void {
    this.stop();
  }

  bgColor(): string {
    return this.bgIndex < 0 ? this.customBg : BG_COLORS[this.bgIndex];
  }

  textColor(): string {
    return this.textIndex < 0 ? this.customText : TEXT_COLORS[this.textIndex];
  }

  /** 文本完整宽度（vp）：每个字约占一个 fontSize，再加余量 */
  textWidth(): number {
    return (this.text.length + 2) * this.fontSize;
  }

  start(): void {
    this.playing = true;
    // 真实屏幕宽度（px → vp）
    try {
      this.screenW = this.getUIContext().px2vp(display.getDefaultDisplaySync().width);
    } catch (err) {
      console.error('get display failed:', JSON.stringify(err));
    }
    this.offsetX = this.screenW;
    // 简易滚动：定时平移
    this.timerId = setInterval(() => {
      this.offsetX -= this.speed * 3;
      if (this.offsetX < -this.textWidth()) {
        this.offsetX = this.screenW;
      }
    }, 16);
  }

  stop(): void {
    this.playing = false;
    if (this.timerId >= 0) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  /** 预设色块行 + 末尾"自定义"彩虹块 */
  @Builder
  colorRow(colors: string[], selected: number, custom: string, prefix: string, onSelect: (i: number) => void) {
    Row({ space: 10 }) {
      ForEach(colors, (c: string, i: number) => {
        Column()
          .width(36).height(36).borderRadius(18)
          .backgroundColor(c)
          .border({ width: selected === i ? 3 : 1, color: selected === i ? $r('app.color.accent') : '#33888888' })
          .onClick(() => onSelect(i))
      }, (c: string) => prefix + c)
      // 自定义：彩虹渐变块，选中时显示当前自定义色
      Column() {
        Text('✏️').fontSize(14)
      }
      .justifyContent(FlexAlign.Center)
      .width(36).height(36).borderRadius(18)
      .backgroundColor(selected < 0 ? custom : Color.Transparent)
      .linearGradient(selected < 0 ? undefined : {
        angle: 135,
        colors: [['#F5576C', 0], ['#FEE140', 0.5], ['#5B6BF5', 1]]
      })
      .border({ width: selected < 0 ? 3 : 1, color: selected < 0 ? $r('app.color.accent') : '#33888888' })
      .onClick(() => onSelect(-1))
    }
    .alignSelf(ItemAlign.Start)
  }

  build() {
    NavDestination() {
      if (this.playing) {
        // ── 全屏弹幕模式（横向文字滚动，点击退出）──
        Stack() {
          Text(this.text)
            .fontSize(this.fontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textColor())
            .maxLines(1)
            .width(this.textWidth())   // 显式给足宽度，避免被屏宽截断
            .translate({ x: this.offsetX })
        }
        .width('100%')
        .height('100%')
        .backgroundColor(this.bgColor())
        .alignContent(Alignment.Start)
        .onClick(() => this.stop())
      } else {
        // ── 编辑模式 ──
        Scroll() {
          Column({ space: 16 }) {
            TextInput({ placeholder: '输入弹幕内容', text: this.text })
              .height(50).borderRadius(14)
              .backgroundColor($r('app.color.bg_card'))
              .fontColor($r('app.color.text_primary'))
              .onChange((v: string) => { this.text = v; })

            Column({ space: 8 }) {
              Text('背景色').fontSize(13).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
              this.colorRow(BG_COLORS, this.bgIndex, this.customBg, 'bg', (i) => { this.bgIndex = i; })
              if (this.bgIndex < 0) {
                RgbPicker({ hexColor: this.customBg })
              }
            }
            .width('100%').padding(16).borderRadius(16)
            .backgroundColor($r('app.color.bg_card'))
            .alignItems(HorizontalAlign.Start)

            Column({ space: 8 }) {
              Text('文字色').fontSize(13).fontColor($r('app.color.text_secondary')).alignSelf(ItemAlign.Start)
              this.colorRow(TEXT_COLORS, this.textIndex, this.customText, 'tx', (i) => { this.textIndex = i; })
              if (this.textIndex < 0) {
                RgbPicker({ hexColor: this.customText })
              }
            }
            .width('100%').padding(16).borderRadius(16)
            .backgroundColor($r('app.color.bg_card'))
            .alignItems(HorizontalAlign.Start)

            // 效果预览
            Stack() {
              Text(this.text.length > 0 ? this.text : '预览')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.textColor())
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 16, right: 16 })
            }
            .width('100%').height(64)
            .borderRadius(14)
            .backgroundColor(this.bgColor())

            Column({ space: 6 }) {
              Row() {
                Text('滚动速度').fontSize(14).fontColor($r('app.color.text_secondary'))
                Blank()
                Text(this.speed.toFixed(0)).fontSize(14).fontColor($r('app.color.text_primary'))
              }.width('100%')
              Slider({ value: this.speed, min: 1, max: 10, step: 1 })
                .onChange((v: number) => { this.speed = v; })
            }
            .padding(16).borderRadius(16).backgroundColor($r('app.color.bg_card'))

            Button('▶ 开始播放（横屏效果最佳）')
              .width('100%').height(54)
              .fontSize(16).fontWeight(FontWeight.Bold)
              .linearGradient({ angle: 135, colors: [['#1A1D26', 0], ['#5B6BF5', 1]] })
              .onClick(() => this.start())

            Text('播放中点击屏幕即可退出')
              .fontSize(12).fontColor($r('app.color.text_secondary'))
          }
          .padding(20)
          .width('100%')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
    }
    .title(this.playing ? '' : '手持弹幕')
    .hideTitleBar(this.playing)
    .backgroundColor($r('app.color.bg_page'))
  }
}
