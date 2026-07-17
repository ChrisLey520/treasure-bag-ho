let storageScore = new LocalStorage();

/** 队伍渐变配色池（与 App 内一致） */
const TEAM_COLORS: [string, string][] = [
  ['#F5576C', '#F093FB'],
  ['#4FACFE', '#00F2FE'],
  ['#43E97B', '#38F9D7'],
  ['#F7971E', '#FFD200']
];

const TEAM_NAMES: string[] = ['红队', '蓝队', '绿队', '黄队'];

interface Team {
  name: string;
  score: number;
}

/**
 * 记分牌服务卡片（2×2/2×4）：2-4 方计分。
 * 点面板 +1、− 键减分、品牌行「归零」重置、±方 调队数、点标题进 App。
 */
@Entry(storageScore)
@Component
struct ScoreCard {
  @State teams: Team[] = [
    { name: '红队', score: 0 },
    { name: '蓝队', score: 0 }
  ];

  private bump(i: number, delta: number): void {
    this.teams = this.teams.map((t: Team, j: number): Team =>
      j === i ? { name: t.name, score: Math.max(0, t.score + delta) } as Team : t);
  }

  private resize(delta: number): void {
    const n = this.teams.length + delta;
    if (n < 2 || n > 4) {
      return;
    }
    if (delta > 0) {
      this.teams = [...this.teams, { name: TEAM_NAMES[this.teams.length], score: 0 } as Team];
    } else {
      this.teams = this.teams.slice(0, n);
    }
  }

  @Builder
  panel(i: number) {
    Column({ space: 2 }) {
      Text(this.teams[i].name)
        .fontSize(9)
        .fontWeight(FontWeight.Medium)
        .fontColor('#CCFFFFFF')
      Text(this.teams[i].score.toString())
        .fontSize(this.teams.length > 2 ? 22 : 32)
        .fontWeight(FontWeight.Bolder)
        .fontColor(Color.White)
        .layoutWeight(1)
      Text('−')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width('100%')
        .height(18)
        .borderRadius(6)
        .backgroundColor('#33000000')
        .onClick(() => this.bump(i, -1))
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(6)
    .layoutWeight(1)
    .height('100%')
    .borderRadius(12)
    .linearGradient({
      angle: 135,
      colors: [[TEAM_COLORS[i % TEAM_COLORS.length][0], 0], [TEAM_COLORS[i % TEAM_COLORS.length][1], 1]]
    })
    .onClick(() => this.bump(i, 1))
  }

  build() {
    Column({ space: 6 }) {
      // 品牌行：标题进 App；右侧 −方/+方/归零
      Row({ space: 4 }) {
        Text('🏆')
          .fontSize(11)
        Text('记分牌')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_secondary'))
        Blank()
        Text('−方')
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.teams.length > 2 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .borderRadius(7)
          .backgroundColor($r('app.color.bg_card'))
          .onClick(() => this.resize(-1))
        Text('+方')
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.teams.length < 4 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .borderRadius(7)
          .backgroundColor($r('app.color.bg_card'))
          .onClick(() => this.resize(1))
        Text('归零')
          .fontSize(9)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .borderRadius(7)
          .backgroundColor($r('app.color.bg_card'))
          .onClick(() => {
            this.teams = this.teams.map((t: Team): Team => ({ name: t.name, score: 0 } as Team));
          })
      }
      .width('100%')
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { targetTool: 'scoreboard' }
        });
      })

      // 队伍布局（卡片不支持 Grid）：2 队一行，3-4 队上下两行
      if (this.teams.length <= 2) {
        Row({ space: 6 }) {
          this.panel(0)
          this.panel(1)
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        Column({ space: 6 }) {
          Row({ space: 6 }) {
            this.panel(0)
            this.panel(1)
          }
          .width('100%')
          .layoutWeight(1)

          Row({ space: 6 }) {
            this.panel(2)
            if (this.teams.length >= 4) {
              this.panel(3)
            } else {
              // 3 队时占位保持宽度一致
              Text('')
                .layoutWeight(1)
                .height('100%')
            }
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .padding(10)
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
