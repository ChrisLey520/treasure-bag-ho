@Component
export struct RegexPage {
  @State pattern: string = '';
  @State flags: string = 'g';
  @State testText: string = '';
  @State error: string = '';

  matches(): string[] {
    this.error = '';
    if (this.pattern.length === 0 || this.testText.length === 0) {
      return [];
    }
    try {
      const re = new RegExp(this.pattern, this.flags);
      const result: string[] = [];
      if (this.flags.includes('g')) {
        let m = re.exec(this.testText);
        let guard = 0;
        while (m !== null && guard < 200) {
          result.push(m[0]);
          if (m[0].length === 0) {
            re.lastIndex += 1; // 防空匹配死循环
          }
          m = re.exec(this.testText);
          guard += 1;
        }
      } else {
        const m = re.exec(this.testText);
        if (m !== null) {
          result.push(m[0]);
        }
      }
      return result;
    } catch (e) {
      this.error = (e as Error).message;
      return [];
    }
  }

  toggleFlag(f: string): void {
    if (this.flags.includes(f)) {
      this.flags = this.flags.split(f).join('');
    } else {
      this.flags += f;
    }
  }

  @Builder
  flagChip(f: string, label: string) {
    Text(`${f} ${label}`)
      .fontSize(12)
      .fontColor(this.flags.includes(f) ? Color.White : $r('app.color.text_secondary'))
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(14)
      .backgroundColor(this.flags.includes(f) ? $r('app.color.accent') : $r('app.color.bg_card'))
      .onClick(() => this.toggleFlag(f))
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        TextInput({ placeholder: '正则表达式，如 \\d+', text: this.pattern })
          .height(48).borderRadius(14)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.pattern = v; })

        Row({ space: 8 }) {
          this.flagChip('g', '全局')
          this.flagChip('i', '忽略大小写')
          this.flagChip('m', '多行')
          this.flagChip('s', '点匹配换行')
        }
        .alignSelf(ItemAlign.Start)

        TextArea({ placeholder: '待匹配的文本…', text: this.testText })
          .layoutWeight(2)
          .borderRadius(14)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .fontSize(14)
          .onChange((v: string) => { this.testText = v; })

        if (this.error.length > 0) {
          Text('表达式错误：' + this.error)
            .fontSize(13).fontColor('#F5576C')
            .width('100%').padding(12)
            .borderRadius(10).backgroundColor('#1AF5576C')
        }

        Column({ space: 8 }) {
          Text(`匹配结果（${this.matches().length} 个${this.matches().length >= 200 ? '，已截断' : ''}）`)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .alignSelf(ItemAlign.Start)
          Scroll() {
            Column({ space: 6 }) {
              ForEach(this.matches().slice(0, 100), (m: string, i: number) => {
                Text(m.length > 0 ? m : '(空串)')
                  .fontSize(14)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .borderRadius(8)
                  .backgroundColor('#1A5B6BF5')
              }, (m: string, i: number) => i + m)
            }
            .width('100%')
          }
          .layoutWeight(1)
          .align(Alignment.TopStart)
        }
        .layoutWeight(2)
        .width('100%')
        .padding(14)
        .borderRadius(14)
        .backgroundColor($r('app.color.bg_card'))
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('正则测试')
    .backgroundColor($r('app.color.bg_page'))
  }
}
