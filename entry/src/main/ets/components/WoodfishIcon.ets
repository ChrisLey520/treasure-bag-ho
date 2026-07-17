/**
 * 自绘木鱼图标（Unicode 无木鱼 emoji，🪵 是木头）。
 * 造型：顶部小圆钮 + 圆润鱼身 + 嘴部开口 + 右侧敲槌。
 * 页面与服务卡片共用；size 为主体直径。
 */
@Builder
export function WoodfishIcon(size: number) {
  Stack({ alignContent: Alignment.Center }) {
    // 鱼身：圆润椭圆，木色渐变
    Column()
      .width(size)
      .height(size * 0.82)
      .borderRadius(size / 2)
      .linearGradient({ angle: 135, colors: [['#C89F82', 0], ['#8B5A3C', 1]] })
      .shadow({ radius: size * 0.08, color: '#4D000000', offsetY: size * 0.04 })
      .offset({ x: 0, y: size * 0.06 })
    // 顶部圆钮
    Column()
      .width(size * 0.22)
      .height(size * 0.14)
      .borderRadius(size * 0.08)
      .backgroundColor('#8B5A3C')
      .offset({ x: 0, y: -size * 0.36 })
    // 嘴部开口：深色弧缝
    Column()
      .width(size * 0.62)
      .height(size * 0.13)
      .borderRadius(size * 0.08)
      .backgroundColor('#4A2E1D')
      .offset({ x: 0, y: size * 0.22 })
    // 敲槌：右上斜放（槌杆 + 槌头）
    Column()
      .width(size * 0.5)
      .height(size * 0.07)
      .borderRadius(size * 0.04)
      .backgroundColor('#6B4226')
      .rotate({ angle: -40 })
      .offset({ x: size * 0.38, y: -size * 0.28 })
    Column()
      .width(size * 0.16)
      .height(size * 0.16)
      .borderRadius(size * 0.08)
      .backgroundColor('#8B5A3C')
      .offset({ x: size * 0.56, y: -size * 0.42 })
  }
  .width(size * 1.3)
  .height(size * 1.2)
}
