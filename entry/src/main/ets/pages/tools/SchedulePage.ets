import { ToolStore } from '../../utils/ToolStore';
import { pasteboard } from '@kit.BasicServicesKit';

/**
 * 课程表：周视图 + 单双周课程 + 增删改 + WakeUp 兼容格式导入导出。
 * 数据模型与 WakeUp 课程表（开源，业界通用交换格式）对齐：
 * CourseBase {id, courseName, color} + CourseDetail {id, day, room, teacher,
 * startNode, step, startWeek, endWeek, type(0每周/1单周/2双周)}
 */

interface CourseBase {
  id: number;
  courseName: string;
  color: string;
  tableId: number;
}

interface CourseDetail {
  id: number;          // 对应 CourseBase.id
  day: number;         // 1-7 周一~周日
  room: string;
  teacher: string;
  startNode: number;   // 1 起
  step: number;        // 连续节数
  startWeek: number;
  endWeek: number;
  type: number;        // 0 每周 1 单周 2 双周
  tableId: number;
}

interface ScheduleTable {
  name: string;
  startDate: string;   // 'YYYY-MM-DD' 学期第一周周一
  maxWeek: number;
  nodes: number;       // 每天节数
}

interface ScheduleData {
  table: ScheduleTable;
  courses: CourseBase[];
  details: CourseDetail[];
  times?: string[][];   // 每节 [开始, 结束]，与 nodes 等长
}

/** WakeUp 导出第 1/2/3 行的结构 */
interface WakeTimeTable {
  id: number;
  name: string;
  sameLen: boolean;
  courseLen: number;
}

interface WakeTimeDetail {
  node: number;
  startTime: string;
  endTime: string;
  timeTable: number;
}

interface WakeTable {
  id: number;
  tableName: string;
  nodes: number;
  startDate: string;
  maxWeek: number;
  showSat: boolean;
  showSun: boolean;
  sundayFirst: boolean;
  type: number;
}

const STORE_KEY = 'schedule';
const DAY_NAMES: string[] = ['一', '二', '三', '四', '五', '六', '日'];
const TYPE_NAMES: string[] = ['每周', '单周', '双周'];
const COURSE_COLORS: string[] = [
  '#F5576C', '#4FACFE', '#43E97B', '#F7971E', '#8E2DE2', '#30CFD0',
  '#EC008C', '#56AB2F', '#FF512F', '#5B6BF5', '#B79891', '#1BCEDF'
];
/** 默认 12 节作息（导出 WakeUp 第 2 行用） */
const DEFAULT_TIMES: string[][] = [
  ['08:00', '08:45'], ['08:55', '09:40'], ['10:00', '10:45'], ['10:55', '11:40'],
  ['14:00', '14:45'], ['14:55', '15:40'], ['16:00', '16:45'], ['16:55', '17:40'],
  ['19:00', '19:45'], ['19:55', '20:40'], ['20:50', '21:35'], ['21:45', '22:30']
];

function todayStr(): string {
  const d = new Date();
  return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
}

/** 本周周一 */
function mondayStr(): string {
  const d = new Date();
  const wd = d.getDay() === 0 ? 7 : d.getDay();
  d.setDate(d.getDate() - (wd - 1));
  return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
}

@Component
export struct SchedulePage {
  @State table: ScheduleTable = { name: '我的课表', startDate: mondayStr(), maxWeek: 20, nodes: 12 };
  @State courses: CourseBase[] = [];
  @State details: CourseDetail[] = [];
  @State times: string[][] = [];   // 每节 [开始, 结束]（默认作息，可在设置里改）
  @State curWeek: number = 1;
  @State rev: number = 0;          // 数据版本号：进 ForEach key 破除旧缓存（否则改课后当前视图不刷新）
  @State showEdit: boolean = false;
  @State showSettings: boolean = false;
  @State editTimeNode: number = -1;   // 正在编辑起止时间的节次（1 起，-1 无）
  // ── 作息快速生成参数 ──
  @State genStart: string = '08:00';  // 首节开始
  @State genLen: number = 45;         // 每节时长（分钟）
  @State genBreak: number = 10;       // 课间休息（分钟）
  @State genLunchAfter: number = 4;   // 第 N 节后午休（0 不设）
  @State genLunchMin: number = 120;   // 午休时长
  @State genDinnerAfter: number = 8;  // 第 N 节后晚休（0 不设）
  @State genDinnerMin: number = 80;   // 晚休时长
  @State toast: string = '';
  // ── 编辑表单状态（editDetailId < 0 为新增） ──
  @State editDetailId: number = -1;
  @State fName: string = '';
  @State fTeacher: string = '';
  @State fRoom: string = '';
  @State fDay: number = 1;
  @State fStartNode: number = 1;
  @State fStep: number = 2;
  @State fStartWeek: number = 1;
  @State fEndWeek: number = 20;
  @State fType: number = 0;
  private toastTimer: number = -1;

  async aboutToAppear(): Promise<void> {
    const ctx = this.getUIContext().getHostContext();
    if (ctx === undefined) {
      return;
    }
    const saved = await ToolStore.get(ctx, STORE_KEY, '');
    if (saved.length > 0) {
      try {
        const data = JSON.parse(saved) as ScheduleData;
        this.table = data.table;
        this.courses = data.courses;
        this.details = data.details;
        this.times = data.times ?? [];
      } catch (err) {
        console.error('parse schedule failed:', JSON.stringify(err));
      }
    }
    this.ensureTimes();
    this.curWeek = this.weekOfToday();
  }

  /** times 与节数对齐：不足补默认作息，超出截断 */
  private ensureTimes(): void {
    const arr: string[][] = [];
    for (let i = 0; i < this.table.nodes; i++) {
      if (i < this.times.length && this.times[i].length === 2) {
        arr.push(this.times[i]);
      } else {
        const t = DEFAULT_TIMES[i % DEFAULT_TIMES.length];
        arr.push([t[0], t[1]]);
      }
    }
    this.times = arr;
  }

  aboutToDisappear(): void {
    if (this.toastTimer >= 0) {
      clearTimeout(this.toastTimer);
    }
  }

  persist(): void {
    this.rev += 1;   // 数据变更 → 网格 ForEach key 变化，强制重渲染
    const data: ScheduleData = { table: this.table, courses: this.courses, details: this.details, times: this.times };
    ToolStore.save(STORE_KEY, JSON.stringify(data));
  }

  private showToast(msg: string): void {
    this.getUIContext().getPromptAction().showToast({ message: msg, duration: 2000 });
  }

  /** 今天是学期第几周（1 起，超界收敛） */
  weekOfToday(): number {
    const parts = this.table.startDate.split('-');
    const start = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const diff = Math.floor((today.getTime() - start.getTime()) / 86400000);
    const w = Math.floor(diff / 7) + 1;
    return Math.max(1, Math.min(this.table.maxWeek, w));
  }

  /** 某排课在指定周是否上课（单双周判定） */
  private activeInWeek(dt: CourseDetail, week: number): boolean {
    if (week < dt.startWeek || week > dt.endWeek) {
      return false;
    }
    if (dt.type === 1) {
      return week % 2 === 1;
    }
    if (dt.type === 2) {
      return week % 2 === 0;
    }
    return true;
  }

  private courseOf(id: number): CourseBase | undefined {
    for (const c of this.courses) {
      if (c.id === id) {
        return c;
      }
    }
    return undefined;
  }

  /** 当前周、某天、某节起始的排课（用于网格渲染定位） */
  private detailAt(day: number, node: number): CourseDetail | undefined {
    for (const dt of this.details) {
      if (dt.day === day && dt.startNode === node && this.activeInWeek(dt, this.curWeek)) {
        return dt;
      }
    }
    return undefined;
  }

  /** 该格是否被上方跨节课程覆盖 */
  private coveredAt(day: number, node: number): boolean {
    for (const dt of this.details) {
      if (dt.day === day && this.activeInWeek(dt, this.curWeek) &&
        node > dt.startNode && node < dt.startNode + dt.step) {
        return true;
      }
    }
    return false;
  }

  // ════════ 增删改 ════════
  private openAdd(day: number, node: number): void {
    this.editDetailId = -1;
    this.fName = '';
    this.fTeacher = '';
    this.fRoom = '';
    this.fDay = day;
    this.fStartNode = node;
    this.fStep = 2;
    this.fStartWeek = 1;
    this.fEndWeek = this.table.maxWeek;
    this.fType = 0;
    this.showEdit = true;
  }

  private openEdit(dt: CourseDetail): void {
    const c = this.courseOf(dt.id);
    this.editDetailId = this.details.indexOf(dt);
    this.fName = c !== undefined ? c.courseName : '';
    this.fTeacher = dt.teacher;
    this.fRoom = dt.room;
    this.fDay = dt.day;
    this.fStartNode = dt.startNode;
    this.fStep = dt.step;
    this.fStartWeek = dt.startWeek;
    this.fEndWeek = dt.endWeek;
    this.fType = dt.type;
    this.showEdit = true;
  }

  private saveEdit(): void {
    const name = this.fName.trim();
    if (name.length === 0) {
      this.showToast('请填写课程名称');
      return;
    }
    if (this.fEndWeek < this.fStartWeek) {
      this.showToast('结束周不能早于开始周');
      return;
    }
    // 同名课程复用（同一课程多个时段共用颜色），否则新建
    let course: CourseBase | undefined = undefined;
    for (const c of this.courses) {
      if (c.courseName === name) {
        course = c;
        break;
      }
    }
    if (course === undefined) {
      const maxId = this.courses.reduce((m: number, c: CourseBase): number => Math.max(m, c.id), 0);
      course = {
        id: maxId + 1,
        courseName: name,
        color: COURSE_COLORS[this.courses.length % COURSE_COLORS.length],
        tableId: 1
      };
      this.courses = [...this.courses, course];
    }
    const detail: CourseDetail = {
      id: course.id,
      day: this.fDay,
      room: this.fRoom.trim(),
      teacher: this.fTeacher.trim(),
      startNode: this.fStartNode,
      step: Math.max(1, Math.min(this.fStep, this.table.nodes - this.fStartNode + 1)),
      startWeek: this.fStartWeek,
      endWeek: this.fEndWeek,
      type: this.fType,
      tableId: 1
    };
    if (this.editDetailId >= 0) {
      this.details = this.details.map((d: CourseDetail, i: number): CourseDetail =>
        i === this.editDetailId ? detail : d);
    } else {
      this.details = [...this.details, detail];
    }
    this.cleanOrphans();
    this.persist();
    this.showEdit = false;
  }

  private deleteEdit(): void {
    if (this.editDetailId >= 0) {
      this.details = this.details.filter((_: CourseDetail, i: number): boolean => i !== this.editDetailId);
      this.cleanOrphans();
      this.persist();
    }
    this.showEdit = false;
  }

  /** 清理无任何排课引用的课程 */
  private cleanOrphans(): void {
    this.courses = this.courses.filter((c: CourseBase): boolean => {
      for (const d of this.details) {
        if (d.id === c.id) {
          return true;
        }
      }
      return false;
    });
  }

  // ════════ WakeUp 兼容导入导出 ════════
  /** 导出为 WakeUp 5 行格式文本 → 剪贴板 */
  private exportWakeUp(): void {
    const timeTable: WakeTimeTable = { id: 1, name: '默认', sameLen: true, courseLen: 45 };
    const times: WakeTimeDetail[] = [];
    for (let i = 0; i < this.table.nodes; i++) {
      const t = i < this.times.length ? this.times[i] : DEFAULT_TIMES[i % DEFAULT_TIMES.length];
      times.push({ node: i + 1, startTime: t[0], endTime: t[1], timeTable: 1 });
    }
    const wtable: WakeTable = {
      id: 1,
      tableName: this.table.name,
      nodes: this.table.nodes,
      startDate: this.table.startDate,
      maxWeek: this.table.maxWeek,
      showSat: true,
      showSun: true,
      sundayFirst: false,
      type: 0
    };
    const text = `${JSON.stringify(timeTable)}\n${JSON.stringify(times)}\n${JSON.stringify(wtable)}\n` +
      `${JSON.stringify(this.courses)}\n${JSON.stringify(this.details)}`;
    const record = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    pasteboard.getSystemPasteboard().setData(record)
      .then((): void => this.showToast('已复制课表数据（WakeUp 兼容格式）'))
      .catch((err: Error): void => {
        console.error('copy failed:', err.message);
        this.showToast('复制失败');
      });
  }

  /** 从剪贴板导入 WakeUp 5 行格式 */
  private async importWakeUp(): Promise<void> {
    try {
      const data = await pasteboard.getSystemPasteboard().getData();
      const text = data.getPrimaryText();
      if (text === undefined || text.trim().length === 0) {
        this.showToast('剪贴板为空，请先复制 WakeUp 导出的课表文本');
        return;
      }
      const lines = text.trim().split('\n').filter((l: string): boolean => l.trim().length > 0);
      if (lines.length < 5) {
        this.showToast('格式不符：需要 WakeUp 导出的 5 行课表数据');
        return;
      }
      const wtable = JSON.parse(lines[2]) as WakeTable;
      const courses = JSON.parse(lines[3]) as CourseBase[];
      const details = JSON.parse(lines[4]) as CourseDetail[];
      if (!Array.isArray(courses) || !Array.isArray(details)) {
        this.showToast('课程数据解析失败');
        return;
      }
      this.table = {
        name: wtable.tableName ?? '导入课表',
        startDate: wtable.startDate ?? mondayStr(),
        maxWeek: wtable.maxWeek ?? 20,
        nodes: Math.max(1, Math.min(wtable.nodes ?? 12, 16))
      };
      // 第 2 行节次作息一并导入
      try {
        const wtimes = JSON.parse(lines[1]) as WakeTimeDetail[];
        if (Array.isArray(wtimes) && wtimes.length > 0) {
          const arr: string[][] = [];
          for (let i = 0; i < this.table.nodes; i++) {
            let hit: WakeTimeDetail | undefined = undefined;
            for (const wt of wtimes) {
              if (wt.node === i + 1) {
                hit = wt;
                break;
              }
            }
            if (hit !== undefined) {
              arr.push([hit.startTime, hit.endTime]);
            } else {
              const t = DEFAULT_TIMES[i % DEFAULT_TIMES.length];
              arr.push([t[0], t[1]]);
            }
          }
          this.times = arr;
        }
      } catch (err) {
        console.error('parse times failed:', JSON.stringify(err));
      }
      this.ensureTimes();
      // 补齐字段缺省 & 颜色兜底
      this.courses = courses.map((c: CourseBase, i: number): CourseBase => ({
        id: c.id,
        courseName: c.courseName ?? '未命名',
        color: c.color !== undefined && c.color.startsWith('#') ? c.color : COURSE_COLORS[i % COURSE_COLORS.length],
        tableId: 1
      } as CourseBase));
      this.details = details.map((d: CourseDetail): CourseDetail => ({
        id: d.id,
        day: d.day,
        room: d.room ?? '',
        teacher: d.teacher ?? '',
        startNode: d.startNode,
        step: d.step,
        startWeek: d.startWeek,
        endWeek: d.endWeek,
        type: d.type ?? 0,
        tableId: 1
      } as CourseDetail));
      this.persist();
      this.curWeek = this.weekOfToday();
      this.showToast(`导入成功：${this.courses.length} 门课，${this.details.length} 个时段`);
    } catch (err) {
      console.error('import failed:', JSON.stringify(err));
      this.showToast('导入失败：数据格式不符');
    }
  }

  // ════════ UI ════════
  /** 数字字段读写（@Builder 值参数不参与状态观察，须传字段名内部直读 @State） */
  private numVal(field: string): number {
    if (field === 'startNode') { return this.fStartNode; }
    if (field === 'step') { return this.fStep; }
    if (field === 'startWeek') { return this.fStartWeek; }
    if (field === 'endWeek') { return this.fEndWeek; }
    if (field === 'maxWeek') { return this.table.maxWeek; }
    if (field.startsWith('gen')) { return this.genVal(field); }
    return this.table.nodes;   // nodes
  }

  private numSet(field: string, v: number): void {
    if (field === 'startNode') { this.fStartNode = v; }
    else if (field === 'step') { this.fStep = v; }
    else if (field === 'startWeek') { this.fStartWeek = v; }
    else if (field === 'endWeek') { this.fEndWeek = v; }
    else if (field.startsWith('gen')) { this.genSet(field, v); }
    else if (field === 'maxWeek') {
      this.table = { name: this.table.name, startDate: this.table.startDate, maxWeek: v, nodes: this.table.nodes };
    } else {
      this.table = { name: this.table.name, startDate: this.table.startDate, maxWeek: this.table.maxWeek, nodes: v };
    }
  }

  /** 数字选择行支持步长（分钟类参数用 5 分钟步进） */
  private numStep(field: string): number {
    if (field === 'genLunchMin' || field === 'genDinnerMin') { return 10; }
    if (field === 'genLen' || field === 'genBreak') { return 5; }
    return 1;
  }

  /** 数字选择行：label − 值 + （gen* 分钟参数按 5/10 步进） */
  @Builder
  numRow(label: string, field: string, min: number, max: number) {
    Row({ space: 8 }) {
      Text(label)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width(80)
      Blank()
      Text('−')
        .fontSize(17).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
        .width(34).height(34)
        .borderRadius(10)
        .backgroundColor($r('app.color.bg_page'))
        .onClick(() => {
          const step = this.numStep(field);
          if (this.numVal(field) - step >= min) {
            this.numSet(field, this.numVal(field) - step);
          }
        })
      Text(this.numVal(field).toString())
        .fontSize(15).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
        .width(40)
      Text('+')
        .fontSize(17).fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .textAlign(TextAlign.Center)
        .width(34).height(34)
        .borderRadius(10)
        .backgroundColor($r('app.color.bg_page'))
        .onClick(() => {
          const step = this.numStep(field);
          if (this.numVal(field) + step <= max) {
            this.numSet(field, this.numVal(field) + step);
          }
        })
    }
    .width('100%')
  }

  build() {
    NavDestination() {
      Stack() {
        Column({ space: 8 }) {
          // ── 周次切换 + 工具行 ──
          Row({ space: 8 }) {
            Text('◀')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .padding(8)
              .onClick(() => {
                if (this.curWeek > 1) {
                  this.curWeek -= 1;
                }
              })
            Column({ space: 1 }) {
              Text(`第 ${this.curWeek} 周`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              Text(`${this.curWeek % 2 === 1 ? '单周' : '双周'}${this.curWeek === this.weekOfToday() ? ' · 本周' : ''}`)
                .fontSize(10)
                .fontColor(this.curWeek % 2 === 1 ? '#FF9F43' : '#4FACFE')
            }
            .onClick(() => {
              this.curWeek = this.weekOfToday();
            })
            Text('▶')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .padding(8)
              .onClick(() => {
                if (this.curWeek < this.table.maxWeek) {
                  this.curWeek += 1;
                }
              })
            Blank()
            Text('导入')
              .fontSize(12)
              .fontColor($r('app.color.text_primary'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(12)
              .backgroundColor($r('app.color.bg_card'))
              .onClick(() => this.importWakeUp())
            Text('导出')
              .fontSize(12)
              .fontColor($r('app.color.text_primary'))
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(12)
              .backgroundColor($r('app.color.bg_card'))
              .onClick(() => this.exportWakeUp())
            Text('⚙')
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .padding({ left: 8, right: 8, top: 6, bottom: 6 })
              .borderRadius(12)
              .backgroundColor($r('app.color.bg_card'))
              .onClick(() => {
                this.showSettings = true;
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          // ── 表头：周一~周日 ──
          Row({ space: 2 }) {
            Text('')
              .width(30)
            ForEach(DAY_NAMES, (d: string, i: number) => {
              Text(d)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_secondary'))
                .textAlign(TextAlign.Center)
                .layoutWeight(1)
            }, (d: string) => d)
          }
          .width('100%')

          // ── 课程网格 ──
          Scroll() {
            Row({ space: 2 }) {
              // 节次栏（节号 + 起止时间）
              Column({ space: 2 }) {
                ForEach(this.nodeList(), (n: number) => {
                  Column({ space: 1 }) {
                    Text(n.toString())
                      .fontSize(10)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_secondary'))
                    Text(this.timeOf(n, 0))
                      .fontSize(7)
                      .fontColor($r('app.color.text_secondary'))
                      .opacity(0.8)
                    Text(this.timeOf(n, 1))
                      .fontSize(7)
                      .fontColor($r('app.color.text_secondary'))
                      .opacity(0.8)
                  }
                  .justifyContent(FlexAlign.Center)
                  .width(30)
                  .height(52)
                }, (n: number) => `n${n}-${this.rev}`)
              }
              // 七天列
              ForEach([1, 2, 3, 4, 5, 6, 7], (day: number) => {
                Column({ space: 2 }) {
                  ForEach(this.nodeList(), (node: number) => {
                    if (this.detailAt(day, node) !== undefined) {
                      this.courseBlock(day, node)
                    } else if (!this.coveredAt(day, node)) {
                      // 空格：点击快捷添加
                      Text('')
                        .width('100%')
                        .height(52)
                        .borderRadius(8)
                        .backgroundColor($r('app.color.bg_card'))
                        .opacity(0.45)
                        .onClick(() => this.openAdd(day, node))
                    }
                  }, (node: number) => `d${day}n${node}-${this.curWeek}-${this.rev}`)
                }
                .layoutWeight(1)
              }, (day: number) => `day${day}`)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
        .padding({ left: 10, right: 10, top: 4, bottom: 10 })
        .width('100%')
        .height('100%')

        // ── 编辑弹层 ──
        if (this.showEdit) {
          this.editSheet()
        }
        // ── 设置弹层 ──
        if (this.showSettings) {
          this.settingsSheet()
        }
      }
      .width('100%')
      .height('100%')
    }
    .title('课程表')
    .backgroundColor($r('app.color.bg_page'))
  }

  private nodeList(): number[] {
    const arr: number[] = [];
    for (let i = 1; i <= this.table.nodes; i++) {
      arr.push(i);
    }
    return arr;
  }

  /** 第 n 节的开始(idx 0)/结束(idx 1)时间 */
  private timeOf(n: number, idx: number): string {
    if (n - 1 < this.times.length && this.times[n - 1].length === 2) {
      return this.times[n - 1][idx];
    }
    return DEFAULT_TIMES[(n - 1) % DEFAULT_TIMES.length][idx];
  }

  /** 'HH:mm' → Date（TimePicker 用） */
  private timeAsDate(n: number, idx: number): Date {
    const parts = this.timeOf(n, idx).split(':');
    const d = new Date();
    d.setHours(parseInt(parts[0]) || 8, parseInt(parts[1]) || 0, 0, 0);
    return d;
  }

  private genStartDate(): Date {
    const parts = this.genStart.split(':');
    const d = new Date();
    d.setHours(parseInt(parts[0]) || 8, parseInt(parts[1]) || 0, 0, 0);
    return d;
  }

  private setTime(n: number, idx: number, v: Date): void {
    this.ensureTimes();
    const arr = this.times.map((t: string[]): string[] => [t[0], t[1]]);
    arr[n - 1][idx] = `${v.getHours().toString().padStart(2, '0')}:${v.getMinutes().toString().padStart(2, '0')}`;
    this.times = arr;
  }

  /**
   * 一键生成全学期作息：首节开始 + 每节时长 + 课间 + 午/晚休，
   * 生成一次全学期（所有周、每天）通用
   */
  private generateTimes(): void {
    const parts = this.genStart.split(':');
    let cur = (parseInt(parts[0]) || 8) * 60 + (parseInt(parts[1]) || 0);
    const fmt = (m: number): string =>
      `${Math.floor(m / 60) % 24}`.padStart(2, '0') + ':' + `${m % 60}`.padStart(2, '0');
    const arr: string[][] = [];
    for (let n = 1; n <= this.table.nodes; n++) {
      const s = cur;
      const e = cur + this.genLen;
      arr.push([fmt(s), fmt(e)]);
      cur = e + this.genBreak;
      if (this.genLunchAfter > 0 && n === this.genLunchAfter) {
        cur = e + this.genLunchMin;
      } else if (this.genDinnerAfter > 0 && n === this.genDinnerAfter) {
        cur = e + this.genDinnerMin;
      }
    }
    this.times = arr;
    this.persist();
    this.showToast('已生成全学期作息，可再逐节微调');
  }

  /** 作息生成参数读写（numRow 复用） */
  private genVal(field: string): number {
    if (field === 'genLen') { return this.genLen; }
    if (field === 'genBreak') { return this.genBreak; }
    if (field === 'genLunchAfter') { return this.genLunchAfter; }
    if (field === 'genLunchMin') { return this.genLunchMin; }
    if (field === 'genDinnerAfter') { return this.genDinnerAfter; }
    return this.genDinnerMin;
  }

  private genSet(field: string, v: number): void {
    if (field === 'genLen') { this.genLen = v; }
    else if (field === 'genBreak') { this.genBreak = v; }
    else if (field === 'genLunchAfter') { this.genLunchAfter = v; }
    else if (field === 'genLunchMin') { this.genLunchMin = v; }
    else if (field === 'genDinnerAfter') { this.genDinnerAfter = v; }
    else { this.genDinnerMin = v; }
  }

  /** 课程块（跨 step 节整块渲染） */
  @Builder
  courseBlock(day: number, node: number) {
    Column({ space: 1 }) {
      Text(this.blockName(day, node))
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
      if (this.blockRoom(day, node).length > 0) {
        Text(`@${this.blockRoom(day, node)}`)
          .fontSize(8)
          .fontColor('#E6FFFFFF')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
      }
      if (this.blockType(day, node) > 0) {
        Text(TYPE_NAMES[this.blockType(day, node)])
          .fontSize(7)
          .fontColor(Color.White)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .borderRadius(5)
          .backgroundColor('#33000000')
      }
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(this.blockHeight(day, node))
    .padding(3)
    .borderRadius(8)
    .backgroundColor(this.blockColor(day, node))
    .onClick(() => {
      const dt = this.detailAt(day, node);
      if (dt !== undefined) {
        this.openEdit(dt);
      }
    })
  }

  private blockName(day: number, node: number): string {
    const dt = this.detailAt(day, node);
    if (dt === undefined) {
      return '';
    }
    const c = this.courseOf(dt.id);
    return c !== undefined ? c.courseName : '';
  }

  private blockRoom(day: number, node: number): string {
    const dt = this.detailAt(day, node);
    return dt !== undefined ? dt.room : '';
  }

  private blockType(day: number, node: number): number {
    const dt = this.detailAt(day, node);
    return dt !== undefined ? dt.type : 0;
  }

  private blockHeight(day: number, node: number): number {
    const dt = this.detailAt(day, node);
    const step = dt !== undefined ? dt.step : 1;
    return step * 52 + (step - 1) * 2;
  }

  private blockColor(day: number, node: number): string {
    const dt = this.detailAt(day, node);
    if (dt === undefined) {
      return '#4FACFE';
    }
    const c = this.courseOf(dt.id);
    return c !== undefined ? c.color : '#4FACFE';
  }

  /** 课程编辑弹层 */
  @Builder
  editSheet() {
    Column() {
      Column({ space: 10 }) {
        Row() {
          Text(this.editDetailId >= 0 ? '编辑课程' : '添加课程')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Blank()
          Text('✕')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .padding(6)
            .onClick(() => {
              this.showEdit = false;
            })
        }
        .width('100%')

        TextInput({ placeholder: '课程名称 *', text: this.fName })
          .height(42)
          .borderRadius(12)
          .backgroundColor($r('app.color.bg_page'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.fName = v; })
        TextInput({ placeholder: '教师（可选）', text: this.fTeacher })
          .height(42)
          .borderRadius(12)
          .backgroundColor($r('app.color.bg_page'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.fTeacher = v; })
        TextInput({ placeholder: '地点（如 教三-201）', text: this.fRoom })
          .height(42)
          .borderRadius(12)
          .backgroundColor($r('app.color.bg_page'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.fRoom = v; })

        // 周几
        Row({ space: 5 }) {
          ForEach(DAY_NAMES, (d: string, i: number) => {
            Text(d)
              .fontSize(13)
              .fontWeight(this.fDay === i + 1 ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.fDay === i + 1 ? Color.White : $r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(34)
              .borderRadius(10)
              .backgroundColor(this.fDay === i + 1 ? $r('app.color.accent') : $r('app.color.bg_page'))
              .onClick(() => {
                this.fDay = i + 1;
              })
          }, (d: string) => `fd${d}`)
        }
        .width('100%')

        this.numRow('开始节', 'startNode', 1, this.table.nodes)
        this.numRow('连续节数', 'step', 1, 6)
        this.numRow('开始周', 'startWeek', 1, this.table.maxWeek)
        this.numRow('结束周', 'endWeek', 1, this.table.maxWeek)

        // 单双周
        Row({ space: 6 }) {
          Text('周期')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .width(64)
          ForEach(TYPE_NAMES, (t: string, i: number) => {
            Text(t)
              .fontSize(13)
              .fontWeight(this.fType === i ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.fType === i ? Color.White : $r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .height(34)
              .borderRadius(10)
              .backgroundColor(this.fType === i ? (i === 1 ? '#FF9F43' : (i === 2 ? '#4FACFE' : $r('app.color.accent'))) : $r('app.color.bg_page'))
              .onClick(() => {
                this.fType = i;
              })
          }, (t: string) => `ft${t}`)
        }
        .width('100%')

        Row({ space: 10 }) {
          if (this.editDetailId >= 0) {
            Button('删除')
              .layoutWeight(1)
              .height(44)
              .fontColor('#F5576C')
              .backgroundColor('#1AF5576C')
              .onClick(() => this.deleteEdit())
          }
          Button('保存')
            .layoutWeight(2)
            .height(44)
            .fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => this.saveEdit())
        }
        .width('100%')
      }
      .padding(18)
      .borderRadius({ topLeft: 20, topRight: 20 })
      .backgroundColor($r('app.color.bg_card'))
      .width('100%')
      .onClick(() => {
        // 抽屉面板内点击（非输入区）不关闭：拦截，防止落到遮罩的关闭 onClick
      })
    }
    .justifyContent(FlexAlign.End)
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .onClick(() => {
      this.showEdit = false;
    })
  }

  /** 课表设置弹层 */
  @Builder
  settingsSheet() {
    Column() {
      Column({ space: 0 }) {
        Row() {
          Text('课表设置')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Blank()
          Text('✕')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .padding(6)
            .onClick(() => {
              this.showSettings = false;
              this.editTimeNode = -1;
              this.persist();
            })
        }
        .width('100%')
        .padding({ bottom: 8 })

        Scroll() {
          Column({ space: 12 }) {

        Row({ space: 8 }) {
          Text('开学日期')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .width(64)
          Text(this.table.startDate)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        DatePicker({
          start: new Date('2020-01-01'),
          end: new Date('2035-12-31'),
          selected: new Date(this.table.startDate)
        })
          .height(110)
          .onDateChange((v: Date) => {
            this.table = {
              name: this.table.name,
              startDate: `${v.getFullYear()}-${(v.getMonth() + 1).toString().padStart(2, '0')}-${v.getDate().toString().padStart(2, '0')}`,
              maxWeek: this.table.maxWeek,
              nodes: this.table.nodes
            };
          })
        Text('提示：选学期第一周的周一，用于计算当前周')
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))

        this.numRow('学期周数', 'maxWeek', 4, 30)
        this.numRow('每天节数', 'nodes', 4, 16)

        Divider().strokeWidth(0.5).color('#33888888')

        // ── 作息一键生成：编辑一次全学期通用 ──
        Text('作息生成（编辑一次，全学期每天通用）')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .alignSelf(ItemAlign.Start)
        Row({ space: 8 }) {
          Text('首节开始')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .width(80)
          Blank()
          TimePicker({ selected: this.genStartDate() })
            .useMilitaryTime(true)
            .height(60)
            .width(150)
            .onChange((v: TimePickerResult) => {
              this.genStart = `${(v.hour ?? 8).toString().padStart(2, '0')}:${(v.minute ?? 0).toString().padStart(2, '0')}`;
            })
        }
        .width('100%')
        this.numRow('每节时长(分)', 'genLen', 30, 120)
        this.numRow('课间休息(分)', 'genBreak', 0, 30)
        this.numRow('午休在第N节后', 'genLunchAfter', 0, 8)
        this.numRow('午休时长(分)', 'genLunchMin', 30, 240)
        this.numRow('晚休在第N节后', 'genDinnerAfter', 0, 12)
        this.numRow('晚休时长(分)', 'genDinnerMin', 30, 240)
        Button('按以上参数生成全学期作息')
          .width('100%')
          .height(40)
          .fontSize(14)
          .fontColor($r('app.color.accent'))
          .backgroundColor('#1A5B6BF5')
          .onClick(() => this.generateTimes())

        Divider().strokeWidth(0.5).color('#33888888')

        // ── 节次作息微调：横向滑动，点某节展开 TimePicker 改起止 ──
        Text('逐节微调（点击某节修改起止时间）')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .alignSelf(ItemAlign.Start)
        Scroll() {
          Row({ space: 6 }) {
            ForEach(this.nodeList(), (n: number) => {
              Column({ space: 1 }) {
                Text(`第${n}节`)
                  .fontSize(10)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.editTimeNode === n ? Color.White : $r('app.color.text_primary'))
                Text(this.timeOf(n, 0))
                  .fontSize(9)
                  .fontColor(this.editTimeNode === n ? '#E6FFFFFF' : $r('app.color.text_secondary'))
                Text(this.timeOf(n, 1))
                  .fontSize(9)
                  .fontColor(this.editTimeNode === n ? '#E6FFFFFF' : $r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Center)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .borderRadius(10)
              .backgroundColor(this.editTimeNode === n ? $r('app.color.accent') : $r('app.color.bg_page'))
              .onClick(() => {
                this.editTimeNode = this.editTimeNode === n ? -1 : n;
              })
            }, (n: number) => `tn${n}-${this.rev}-${this.editTimeNode === n ? '1' : '0'}`)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        if (this.editTimeNode > 0) {
          Row({ space: 8 }) {
            Column({ space: 2 }) {
              Text('开始')
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
              TimePicker({ selected: this.timeAsDate(this.editTimeNode, 0) })
                .useMilitaryTime(true)
                .height(90)
                .onChange((v: TimePickerResult) => {
                  const d = new Date();
                  d.setHours(v.hour ?? 8, v.minute ?? 0, 0, 0);
                  this.setTime(this.editTimeNode, 0, d);
                })
            }
            .layoutWeight(1)
            Column({ space: 2 }) {
              Text('结束')
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
              TimePicker({ selected: this.timeAsDate(this.editTimeNode, 1) })
                .useMilitaryTime(true)
                .height(90)
                .onChange((v: TimePickerResult) => {
                  const d = new Date();
                  d.setHours(v.hour ?? 8, v.minute ?? 45, 0, 0);
                  this.setTime(this.editTimeNode, 1, d);
                })
            }
            .layoutWeight(1)
          }
          .width('100%')
        }

        Button('完成')
          .width('100%')
          .height(44)
          .fontWeight(FontWeight.Bold)
          .backgroundColor($r('app.color.accent'))
          .onClick(() => {
            this.showSettings = false;
            this.editTimeNode = -1;
            this.curWeek = this.weekOfToday();
            this.ensureTimes();
            this.persist();
          })
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: '72%' })
      }
      .padding(18)
      .borderRadius({ topLeft: 20, topRight: 20 })
      .backgroundColor($r('app.color.bg_card'))
      .width('100%')
      .onClick(() => {
        // 面板内点击不关闭（拦截遮罩 onClick）
      })
    }
    .justifyContent(FlexAlign.End)
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
    .onClick(() => {
      this.showSettings = false;
      this.editTimeNode = -1;
      this.persist();
    })
  }
}
