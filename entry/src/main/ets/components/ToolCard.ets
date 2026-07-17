import { ToolInfo } from '../model/ToolRegistry';

/**
 * 工具卡片：干净卡面 + 渐变小图标块。
 * 卡面统一用 bg_card 底色，工具的渐变色只体现在左上角图标块，
 * 整页视觉安静、图标块提供识别度。
 */
@Component
export struct ToolCard {
  @Require tool: ToolInfo;
  isFavorite: boolean = false;
  onTap: (tool: ToolInfo) => void = () => {};
  onLongPress: (tool: ToolInfo) => void = () => {};
  @State pressed: boolean = false;

  build() {
    Column({ space: 10 }) {
      Row() {
        // 图标块：渐变圆角方块，emoji 或自绘字符
        Text(this.tool.glyph !== undefined ? this.tool.glyph : this.tool.emoji)
          .fontSize(this.tool.glyph !== undefined ? 20 : 22)
          .fontWeight(this.tool.glyph !== undefined ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width(40)
          .height(40)
          .borderRadius(12)
          .linearGradient({
            angle: 135,
            colors: [[(this.tool.glyphGradient ?? this.tool.gradient)[0], 0],
              [(this.tool.glyphGradient ?? this.tool.gradient)[1], 1]]
          })
        Blank()
        if (this.isFavorite) {
          Text('★')
            .fontSize(13)
            .fontColor('#FFC94D')
        }
      }
      .width('100%')

      Column({ space: 3 }) {
        Text(this.tool.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
        Text(this.tool.desc)
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(14)
    .width('100%')
    .height(108)
    .borderRadius(18)
    .backgroundColor($r('app.color.bg_card'))
    .shadow({ radius: 10, color: '#14000000', offsetY: 3 })
    .scale({ x: this.pressed ? 0.96 : 1, y: this.pressed ? 0.96 : 1 })
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
