/** 队伍渐变配色池（按加入顺序取用） */
const TEAM_COLORS: [string, string][] = [
  ['#F5576C', '#F093FB'],
  ['#4FACFE', '#00F2FE'],
  ['#43E97B', '#38F9D7'],
  ['#F7971E', '#FFD200'],
  ['#8E2DE2', '#4A00E0'],
  ['#30CFD0', '#330867']
];

const DEFAULT_NAMES: string[] = ['红队', '蓝队', '绿队', '黄队', '紫队', '青队'];

interface Team {
  name: string;
  score: number;
}

@Component
export struct ScoreboardPage {
  @State teams: Team[] = [
    { name: '红队', score: 0 },
    { name: '蓝队', score: 0 }
  ];

  private addTeam(): void {
    if (this.teams.length >= 6) {
      return;
    }
    const idx = this.teams.length;
    this.teams = [...this.teams, { name: DEFAULT_NAMES[idx], score: 0 } as Team];
  }

  private removeTeam(): void {
    if (this.teams.length <= 2) {
      return;
    }
    this.teams = this.teams.slice(0, this.teams.length - 1);
  }

  private bump(i: number, delta: number): void {
    // @State 数组元素属性变更不触发刷新，整体替换
    this.teams = this.teams.map((t: Team, j: number): Team =>
      j === i ? { name: t.name, score: Math.max(0, t.score + delta) } as Team : t);
  }

  /**
   * 记分面板。@Builder 值参数不参与状态观察，须传索引、内部直读 @State
   */
  @Builder
  scorePanel(i: number) {
    Column({ space: this.teams.length > 2 ? 6 : 14 }) {
      Text(this.teams[i].name)
        .fontSize(this.teams.length > 2 ? 15 : 18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)

      Text(this.teams[i].score.toString())
        .fontSize(this.teams.length > 4 ? 44 : (this.teams.length > 2 ? 56 : 80))
        .fontWeight(FontWeight.Bolder)
        .fontColor(Color.White)

      Row({ space: 14 }) {
        Button('−')
          .width(this.teams.length > 2 ? 44 : 56)
          .height(this.teams.length > 2 ? 44 : 56)
          .fontSize(this.teams.length > 2 ? 20 : 26)
          .backgroundColor('#33FFFFFF')
          .onClick(() => this.bump(i, -1))
        Button('+')
          .width(this.teams.length > 2 ? 44 : 56)
          .height(this.teams.length > 2 ? 44 : 56)
          .fontSize(this.teams.length > 2 ? 20 : 26)
          .backgroundColor('#4DFFFFFF')
          .onClick(() => this.bump(i, 1))
      }
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height('100%')
    .borderRadius(20)
    .linearGradient({
      angle: 135,
      colors: [[TEAM_COLORS[i % TEAM_COLORS.length][0], 0], [TEAM_COLORS[i % TEAM_COLORS.length][1], 1]]
    })
    .onClick(() => this.bump(i, 1))
  }

  build() {
    NavDestination() {
      Column({ space: 14 }) {
        // 队伍宫格：1-2 队单列、3+ 队双列
        Grid() {
          ForEach(this.teams, (t: Team, i: number) => {
            GridItem() {
              this.scorePanel(i)
            }
          }, (t: Team, i: number) => `${i}-${t.name}`)
        }
        .columnsTemplate(this.teams.length <= 2 ? '1fr' : '1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Row({ space: 10 }) {
          Button('− 减一方')
            .layoutWeight(1).height(48)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor(this.teams.length > 2 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
            .enabled(this.teams.length > 2)
            .onClick(() => this.removeTeam())
          Button('+ 加一方')
            .layoutWeight(1).height(48)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor(this.teams.length < 6 ? $r('app.color.text_primary') : $r('app.color.text_secondary'))
            .enabled(this.teams.length < 6)
            .onClick(() => this.addTeam())
          Button('重置')
            .layoutWeight(1).height(48)
            .backgroundColor($r('app.color.bg_card'))
            .fontColor($r('app.color.text_primary'))
            .onClick(() => {
              this.teams = this.teams.map((t: Team): Team => ({ name: t.name, score: 0 } as Team));
            })
        }
        .width('100%')
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('记分牌')
    .backgroundColor($r('app.color.bg_page'))
  }
}
