/**
 * 图片工具类手绘图标：取色器、镜像、压缩、二维码生成、扫码、OCR、九宫格
 */

interface QrPosition {
  x: number;
  y: number;
}

interface ScanCorner {
  x: number;
  y: number;
  sx: number;
  sy: number;
}

const QR_POSITIONS: QrPosition[] = [
  { x: -7.84, y: -7.84 },
  { x: 7.84, y: -7.84 },
  { x: -7.84, y: 7.84 }
];

const SCAN_CORNERS: ScanCorner[] = [
  { x: -9.8, y: -9.8, sx: 1, sy: 1 },
  { x: 9.8, y: -9.8, sx: -1, sy: 1 },
  { x: -9.8, y: 9.8, sx: 1, sy: -1 },
  { x: 9.8, y: 9.8, sx: -1, sy: -1 }
];

/** 取色器：吸管 + 色环 */
@Builder
export function ColorPickerIcon(size: number) {
  Stack({ alignContent: Alignment.Center }) {
    // 色环背景（三色段圆环）
    Circle()
      .width(size * 0.75)
      .height(size * 0.75)
      .fillOpacity(0)
      .stroke('#FF6B6B')
      .strokeWidth(size * 0.12)
    Circle()
      .width(size * 0.75)
      .height(size * 0.75)
      .fillOpacity(0)
      .stroke('#4ECDC4')
      .strokeWidth(size * 0.12)
      .strokeDashArray([size * 0.3, size * 0.9])
    Circle()
      .width(size * 0.75)
      .height(size * 0.75)
      .fillOpacity(0)
      .stroke('#FFD93D')
      .strokeWidth(size * 0.12)
      .strokeDashArray([size * 0.3, size * 0.9])
      .strokeDashOffset(size * 0.6)

    // 吸管（斜持，管身白+吸头红）
    Column() {
      Rect()
        .width(size * 0.12)
        .height(size * 0.35)
        .fill('#FFFFFF')
        .stroke('#333333')
        .strokeWidth(size * 0.02)
        .radius(size * 0.03)
      Circle()
        .width(size * 0.18)
        .height(size * 0.18)
        .fill('#FF6B6B')
        .stroke('#333333')
        .strokeWidth(size * 0.02)
        .margin({ top: -size * 0.02 })
    }
    .rotate({ angle: -35 })
    .offset({ x: size * 0.15, y: -size * 0.1 })
  }
  .width(size)
  .height(size)
}

/** 镜像：对称的两半 */
@Builder
export function MirrorIcon(size: number) {
  Stack({ alignContent: Alignment.Center }) {
    // 中线
    Rect()
      .width(size * 0.04)
      .height(size * 0.9)
      .fill('#999999')
      .radius(size * 0.02)

    // 左半边（蓝色）
    Column() {
      Circle()
        .width(size * 0.35)
        .height(size * 0.45)
        .fill('#4A90E2')
      Rect()
        .width(size * 0.35)
        .height(size * 0.25)
        .fill('#2E6DB5')
    }
    .clip(true)
    .width(size * 0.42)
    .height(size * 0.85)
    .offset({ x: -size * 0.23, y: 0 })

    // 右半边（绿色镜像）
    Column() {
      Circle()
        .width(size * 0.35)
        .height(size * 0.45)
        .fill('#7ED321')
      Rect()
        .width(size * 0.35)
        .height(size * 0.25)
        .fill('#5BA518')
    }
    .clip(true)
    .width(size * 0.42)
    .height(size * 0.85)
    .scale({ x: -1, y: 1 })
    .offset({ x: size * 0.23, y: 0 })
  }
  .width(size)
  .height(size)
}

/** 压缩：箭头向内挤压的图片 */
@Builder
export function CompressIcon(size: number) {
  Stack({ alignContent: Alignment.Center }) {
    // 背景图片轮廓
    Rect()
      .width(size * 0.7)
      .height(size * 0.6)
      .fill('#667EEA')
      .radius(size * 0.08)

    // 左箭头
    Path()
      .width(size * 0.25)
      .height(size * 0.2)
      .commands(`M${size * 0.2} ${size * 0.1} L${size * 0.05} ${size * 0.1} L${size * 0.12} ${size * 0.05} M${size * 0.05} ${size * 0.1} L${size * 0.12} ${size * 0.15}`)
      .stroke('#FF6B6B')
      .strokeWidth(size * 0.03)
      .strokeLineCap(LineCapStyle.Round)
      .strokeLineJoin(LineJoinStyle.Round)
      .offset({ x: -size * 0.45, y: 0 })

    // 右箭头
    Path()
      .width(size * 0.25)
      .height(size * 0.2)
      .commands(`M${size * 0.05} ${size * 0.1} L${size * 0.2} ${size * 0.1} L${size * 0.13} ${size * 0.05} M${size * 0.2} ${size * 0.1} L${size * 0.13} ${size * 0.15}`)
      .stroke('#FF6B6B')
      .strokeWidth(size * 0.03)
      .strokeLineCap(LineCapStyle.Round)
      .strokeLineJoin(LineJoinStyle.Round)
      .offset({ x: size * 0.45, y: 0 })
  }
  .width(size)
  .height(size)
}

/** 二维码生成：3×3 定位点 + 中心小方块矩阵 */
@Builder
export function QrGenIcon(size: number) {
  Stack({ alignContent: Alignment.Center }) {
    // 三个角的定位框（外框 + 内实心）
    ForEach(QR_POSITIONS, (pos: QrPosition) => {
      Stack() {
        Rect()
          .width(size * 0.28)
          .height(size * 0.28)
          .fillOpacity(0)
          .stroke('#333333')
          .strokeWidth(size * 0.04)
          .radius(size * 0.02)
        Rect()
          .width(size * 0.14)
          .height(size * 0.14)
          .fill('#333333')
          .radius(size * 0.02)
      }
      .offset({ x: pos.x * size / 28, y: pos.y * size / 28 })
    })

    // 中心数据区（小方块点阵）
    Column({ space: size * 0.03 }) {
      ForEach([0, 1, 2, 3], (row: number) => {
        Row({ space: size * 0.03 }) {
          ForEach([0, 1, 2, 3], (col: number) => {
            Rect()
              .width(size * 0.06)
              .height(size * 0.06)
              .fill((row + col) % 2 === 0 ? '#333333' : Color.Transparent)
              .radius(size * 0.01)
          })
        }
      })
    }
    .offset({ x: size * 0.15, y: size * 0.15 })
  }
  .width(size)
  .height(size)
}

/** 扫码：扫描线 + 取景框 */
@Builder
export function QrScanIcon(size: number) {
  Stack({ alignContent: Alignment.Center }) {
    // 取景框四角（L 型）
    ForEach(SCAN_CORNERS, (corner: ScanCorner) => {
      Stack() {
        Rect()
          .width(size * 0.25)
          .height(size * 0.04)
          .fill('#4ECDC4')
          .radius(size * 0.02)
          .offset({ x: size * 0.105, y: 0 })
        Rect()
          .width(size * 0.04)
          .height(size * 0.25)
          .fill('#4ECDC4')
          .radius(size * 0.02)
          .offset({ x: 0, y: size * 0.105 })
      }
      .scale({ x: corner.sx, y: corner.sy })
      .offset({ x: corner.x * size / 28, y: corner.y * size / 28 })
    })

    // 扫描线（红色横线）
    Rect()
      .width(size * 0.6)
      .height(size * 0.04)
      .fill('#FF6B6B')
      .fillOpacity(0.8)
      .radius(size * 0.02)
      .offset({ y: -size * 0.1 })
  }
  .width(size)
  .height(size)
}

/** OCR：文档 + A 字母识别 */
@Builder
export function OcrIcon(size: number) {
  Stack({ alignContent: Alignment.Center }) {
    // 文档底纸（白底圆角矩形 + 顶部蓝色条）
    Column() {
      Rect()
        .width(size * 0.7)
        .height(size * 0.15)
        .fill('#4A90E2')
        .borderRadius({ topLeft: size * 0.08, topRight: size * 0.08 })
      Rect()
        .width(size * 0.7)
        .height(size * 0.6)
        .fill('#FFFFFF')
        .stroke('#CCCCCC')
        .strokeWidth(size * 0.02)
        .borderRadius({ bottomLeft: size * 0.08, bottomRight: size * 0.08 })
        .margin({ top: -size * 0.01 })
    }

    // 文本行（灰色横线）
    Column({ space: size * 0.08 }) {
      Rect()
        .width(size * 0.5)
        .height(size * 0.04)
        .fill('#DDDDDD')
        .radius(size * 0.02)
      Rect()
        .width(size * 0.49)
        .height(size * 0.04)
        .fill('#DDDDDD')
        .radius(size * 0.02)
      Rect()
        .width(size * 0.42)
        .height(size * 0.04)
        .fill('#DDDDDD')
        .radius(size * 0.02)
    }
    .offset({ y: size * 0.05 })

    // 识别标记（右上角 A 字母 + 光圈）
    Stack() {
      Circle()
        .width(size * 0.3)
        .height(size * 0.3)
        .fill('#8E2DE2')
        .fillOpacity(0.9)
      Text('A')
        .fontSize(size * 0.2)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .offset({ x: size * 0.25, y: -size * 0.28 })
  }
  .width(size)
  .height(size)
}

/** 九宫格：3×3 网格 */
@Builder
export function NineGridIcon(size: number) {
  Column({ space: size * 0.04 }) {
    ForEach([0, 1, 2], (row: number) => {
      Row({ space: size * 0.04 }) {
        ForEach([0, 1, 2], (col: number) => {
          Rect()
            .width(size * 0.26)
            .height(size * 0.26)
            .fill('#FC5C7D')
            .radius(size * 0.05)
            .fillOpacity((row * 3 + col) % 2 === 0 ? 1 : 0.5)
        })
      }
    })
  }
  .width(size)
  .height(size)
}
