import { audio } from '@kit.AudioKit';

interface NoiseType {
  key: string;
  name: string;
  emoji: string;
  gradient: [string, string];
}

const NOISE_TYPES: NoiseType[] = [
  { key: 'white', name: '白噪音', emoji: '📻', gradient: ['#8E9EAB', '#EEF2F3'] },
  { key: 'pink', name: '粉噪音', emoji: '🌸', gradient: ['#FFAFBD', '#FFC3A0'] },
  { key: 'brown', name: '布朗噪音', emoji: '🌊', gradient: ['#6D6027', '#D3CBB8'] }
];

/**
 * 白噪音：AudioRenderer + writeData 回调实时生成 PCM，无需打包音频资源。
 * 白噪音 = 均匀随机；粉噪音 = Voss-McCartney 近似；布朗噪音 = 随机游走。
 */
@Component
export struct WhiteNoisePage {
  @State playing: boolean = false;
  @State typeIndex: number = 0;
  @State volume: number = 60;
  private renderer?: audio.AudioRenderer;
  // 粉噪音状态
  private pinkRows: number[] = [0, 0, 0, 0, 0, 0, 0];
  private pinkCounter: number = 0;
  // 布朗噪音状态
  private brownLast: number = 0;

  aboutToDisappear(): void {
    this.stop();
  }

  nextSample(): number {
    const type = NOISE_TYPES[this.typeIndex].key;
    if (type === 'white') {
      return Math.random() * 2 - 1;
    }
    if (type === 'pink') {
      // Voss-McCartney：多行随机数按 bit 更新求和
      this.pinkCounter = (this.pinkCounter + 1) & 0x7f;
      for (let i = 0; i < this.pinkRows.length; i++) {
        if ((this.pinkCounter & ((1 << i) - 1)) === 0) {
          this.pinkRows[i] = Math.random() * 2 - 1;
        }
      }
      let sum = 0;
      for (const v of this.pinkRows) {
        sum += v;
      }
      return sum / this.pinkRows.length;
    }
    // brown：随机游走 + 回中
    this.brownLast += (Math.random() * 2 - 1) * 0.02;
    this.brownLast = Math.max(-1, Math.min(1, this.brownLast * 0.999));
    return this.brownLast * 3.5;
  }

  async start(): Promise<void> {
    if (this.playing) {
      return;
    }
    try {
      const streamInfo: audio.AudioStreamInfo = {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
        channels: audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      };
      const rendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      };
      this.renderer = await audio.createAudioRenderer({
        streamInfo: streamInfo,
        rendererInfo: rendererInfo
      });
      this.renderer.on('writeData', (buffer: ArrayBuffer) => {
        const view = new Int16Array(buffer);
        const gain = this.volume / 100 * 0.5;
        for (let i = 0; i < view.length; i++) {
          const s = Math.max(-1, Math.min(1, this.nextSample() * gain));
          view[i] = Math.round(s * 32767);
        }
        return audio.AudioDataCallbackResult.VALID;
      });
      await this.renderer.start();
      this.playing = true;
    } catch (err) {
      console.error('audio start failed:', JSON.stringify(err));
      this.getUIContext().getPromptAction().showToast({ message: '音频初始化失败', duration: 1500 });
    }
  }

  async stop(): Promise<void> {
    if (this.renderer !== undefined) {
      try {
        await this.renderer.stop();
        await this.renderer.release();
      } catch (err) {
        console.error('audio stop failed:', JSON.stringify(err));
      }
      this.renderer = undefined;
    }
    this.playing = false;
  }

  async switchType(i: number): Promise<void> {
    this.typeIndex = i;
    // 重置生成器状态
    this.pinkRows = [0, 0, 0, 0, 0, 0, 0];
    this.brownLast = 0;
  }

  build() {
    NavDestination() {
      Column({ space: 24 }) {
        Blank()

        Text(NOISE_TYPES[this.typeIndex].emoji)
          .fontSize(80)
          .scale({
            x: this.playing ? 1.1 : 1,
            y: this.playing ? 1.1 : 1
          })
          .animation({ duration: 800, curve: Curve.EaseInOut })

        Text(this.playing ? '正在播放 · 助眠专注两相宜' : '选择噪音类型，点击播放')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))

        Row({ space: 12 }) {
          ForEach(NOISE_TYPES, (t: NoiseType, i: number) => {
            Column({ space: 6 }) {
              Text(t.emoji).fontSize(26)
              Text(t.name)
                .fontSize(13)
                .fontWeight(this.typeIndex === i ? FontWeight.Bold : FontWeight.Normal)
                .fontColor(this.typeIndex === i ? Color.White : $r('app.color.text_secondary'))
            }
            .width(90)
            .padding({ top: 14, bottom: 14 })
            .borderRadius(18)
            .backgroundColor(this.typeIndex === i ? $r('app.color.accent') : $r('app.color.bg_card'))
            .onClick(() => this.switchType(i))
          }, (t: NoiseType) => t.key)
        }

        Column({ space: 6 }) {
          Row() {
            Text('音量').fontSize(13).fontColor($r('app.color.text_secondary'))
            Blank()
            Text(`${this.volume}%`).fontSize(13).fontColor($r('app.color.text_primary'))
          }.width('100%')
          Slider({ value: this.volume, min: 10, max: 100 })
            .onChange((v: number) => { this.volume = v; })
        }
        .width('80%')
        .padding(16)
        .borderRadius(16)
        .backgroundColor($r('app.color.bg_card'))

        Button(this.playing ? '⏸ 停止' : '▶ 播放')
          .width(180).height(54)
          .fontSize(17).fontWeight(FontWeight.Bold)
          .linearGradient({
            angle: 135,
            colors: [[NOISE_TYPES[this.typeIndex].gradient[0], 0], [NOISE_TYPES[this.typeIndex].gradient[1], 1]]
          })
          .onClick(() => {
            if (this.playing) {
              this.stop();
            } else {
              this.start();
            }
          })

        Blank()
        Blank()
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('白噪音')
    .backgroundColor($r('app.color.bg_page'))
  }
}
