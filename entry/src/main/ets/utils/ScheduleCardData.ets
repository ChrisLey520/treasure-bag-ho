import { preferences } from '@kit.ArkData';

/**
 * 今日课程卡片共享数据构建：解析 preferences 里的 schedule JSON，
 * 按 今天星期几 + 当前周 + 单双周 过滤并按节次排序。
 * EntryFormAbility（2×4 卡）与 ExtraFormAbility（4×4 大卡）共用。
 */

interface SchedCourseBase {
  id: number;
  courseName: string;
  color: string;
}

interface SchedCourseDetail {
  id: number;
  day: number;
  room: string;
  teacher: string;
  startNode: number;
  step: number;
  startWeek: number;
  endWeek: number;
  type: number;
}

interface SchedTable {
  startDate: string;
  maxWeek: number;
}

interface SchedData {
  table: SchedTable;
  courses: SchedCourseBase[];
  details: SchedCourseDetail[];
  times?: string[][];
}

export interface TodayCourse {
  start: string;    // 开始时刻（无作息则 "N节" 形式）
  end: string;      // 结束时刻（无作息则空）
  name: string;
  room: string;
  teacher: string;
  color: string;
}

export interface TodayInfo {
  weekText: string;
  courses: TodayCourse[];
}

export function buildTodayCourses(pref: preferences.Preferences): TodayInfo {
  const empty: TodayInfo = { weekText: '', courses: [] };
  const saved = pref.getSync('schedule', '') as string;
  if (saved.length === 0) {
    return empty;
  }
  let data: SchedData | undefined = undefined;
  try {
    data = JSON.parse(saved) as SchedData;
  } catch (err) {
    return empty;
  }
  const parts = data.table.startDate.split('-');
  const start = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const week = Math.max(1, Math.min(data.table.maxWeek,
    Math.floor(Math.floor((today.getTime() - start.getTime()) / 86400000) / 7) + 1));
  const weekday = now.getDay() === 0 ? 7 : now.getDay();

  const nameOf = (id: number): string => {
    for (const c of data!.courses) {
      if (c.id === id) {
        return c.courseName;
      }
    }
    return '';
  };
  const colorOf = (id: number): string => {
    for (const c of data!.courses) {
      if (c.id === id && c.color !== undefined && c.color.startsWith('#')) {
        return c.color;
      }
    }
    return '#4FACFE';
  };

  const todays: SchedCourseDetail[] = [];
  for (const dt of data.details) {
    if (dt.day !== weekday || week < dt.startWeek || week > dt.endWeek) {
      continue;
    }
    if (dt.type === 1 && week % 2 === 0) {
      continue;
    }
    if (dt.type === 2 && week % 2 === 1) {
      continue;
    }
    todays.push(dt);
  }
  todays.sort((a: SchedCourseDetail, b: SchedCourseDetail): number => a.startNode - b.startNode);

  const times = data.times ?? [];
  const courses: TodayCourse[] = [];
  for (const dt of todays) {
    let startText = dt.step > 1 ? `${dt.startNode}-${dt.startNode + dt.step - 1}节` : `${dt.startNode}节`;
    let endText = '';
    if (dt.startNode - 1 < times.length && times[dt.startNode - 1].length === 2) {
      startText = times[dt.startNode - 1][0];
      const endIdx = dt.startNode + dt.step - 2;
      if (endIdx < times.length && times[endIdx].length === 2) {
        endText = times[endIdx][1];
      }
    }
    courses.push({
      start: startText,
      end: endText,
      name: nameOf(dt.id),
      room: dt.room,
      teacher: dt.teacher,
      color: colorOf(dt.id)
    });
  }
  return {
    weekText: `第${week}周 ${week % 2 === 1 ? '单' : '双'}`,
    courses: courses
  };
}
