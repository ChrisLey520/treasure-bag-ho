interface UnitDef {
  name: string;
  factor: number; // 相对基准单位
}

interface UnitGroup {
  name: string;
  units: UnitDef[];
}

const GROUPS: UnitGroup[] = [
  {
    name: '长度', units: [
      { name: '毫米', factor: 0.001 },
      { name: '厘米', factor: 0.01 },
      { name: '米', factor: 1 },
      { name: '千米', factor: 1000 },
      { name: '英寸', factor: 0.0254 },
      { name: '英尺', factor: 0.3048 },
      { name: '英里', factor: 1609.344 }
    ]
  },
  {
    name: '重量', units: [
      { name: '克', factor: 1 },
      { name: '千克', factor: 1000 },
      { name: '斤', factor: 500 },
      { name: '两', factor: 50 },
      { name: '吨', factor: 1000000 },
      { name: '磅', factor: 453.592 },
      { name: '盎司', factor: 28.3495 }
    ]
  },
  {
    name: '面积', units: [
      { name: '平方米', factor: 1 },
      { name: '平方千米', factor: 1000000 },
      { name: '公顷', factor: 10000 },
      { name: '亩', factor: 666.667 },
      { name: '平方英尺', factor: 0.0929 }
    ]
  },
  {
    name: '存储', units: [
      { name: 'B', factor: 1 },
      { name: 'KB', factor: 1024 },
      { name: 'MB', factor: 1048576 },
      { name: 'GB', factor: 1073741824 },
      { name: 'TB', factor: 1099511627776 }
    ]
  }
];

@Component
export struct UnitPage {
  @State groupIndex: number = 0;
  @State fromIndex: number = 2;
  @State input: string = '1';

  results(): string[] {
    const group = GROUPS[this.groupIndex];
    const from = group.units[Math.min(this.fromIndex, group.units.length - 1)];
    const v = parseFloat(this.input);
    if (isNaN(v)) {
      return group.units.map(() => '—');
    }
    const base = v * from.factor;
    return group.units.map(u => {
      const r = base / u.factor;
      return r >= 1e12 || (r < 1e-6 && r > 0) ? r.toExponential(4) : parseFloat(r.toPrecision(10)).toString();
    });
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        Scroll() {
          Row({ space: 10 }) {
            ForEach(GROUPS, (g: UnitGroup, i: number) => {
              Text(g.name)
                .fontSize(14)
                .fontColor(this.groupIndex === i ? Color.White : $r('app.color.text_secondary'))
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .borderRadius(16)
                .backgroundColor(this.groupIndex === i ? $r('app.color.accent') : $r('app.color.bg_card'))
                .onClick(() => {
                  this.groupIndex = i;
                  this.fromIndex = 0;
                })
            }, (g: UnitGroup) => g.name)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        Row({ space: 10 }) {
          TextInput({ text: this.input })
            .type(InputType.NUMBER_DECIMAL)
            .height(50)
            .layoutWeight(1)
            .borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onChange((v: string) => { this.input = v; })

          Text(GROUPS[this.groupIndex].units[Math.min(this.fromIndex, GROUPS[this.groupIndex].units.length - 1)].name)
            .fontSize(15)
            .fontColor(Color.White)
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .borderRadius(14)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => {
              this.fromIndex = (this.fromIndex + 1) % GROUPS[this.groupIndex].units.length;
            })
        }
        .width('100%')

        List({ space: 10 }) {
          ForEach(GROUPS[this.groupIndex].units, (u: UnitDef, i: number) => {
            ListItem() {
              Row() {
                Text(u.name).fontSize(14).fontColor($r('app.color.text_secondary'))
                Blank()
                Text(this.results()[i])
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))
                  .copyOption(CopyOptions.LocalDevice)
              }
              .width('100%')
              .padding(16)
              .borderRadius(14)
              .backgroundColor($r('app.color.bg_card'))
            }
          }, (u: UnitDef) => GROUPS[this.groupIndex].name + u.name)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('单位换算')
    .backgroundColor($r('app.color.bg_page'))
  }
}
