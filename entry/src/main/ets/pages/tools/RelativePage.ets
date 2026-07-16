/**
 * 亲戚称呼计算：基于关系链查表。
 * 关系链 key 用 f(父)/m(母)/h(夫)/w(妻)/s(子)/d(女)/ob(兄)/lb(弟)/os(姐)/ls(妹) 拼接。
 */
const CALL_MAP: Record<string, string> = {
  'f': '爸爸', 'm': '妈妈', 'h': '老公', 'w': '老婆',
  's': '儿子', 'd': '女儿', 'ob': '哥哥', 'lb': '弟弟', 'os': '姐姐', 'ls': '妹妹',
  'f,f': '爷爷', 'f,m': '奶奶', 'm,f': '外公', 'm,m': '外婆',
  'f,f,f': '曾祖父', 'f,f,m': '曾祖母',
  'f,ob': '伯父', 'f,lb': '叔叔', 'f,os': '姑妈', 'f,ls': '姑妈',
  'm,ob': '舅舅', 'm,lb': '舅舅', 'm,os': '姨妈', 'm,ls': '姨妈',
  'f,ob,s': '堂兄弟', 'f,ob,d': '堂姐妹', 'f,lb,s': '堂兄弟', 'f,lb,d': '堂姐妹',
  'f,os,s': '表兄弟', 'f,os,d': '表姐妹', 'f,ls,s': '表兄弟', 'f,ls,d': '表姐妹',
  'm,ob,s': '表兄弟', 'm,ob,d': '表姐妹', 'm,lb,s': '表兄弟', 'm,lb,d': '表姐妹',
  'm,os,s': '表兄弟', 'm,os,d': '表姐妹', 'm,ls,s': '表兄弟', 'm,ls,d': '表姐妹',
  's,s': '孙子', 's,d': '孙女', 'd,s': '外孙', 'd,d': '外孙女',
  's,w': '儿媳', 'd,h': '女婿',
  'ob,s': '侄子', 'ob,d': '侄女', 'lb,s': '侄子', 'lb,d': '侄女',
  'os,s': '外甥', 'os,d': '外甥女', 'ls,s': '外甥', 'ls,d': '外甥女',
  'h,f': '公公', 'h,m': '婆婆', 'w,f': '岳父', 'w,m': '岳母',
  'ob,w': '嫂子', 'lb,w': '弟妹', 'os,h': '姐夫', 'ls,h': '妹夫',
  'w,ob': '大舅子', 'w,lb': '小舅子', 'w,os': '大姨子', 'w,ls': '小姨子',
  'h,ob': '大伯子', 'h,lb': '小叔子', 'h,os': '大姑子', 'h,ls': '小姑子',
  'f,ob,w': '伯母', 'f,lb,w': '婶婶', 'f,os,h': '姑父', 'f,ls,h': '姑父',
  'm,ob,w': '舅妈', 'm,lb,w': '舅妈', 'm,os,h': '姨父', 'm,ls,h': '姨父'
};

interface RelBtn {
  key: string;
  label: string;
}

const BUTTONS: RelBtn[] = [
  { key: 'f', label: '爸' }, { key: 'm', label: '妈' },
  { key: 'h', label: '夫' }, { key: 'w', label: '妻' },
  { key: 'ob', label: '兄' }, { key: 'lb', label: '弟' },
  { key: 'os', label: '姐' }, { key: 'ls', label: '妹' },
  { key: 's', label: '子' }, { key: 'd', label: '女' }
];

@Component
export struct RelativePage {
  @State chain: string[] = [];

  result(): string {
    if (this.chain.length === 0) {
      return '我';
    }
    const key = this.chain.join(',');
    return CALL_MAP[key] ?? '关系太远啦 😅';
  }

  chainText(): string {
    if (this.chain.length === 0) {
      return '点击下方按钮构建关系';
    }
    const labels: Record<string, string> = {
      'f': '爸爸', 'm': '妈妈', 'h': '老公', 'w': '老婆',
      'ob': '哥哥', 'lb': '弟弟', 'os': '姐姐', 'ls': '妹妹', 's': '儿子', 'd': '女儿'
    };
    return '我的' + this.chain.map(c => labels[c]).join('的');
  }

  build() {
    NavDestination() {
      Column({ space: 20 }) {
        Column({ space: 10 }) {
          Text(this.chainText())
            .fontSize(14)
            .fontColor('#CCFFFFFF')
            .maxLines(2)
          Text(this.result())
            .fontSize(40)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .padding(28)
        .borderRadius(20)
        .linearGradient({ angle: 135, colors: [['#FA709A', 0], ['#FEE140', 1]] })
        .shadow({ radius: 16, color: '#FA709A55', offsetY: 6 })

        Grid() {
          ForEach(BUTTONS, (btn: RelBtn) => {
            GridItem() {
              Text(btn.label)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .height(64)
                .textAlign(TextAlign.Center)
                .borderRadius(16)
                .backgroundColor($r('app.color.bg_card'))
                .onClick(() => {
                  if (this.chain.length < 5) {
                    this.chain = [...this.chain, btn.key];
                  }
                })
            }
          }, (btn: RelBtn) => btn.key)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .height(150)

        Row({ space: 12 }) {
          Button('退一步')
            .layoutWeight(1)
            .height(48)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onClick(() => {
              this.chain = this.chain.slice(0, -1);
            })
          Button('清空')
            .layoutWeight(1)
            .height(48)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => {
              this.chain = [];
            })
        }
        .width('100%')
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('亲戚称呼')
    .backgroundColor($r('app.color.bg_page'))
  }
}
