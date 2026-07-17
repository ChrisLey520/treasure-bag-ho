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

/**
 * 敲槌：竖排 槌杆→槌头 直接相连（杆尾即头顶，不会分离），
 * 使用方外层 rotate 摆放角度/做敲击动画（旋转中心取杆顶 50%,0%）
 */
@Builder
export function WoodfishMallet(size: number) {
  Column() {
    // 槌杆
    Column()
      .width(size * 0.08)
      .height(size * 0.42)
      .borderRadius(size * 0.04)
      .backgroundColor('#6B4226')
    // 槌头（紧贴杆尾）
    Column()
      .width(size * 0.22)
      .height(size * 0.22)
      .borderRadius(size * 0.11)
      .backgroundColor('#8B5A3C')
      .shadow({ radius: size * 0.05, color: '#33000000', offsetY: size * 0.02 })
      .margin({ top: -size * 0.02 })
  }
  .alignItems(HorizontalAlign.Center)
  .width(size * 0.22)
  .height(size * 0.62)
}

/** 静态组合图标（工具卡等小尺寸场景），槌斜置右上、槌头朝向鱼身 */
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
    .rotate({ angle: 35, centerX: '50%', centerY: '10%' })
    .offset({ x: size * 0.32, y: -size * 0.3 })
  }
  .width(size * 1.25)
  .height(size * 1.15)
}
