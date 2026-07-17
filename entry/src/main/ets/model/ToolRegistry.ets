/**
 * 工具注册表：新增工具只需在 TOOLS 中登记一条记录，并在 Index.ets 的路由表中挂载页面。
 */

export enum ToolCategory {
  RECOMMEND = '推荐',
  IMAGE = '图片',
  TEXT = '文字',
  LIFE = '生活',
  QUERY = '查询',
  DEV = '开发者'
}

export interface ToolInfo {
  id: string;          // 路由名，唯一
  name: string;
  desc: string;
  emoji: string;       // 先用 emoji 做图标，后续换 symbol 资源
  category: ToolCategory;
  gradient: [string, string]; // 卡片渐变色（起、止）
  glyph?: string;               // 自绘徽标字符（替代 emoji，与服务卡片徽标一致）
  glyphGradient?: [string, string]; // 徽标渐变（缺省用卡片渐变）
}

export const TOOLS: ToolInfo[] = [
  // ── 图片/媒体 ──
  { id: 'colorpicker', name: '图片取色器', desc: '点击图片提取颜色', emoji: '🎨', category: ToolCategory.IMAGE, gradient: ['#F093FB', '#F5576C'] },
  { id: 'mirror', name: '图片镜像', desc: '翻转 · 旋转', emoji: '🪞', category: ToolCategory.IMAGE, gradient: ['#4FACFE', '#00F2FE'] },
  { id: 'compress', name: '图片压缩', desc: '质量 · 分辨率双控', emoji: '🗜️', category: ToolCategory.IMAGE, gradient: ['#667EEA', '#764BA2'] },
  { id: 'qrgen', name: '二维码生成', desc: '文本 · 网址转码', emoji: '▦', category: ToolCategory.IMAGE, gradient: ['#141E30', '#243B55'] },
  { id: 'qrscan', name: '扫码识别', desc: '二维码 · 条形码', emoji: '📷', category: ToolCategory.IMAGE, gradient: ['#0F2027', '#2C5364'] },
  { id: 'ocr', name: 'OCR 识字', desc: '本地 AI 提取文字', emoji: '🔤', category: ToolCategory.IMAGE, gradient: ['#8E2DE2', '#4A00E0'] },
  { id: 'ninegrid', name: '九宫格切图', desc: '朋友圈 3×3 切图', emoji: '🖼️', category: ToolCategory.IMAGE, gradient: ['#FC5C7D', '#6A82FB'] },
  // ── 查询/计算 ──
  { id: 'radix', name: '进制转换', desc: '2/8/10/16 进制互转', emoji: '🔢', category: ToolCategory.DEV, gradient: ['#667EEA', '#764BA2'] },
  { id: 'color', name: '颜色转换', desc: 'HEX / RGB / HSB', emoji: '🎨', category: ToolCategory.DEV, gradient: ['#F093FB', '#F5576C'] },
  { id: 'unit', name: '单位换算', desc: '长度·重量·面积·温度', emoji: '📐', category: ToolCategory.QUERY, gradient: ['#4FACFE', '#00F2FE'] },
  { id: 'date', name: '日期计算', desc: '日期差 · 日期推算', emoji: '📅', category: ToolCategory.QUERY, gradient: ['#43E97B', '#38F9D7'] },
  { id: 'relative', name: '亲戚称呼', desc: '过年不再叫错人', emoji: '👨‍👩‍👧', category: ToolCategory.QUERY, gradient: ['#FA709A', '#FEE140'] },
  { id: 'bmi', name: 'BMI 计算', desc: '身体质量指数', emoji: '⚖️', category: ToolCategory.QUERY, gradient: ['#30CFD0', '#330867'] },
  { id: 'timestamp', name: '时间戳转换', desc: 'Unix 时间戳互转', emoji: '⏱️', category: ToolCategory.DEV, gradient: ['#A8EDEA', '#5B6BF5'] },
  { id: 'calculator', name: '计算器', desc: '日常四则运算', emoji: '🧮', category: ToolCategory.QUERY, gradient: ['#232526', '#414345'],
    glyph: '＝', glyphGradient: ['#5B6BF5', '#8B5CF6'] },
  { id: 'supercalc', name: '超级计算器', desc: '科学计算 · 函数绘图', emoji: '🧪', category: ToolCategory.QUERY, gradient: ['#42275A', '#734B6D'],
    glyph: '√', glyphGradient: ['#42275A', '#734B6D'] },
  { id: 'calendar', name: '万年历', desc: '公历农历 · 干支生肖', emoji: '🗓️', category: ToolCategory.QUERY, gradient: ['#C33764', '#1D2671'] },
  // ── 文字/文案 ──
  { id: 'answer', name: '答案之书', desc: '让命运替你决定', emoji: '📖', category: ToolCategory.TEXT, gradient: ['#5B247A', '#1BCEDF'] },
  { id: 'banner', name: '手持弹幕', desc: '全屏滚动大字', emoji: '💬', category: ToolCategory.TEXT, gradient: ['#1A1D26', '#5B6BF5'] },
  { id: 'rainbow', name: '彩虹屁', desc: '一键生成夸人金句', emoji: '🌈', category: ToolCategory.TEXT, gradient: ['#FF9A9E', '#FAD0C4'] },
  { id: 'kfc', name: '疯狂星期四', desc: 'V 我 50 文学', emoji: '🍗', category: ToolCategory.TEXT, gradient: ['#F83600', '#F9D423'] },
  { id: 'dogdiary', name: '舔狗日记', desc: '卑微文学鉴赏', emoji: '🐕', category: ToolCategory.TEXT, gradient: ['#606C88', '#3F4C6B'] },
  { id: 'magictext', name: '魔法文案', desc: '隐形字符防和谐', emoji: '🪄', category: ToolCategory.TEXT, gradient: ['#8E2DE2', '#4A00E0'] },
  // ── 生活 ──
  { id: 'focus', name: '专注时钟', desc: '沉浸计时 · 服务卡片', emoji: '⏳', category: ToolCategory.LIFE, gradient: ['#1A2980', '#26D0CE'] },
  { id: 'scoreboard', name: '记分牌', desc: '比赛计分器', emoji: '🏆', category: ToolCategory.LIFE, gradient: ['#11998E', '#38EF7D'] },
  { id: 'decision', name: '随机决定', desc: '转盘帮你选', emoji: '🎯', category: ToolCategory.LIFE, gradient: ['#FC466B', '#3F5EFB'] },
  { id: 'fakecall', name: '来电模拟', desc: '饭局解围神器', emoji: '📞', category: ToolCategory.LIFE, gradient: ['#134E5E', '#71B280'] },
  { id: 'deadpixel', name: '坏点检测', desc: '屏幕纯色检测', emoji: '🖥️', category: ToolCategory.LIFE, gradient: ['#3A1C71', '#D76D77'] },
  { id: 'deviceinfo', name: '设备信息', desc: '型号 · 系统 · 屏幕', emoji: '📱', category: ToolCategory.LIFE, gradient: ['#0F0C29', '#302B63'] },
  { id: 'compass', name: '指南针', desc: '方向传感器', emoji: '🧭', category: ToolCategory.LIFE, gradient: ['#870000', '#190A05'] },
  { id: 'level', name: '水平仪', desc: '气泡找平', emoji: '📏', category: ToolCategory.LIFE, gradient: ['#136A8A', '#267871'] },
  { id: 'ruler', name: '屏幕直尺', desc: '实物测量 0-15cm', emoji: '📐', category: ToolCategory.LIFE, gradient: ['#B79891', '#94716B'] },
  { id: 'todo', name: '待办事项', desc: '轻量任务清单', emoji: '📝', category: ToolCategory.LIFE, gradient: ['#3494E6', '#EC6EAD'] },
  { id: 'habit', name: '习惯打卡', desc: '连续天数统计', emoji: '🌱', category: ToolCategory.LIFE, gradient: ['#56AB2F', '#A8E063'] },
  { id: 'anniversary', name: '纪念日', desc: '倒数日 · 正数日', emoji: '💝', category: ToolCategory.LIFE, gradient: ['#EC008C', '#FC6767'] },
  { id: 'weather', name: '天气查询', desc: '全球城市 7 日预报', emoji: '🌤️', category: ToolCategory.LIFE, gradient: ['#2980B9', '#6DD5FA'] },
  { id: 'protractor', name: '角度尺', desc: '侧靠测角度', emoji: '📐', category: ToolCategory.LIFE, gradient: ['#603813', '#B29F94'] },
  { id: 'whitenoise', name: '白噪音', desc: '助眠 · 专注', emoji: '📻', category: ToolCategory.LIFE, gradient: ['#5C258D', '#4389A2'] },
  { id: 'water', name: '喝水提醒', desc: '打卡 + 定时提醒', emoji: '💧', category: ToolCategory.LIFE, gradient: ['#4FACFE', '#00F2FE'] },
  { id: 'woodfish', name: '电子木鱼', desc: '功德 +1 烦恼 -1', emoji: '🪵', category: ToolCategory.LIFE, gradient: ['#B79891', '#94716B'] },
  { id: 'coindice', name: '硬币 · 骰子', desc: '抛硬币 · 摇骰子', emoji: '🪙', category: ToolCategory.LIFE, gradient: ['#F7971E', '#FFD200'] },
  { id: 'stopwatch', name: '秒表', desc: '计时 · 计次', emoji: '⏱️', category: ToolCategory.LIFE, gradient: ['#348F50', '#56B4D3'] },
  { id: 'ledger', name: '极简记账', desc: '本月收支一目了然', emoji: '📒', category: ToolCategory.LIFE, gradient: ['#373B44', '#4286F4'] },
  { id: 'dailynews', name: '60 秒早报', desc: '每天读懂世界', emoji: '📰', category: ToolCategory.QUERY, gradient: ['#FF512F', '#F09819'] },
  { id: 'iplookup', name: 'IP 定位', desc: '归属地 · 运营商', emoji: '🌐', category: ToolCategory.QUERY, gradient: ['#1A2980', '#26D0CE'] },
  { id: 'websource', name: '网页源码', desc: '查看网页 HTML', emoji: '🌍', category: ToolCategory.DEV, gradient: ['#485563', '#29323C'] },
  // ── 开发者 ──
  { id: 'json', name: 'JSON 格式化', desc: '格式化 · 压缩 · 校验', emoji: '🧩', category: ToolCategory.DEV, gradient: ['#0F2027', '#2C5364'] },
  { id: 'regex', name: '正则测试', desc: '实时匹配验证', emoji: '🎯', category: ToolCategory.DEV, gradient: ['#1F4037', '#99F2C8'] },
  { id: 'encode', name: '编码转换', desc: 'Base64 · URL', emoji: '🔀', category: ToolCategory.DEV, gradient: ['#41295A', '#2F0743'] },
  { id: 'hash', name: '哈希计算', desc: 'MD5 · SHA 摘要', emoji: '🔐', category: ToolCategory.DEV, gradient: ['#000428', '#004E92'] },
  { id: 'uuid', name: 'UUID 生成', desc: '批量随机 UUID', emoji: '🎲', category: ToolCategory.DEV, gradient: ['#360033', '#0B8793'] },
  { id: 'password', name: '密码生成', desc: '强随机 · 防混淆', emoji: '🔑', category: ToolCategory.DEV, gradient: ['#0F3443', '#34E89E'] },
  { id: 'linuxcmd', name: 'Linux 速查', desc: '常用命令手册', emoji: '🐧', category: ToolCategory.DEV, gradient: ['#283C86', '#45A247'] },
];

const RECOMMEND_IDS: string[] = ['answer', 'focus', 'banner', 'color', 'relative', 'decision'];

export function toolsOf(category: ToolCategory, favorites: string[]): ToolInfo[] {
  if (category === ToolCategory.RECOMMEND) {
    const result: ToolInfo[] = [];
    for (const id of favorites) {
      const t = TOOLS.find(t => t.id === id);
      if (t !== undefined) {
        result.push(t);
      }
    }
    for (const id of RECOMMEND_IDS) {
      if (favorites.includes(id)) {
        continue;
      }
      const t = TOOLS.find(t => t.id === id);
      if (t !== undefined) {
        result.push(t);
      }
    }
    return result;
  }
  return TOOLS.filter(t => t.category === category);
}

export function searchTools(keyword: string): ToolInfo[] {
  const kw = keyword.trim().toLowerCase();
  if (kw.length === 0) {
    return [];
  }
  return TOOLS.filter(t =>
    t.name.toLowerCase().includes(kw) ||
    t.desc.toLowerCase().includes(kw) ||
    t.id.includes(kw)
  );
}
