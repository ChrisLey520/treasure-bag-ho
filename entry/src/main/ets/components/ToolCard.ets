import { ToolInfo } from '../model/ToolRegistry';

@Component
export struct ToolCard {
  @Require tool: ToolInfo;
  isFavorite: boolean = false;
  onTap: (tool: ToolInfo) => void = () => {};
  onLongPress: (tool: ToolInfo) => void = () => {};
  @State pressed: boolean = false;

  build() {
    Column({ space: 6 }) {
      Row() {
        if (this.tool.glyph !== undefined) {
          // 自绘徽标：渐变圆角方块 + 字符（与服务卡片品牌徽标一致）
          Text(this.tool.glyph)
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .width(32)
            .height(32)
            .borderRadius(9)
            .linearGradient({
              angle: 135,
              colors: [[(this.tool.glyphGradient ?? this.tool.gradient)[0], 0],
                [(this.tool.glyphGradient ?? this.tool.gradient)[1], 1]]
            })
            .border({ width: 1, color: '#4DFFFFFF' })
            .shadow({ radius: 6, color: '#33000000', offsetY: 2 })
        } else {
          Text(this.tool.emoji)
            .fontSize(30)
        }
        Blank()
        if (this.isFavorite) {
          Text('★')
            .fontSize(14)
            .fontColor('#FFD700')
        }
      }
      .width('100%')

      Blank()

      Text(this.tool.name)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .maxLines(1)

      Text(this.tool.desc)
        .fontSize(11)
        .fontColor('#CCFFFFFF')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .alignItems(HorizontalAlign.Start)
    .padding(14)
    .width('100%')
    .height(110)
    .borderRadius(20)
    .linearGradient({
      angle: 135,
      colors: [[this.tool.gradient[0], 0], [this.tool.gradient[1], 1]]
    })
    .shadow({ radius: 12, color: this.tool.gradient[0] + '55', offsetY: 4 })
    .scale({ x: this.pressed ? 0.95 : 1, y: this.pressed ? 0.95 : 1 })
    .animation({ duration: 150, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => this.onTap(this.tool))
    .gesture(LongPressGesture().onAction(() => this.onLongPress(this.tool)))
  }
}
