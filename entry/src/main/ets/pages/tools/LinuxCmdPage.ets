interface LinuxCmd {
  cmd: string;
  desc: string;
  example: string;
  category: string;
}

const COMMANDS: LinuxCmd[] = [
  { cmd: 'ls', desc: '列出目录内容', example: 'ls -la  # 显示全部文件含隐藏，详细模式', category: '文件' },
  { cmd: 'cd', desc: '切换目录', example: 'cd /var/log  |  cd ~  |  cd -', category: '文件' },
  { cmd: 'cp', desc: '复制文件/目录', example: 'cp -r src/ dest/', category: '文件' },
  { cmd: 'mv', desc: '移动/重命名', example: 'mv old.txt new.txt', category: '文件' },
  { cmd: 'rm', desc: '删除文件/目录', example: 'rm -rf dir/  # 递归强制删除，慎用', category: '文件' },
  { cmd: 'mkdir', desc: '创建目录', example: 'mkdir -p a/b/c  # 递归创建', category: '文件' },
  { cmd: 'touch', desc: '创建空文件/更新时间戳', example: 'touch file.txt', category: '文件' },
  { cmd: 'ln', desc: '创建链接', example: 'ln -s target linkname  # 软链接', category: '文件' },
  { cmd: 'find', desc: '查找文件', example: 'find . -name "*.log" -mtime -7', category: '搜索' },
  { cmd: 'grep', desc: '文本搜索', example: 'grep -rn "error" logs/', category: '搜索' },
  { cmd: 'which', desc: '查找命令路径', example: 'which python3', category: '搜索' },
  { cmd: 'cat', desc: '查看文件内容', example: 'cat file.txt', category: '文本' },
  { cmd: 'less', desc: '分页查看', example: 'less big.log  # q 退出 / 搜索', category: '文本' },
  { cmd: 'head/tail', desc: '查看开头/结尾', example: 'tail -f app.log  # 实时跟踪', category: '文本' },
  { cmd: 'wc', desc: '统计行数/字数', example: 'wc -l file.txt', category: '文本' },
  { cmd: 'sed', desc: '流编辑器', example: "sed -i 's/old/new/g' file.txt", category: '文本' },
  { cmd: 'awk', desc: '文本分析', example: "awk '{print $1}' access.log", category: '文本' },
  { cmd: 'sort/uniq', desc: '排序/去重', example: 'sort file | uniq -c | sort -rn', category: '文本' },
  { cmd: 'ps', desc: '查看进程', example: 'ps aux | grep nginx', category: '进程' },
  { cmd: 'top/htop', desc: '实时进程监控', example: 'top  # P 按CPU排序 M 按内存', category: '进程' },
  { cmd: 'kill', desc: '结束进程', example: 'kill -9 <pid>  # 强制结束', category: '进程' },
  { cmd: 'nohup', desc: '后台运行', example: 'nohup ./run.sh > out.log 2>&1 &', category: '进程' },
  { cmd: 'df', desc: '磁盘空间', example: 'df -h', category: '系统' },
  { cmd: 'du', desc: '目录大小', example: 'du -sh */ | sort -rh', category: '系统' },
  { cmd: 'free', desc: '内存使用', example: 'free -h', category: '系统' },
  { cmd: 'uname', desc: '系统信息', example: 'uname -a', category: '系统' },
  { cmd: 'chmod', desc: '修改权限', example: 'chmod +x run.sh  |  chmod 644 f', category: '权限' },
  { cmd: 'chown', desc: '修改所有者', example: 'chown -R user:group dir/', category: '权限' },
  { cmd: 'sudo', desc: '管理员执行', example: 'sudo systemctl restart nginx', category: '权限' },
  { cmd: 'ssh', desc: '远程登录', example: 'ssh -p 22 user@host', category: '网络' },
  { cmd: 'scp', desc: '远程复制', example: 'scp file user@host:/path/', category: '网络' },
  { cmd: 'curl', desc: 'HTTP 请求', example: 'curl -X POST -d "a=1" http://api', category: '网络' },
  { cmd: 'wget', desc: '下载文件', example: 'wget -c http://url/file.tar.gz', category: '网络' },
  { cmd: 'ping', desc: '连通测试', example: 'ping -c 4 example.com', category: '网络' },
  { cmd: 'netstat/ss', desc: '端口监听', example: 'ss -tlnp | grep 8080', category: '网络' },
  { cmd: 'tar', desc: '打包压缩', example: 'tar -czvf a.tar.gz dir/  |  -xzvf 解压', category: '压缩' },
  { cmd: 'zip/unzip', desc: 'zip 压缩', example: 'zip -r a.zip dir/  |  unzip a.zip', category: '压缩' },
  { cmd: 'history', desc: '命令历史', example: 'history | grep ssh  # !123 重放', category: '其他' },
  { cmd: 'alias', desc: '命令别名', example: "alias ll='ls -la'", category: '其他' },
  { cmd: 'xargs', desc: '参数传递', example: 'find . -name "*.tmp" | xargs rm', category: '其他' }
];

const CATEGORIES: string[] = ['全部', '文件', '搜索', '文本', '进程', '系统', '权限', '网络', '压缩', '其他'];

@Component
export struct LinuxCmdPage {
  @State keyword: string = '';
  @State category: string = '全部';

  filtered(): LinuxCmd[] {
    let list = COMMANDS;
    if (this.category !== '全部') {
      list = list.filter(c => c.category === this.category);
    }
    const kw = this.keyword.trim().toLowerCase();
    if (kw.length > 0) {
      list = list.filter(c => c.cmd.toLowerCase().includes(kw) || c.desc.includes(kw));
    }
    return list;
  }

  build() {
    NavDestination() {
      Column({ space: 10 }) {
        TextInput({ placeholder: '搜索命令…', text: this.keyword })
          .height(42).borderRadius(21)
          .backgroundColor($r('app.color.bg_card'))
          .fontColor($r('app.color.text_primary'))
          .onChange((v: string) => { this.keyword = v; })

        Scroll() {
          Row({ space: 8 }) {
            ForEach(CATEGORIES, (c: string) => {
              Text(c)
                .fontSize(13)
                .fontColor(this.category === c ? Color.White : $r('app.color.text_secondary'))
                .padding({ left: 14, right: 14, top: 7, bottom: 7 })
                .borderRadius(15)
                .backgroundColor(this.category === c ? $r('app.color.accent') : $r('app.color.bg_card'))
                .onClick(() => { this.category = c; })
            }, (c: string) => c)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')

        List({ space: 10 }) {
          ForEach(this.filtered(), (c: LinuxCmd) => {
            ListItem() {
              Column({ space: 6 }) {
                Row({ space: 8 }) {
                  Text(c.cmd)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.accent'))
                  Text(c.desc)
                    .fontSize(13)
                    .fontColor($r('app.color.text_secondary'))
                }
                Text(c.example)
                  .fontSize(12)
                  .fontColor($r('app.color.text_primary'))
                  .padding(10)
                  .borderRadius(8)
                  .backgroundColor('#1A5B6BF5')
                  .width('100%')
                  .copyOption(CopyOptions.LocalDevice)
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding(14)
              .borderRadius(14)
              .backgroundColor($r('app.color.bg_card'))
            }
          }, (c: LinuxCmd) => c.cmd)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .padding(20)
      .width('100%')
      .height('100%')
    }
    .title('Linux 速查')
    .backgroundColor($r('app.color.bg_page'))
  }
}
