import { deviceInfo } from '@kit.BasicServicesKit';
import { display } from '@kit.ArkUI';

interface InfoItem {
  label: string;
  value: string;
}

@Component
export struct DeviceInfoPage {
  @State items: InfoItem[] = [];

  aboutToAppear(): void {
    const list: InfoItem[] = [];
    try {
      list.push({ label: '品牌', value: deviceInfo.brand });
      list.push({ label: '型号', value: deviceInfo.marketName });
      list.push({ label: '产品名', value: deviceInfo.productModel });
      list.push({ label: '设备类型', value: deviceInfo.deviceType });
      list.push({ label: '系统版本', value: deviceInfo.osFullName });
      list.push({ label: '系统 API 版本', value: deviceInfo.sdkApiVersion.toString() });
      list.push({ label: '构建版本', value: deviceInfo.displayVersion });
      list.push({ label: '安全补丁', value: deviceInfo.securityPatchTag });
      list.push({ label: 'CPU ABI', value: deviceInfo.abiList });
    } catch (err) {
      console.error('deviceInfo failed:', JSON.stringify(err));
    }
    try {
      const d = display.getDefaultDisplaySync();
      list.push({ label: '分辨率', value: `${d.width} × ${d.height} px` });
      list.push({ label: '刷新率', value: `${d.refreshRate} Hz` });
      list.push({ label: '像素密度', value: `${d.densityDPI} dpi` });
    } catch (err) {
      console.error('display failed:', JSON.stringify(err));
    }
    this.items = list;
  }

  build() {
    NavDestination() {
      List({ space: 10 }) {
        ForEach(this.items, (item: InfoItem) => {
          ListItem() {
            Row() {
              Text(item.label)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .width(110)
              Text(item.value)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .copyOption(CopyOptions.LocalDevice)
            }
            .width('100%')
            .padding(16)
            .borderRadius(14)
            .backgroundColor($r('app.color.bg_card'))
          }
        }, (item: InfoItem) => item.label)
      }
      .padding(20)
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title('设备信息')
    .backgroundColor($r('app.color.bg_page'))
  }
}
