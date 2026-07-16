import { preferences } from '@kit.ArkData';
import { ToolCategory, ToolInfo, TOOLS, toolsOf, searchTools } from '../model/ToolRegistry';
import { ToolCard } from '../components/ToolCard';
import { RadixPage } from './tools/RadixPage';
import { ColorPage } from './tools/ColorPage';
import { UnitPage } from './tools/UnitPage';
import { DatePage } from './tools/DatePage';
import { RelativePage } from './tools/RelativePage';
import { BmiPage } from './tools/BmiPage';
import { TimestampPage } from './tools/TimestampPage';
import { AnswerPage } from './tools/AnswerPage';
import { BannerPage } from './tools/BannerPage';
import { RainbowPage } from './tools/RainbowPage';
import { KfcPage } from './tools/KfcPage';
import { PomodoroPage } from './tools/PomodoroPage';
import { ScoreboardPage } from './tools/ScoreboardPage';
import { DecisionPage } from './tools/DecisionPage';
import { JsonPage } from './tools/JsonPage';
import { CalculatorPage } from './tools/CalculatorPage';
import { CalendarPage } from './tools/CalendarPage';
import { DogDiaryPage } from './tools/DogDiaryPage';
import { MagicTextPage } from './tools/MagicTextPage';
import { FakeCallPage } from './tools/FakeCallPage';
import { DeadPixelPage } from './tools/DeadPixelPage';
import { DeviceInfoPage } from './tools/DeviceInfoPage';
import { RegexPage } from './tools/RegexPage';
import { EncodePage } from './tools/EncodePage';
import { HashPage } from './tools/HashPage';
import { UuidPage } from './tools/UuidPage';
import { LinuxCmdPage } from './tools/LinuxCmdPage';

const PREF_NAME = 'treasure_bag';
const KEY_FAVORITES = 'favorites';

const CATEGORIES: ToolCategory[] = [
  ToolCategory.RECOMMEND,
  ToolCategory.TEXT,
  ToolCategory.LIFE,
  ToolCategory.QUERY,
  ToolCategory.DEV
];

@Entry
@Component
struct Index {
  @State currentCategory: ToolCategory = ToolCategory.RECOMMEND;
  @State keyword: string = '';
  @State favorites: string[] = [];
  pathStack: NavPathStack = new NavPathStack();
  private pref?: preferences.Preferences;

  async aboutToAppear(): Promise<void> {
    try {
      const ctx = this.getUIContext().getHostContext();
      if (ctx === undefined) {
        return;
      }
      this.pref = await preferences.getPreferences(ctx, PREF_NAME);
      const saved = this.pref.getSync(KEY_FAVORITES, '[]') as string;
      this.favorites = JSON.parse(saved) as string[];
    } catch (err) {
      console.error('load favorites failed:', JSON.stringify(err));
    }
  }

  toggleFavorite(tool: ToolInfo): void {
    if (this.favorites.includes(tool.id)) {
      this.favorites = this.favorites.filter(id => id !== tool.id);
    } else {
      this.favorites = [...this.favorites, tool.id];
    }
    try {
      this.pref?.putSync(KEY_FAVORITES, JSON.stringify(this.favorites));
      this.pref?.flush();
    } catch (err) {
      console.error('save favorites failed:', JSON.stringify(err));
    }
    this.getUIContext().getPromptAction().showToast({
      message: this.favorites.includes(tool.id) ? `已收藏「${tool.name}」` : `已取消收藏「${tool.name}」`,
      duration: 1200
    });
  }

  displayTools(): ToolInfo[] {
    if (this.keyword.trim().length > 0) {
      return searchTools(this.keyword);
    }
    return toolsOf(this.currentCategory, this.favorites);
  }

  @Builder
  toolDestination(name: string) {
    if (name === 'radix') { RadixPage() }
    else if (name === 'color') { ColorPage() }
    else if (name === 'unit') { UnitPage() }
    else if (name === 'date') { DatePage() }
    else if (name === 'relative') { RelativePage() }
    else if (name === 'bmi') { BmiPage() }
    else if (name === 'timestamp') { TimestampPage() }
    else if (name === 'answer') { AnswerPage() }
    else if (name === 'banner') { BannerPage() }
    else if (name === 'rainbow') { RainbowPage() }
    else if (name === 'kfc') { KfcPage() }
    else if (name === 'pomodoro') { PomodoroPage() }
    else if (name === 'scoreboard') { ScoreboardPage() }
    else if (name === 'decision') { DecisionPage() }
    else if (name === 'json') { JsonPage() }
    else if (name === 'calculator') { CalculatorPage() }
    else if (name === 'calendar') { CalendarPage() }
    else if (name === 'dogdiary') { DogDiaryPage() }
    else if (name === 'magictext') { MagicTextPage() }
    else if (name === 'fakecall') { FakeCallPage() }
    else if (name === 'deadpixel') { DeadPixelPage() }
    else if (name === 'deviceinfo') { DeviceInfoPage() }
    else if (name === 'regex') { RegexPage() }
    else if (name === 'encode') { EncodePage() }
    else if (name === 'hash') { HashPage() }
    else if (name === 'uuid') { UuidPage() }
    else if (name === 'linuxcmd') { LinuxCmdPage() }
  }

  build() {
    Navigation(this.pathStack) {
      Column() {
        // ── 标题 ──
        Row() {
          Column({ space: 2 }) {
            Text('百宝袋')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text(`${TOOLS.length} 个工具 · 持续更新`)
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)

          Blank()
          Text('🎒').fontSize(34)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 12 })

        // ── 搜索框 ──
        TextInput({ placeholder: '搜索工具…', text: this.keyword })
          .height(42)
          .borderRadius(21)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_secondary'))
          .margin({ left: 20, right: 20, bottom: 8 })
          .onChange((value: string) => {
            this.keyword = value;
          })

        // ── 分类 Tab ──
        if (this.keyword.trim().length === 0) {
          Scroll() {
            Row({ space: 10 }) {
              ForEach(CATEGORIES, (cat: ToolCategory) => {
                Text(cat)
                  .fontSize(14)
                  .fontWeight(this.currentCategory === cat ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(this.currentCategory === cat ? Color.White : $r('app.color.text_secondary'))
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .borderRadius(18)
                  .backgroundColor(this.currentCategory === cat ? $r('app.color.accent') : $r('app.color.bg_card'))
                  .animation({ duration: 200, curve: Curve.EaseOut })
                  .onClick(() => {
                    this.currentCategory = cat;
                  })
              }, (cat: ToolCategory) => cat)
            }
            .padding({ left: 20, right: 20 })
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .width('100%')
          .margin({ bottom: 4 })
        }

        // ── 工具宫格 ──
        Grid() {
          ForEach(this.displayTools(), (tool: ToolInfo) => {
            GridItem() {
              ToolCard({
                tool: tool,
                isFavorite: this.favorites.includes(tool.id),
                onTap: (t: ToolInfo) => {
                  this.pathStack.pushPathByName(t.id, null);
                },
                onLongPress: (t: ToolInfo) => {
                  this.toggleFavorite(t);
                }
              })
            }
          }, (tool: ToolInfo) => tool.id + (this.favorites.includes(tool.id) ? '1' : '0'))
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(14)
        .rowsGap(14)
        .padding({ left: 20, right: 20, top: 8, bottom: 20 })
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        if (this.displayTools().length === 0) {
          Column({ space: 8 }) {
            Text('🔍').fontSize(40)
            Text('没有找到相关工具')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
          .margin({ bottom: 60 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))
      .padding({ top: 36 })
    }
    .navDestination(this.toolDestination)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
  }
}
