/**
 * 自绘木鱼（Unicode 无木鱼 emoji，🪵 是木头）。
 * WoodfishBody：鱼身（圆润椭圆 + 顶钮 + 嘴部开口）
 * WoodfishMallet：敲槌（槌杆 + 槌头），独立组件便于做敲击摆动动画
 * WoodfishIcon：静态组合（工具卡图标等小尺寸场景用）
 */

@Builder
export function WoodfishBody(size: number) {
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
  }
  .width(size * 1.05)
  .height(size)
}

@Builder
export function WoodfishMallet(size: number) {
  Stack({ alignContent: Alignment.TopStart }) {
    // 槌杆（斜放）
    Column()
      .width(size * 0.52)
      .height(size * 0.08)
      .borderRadius(size * 0.04)
      .backgroundColor('#6B4226')
      .rotate({ angle: -40, centerX: '10%', centerY: '50%' })
      .offset({ x: size * 0.12, y: size * 0.3 })
    // 槌头（在杆的高端）
    Column()
      .width(size * 0.2)
      .height(size * 0.2)
      .borderRadius(size * 0.1)
      .backgroundColor('#8B5A3C')
      .shadow({ radius: size * 0.05, color: '#33000000', offsetY: size * 0.02 })
      .offset({ x: 0, y: size * 0.02 })
  }
  .width(size * 0.62)
  .height(size * 0.55)
}

/** 静态组合图标（工具卡等小尺寸场景），槌置于右上 */
@Builder
export function WoodfishIcon(size: number) {
  Stack({ alignContent: Alignment.Center }) {
    Column() {
      WoodfishBody(size * 0.85)
    }
    .offset({ x: -size * 0.05, y: size * 0.08 })
    Column() {
      WoodfishMallet(size * 0.85)
    }
    .offset({ x: size * 0.3, y: -size * 0.28 })
  }
  .width(size * 1.25)
  .height(size * 1.15)
}
