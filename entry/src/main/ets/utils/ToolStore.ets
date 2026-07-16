import { preferences } from '@kit.ArkData';

/**
 * 轻量 JSON 存储：每个工具一个 key，整体序列化。
 */
export class ToolStore {
  private static prefCache?: preferences.Preferences;

  static async get(ctx: Context, key: string, def: string): Promise<string> {
    try {
      if (ToolStore.prefCache === undefined) {
        ToolStore.prefCache = await preferences.getPreferences(ctx, 'treasure_bag_tools');
      }
      return ToolStore.prefCache.getSync(key, def) as string;
    } catch (err) {
      console.error('ToolStore.get failed:', JSON.stringify(err));
      return def;
    }
  }

  static save(key: string, value: string): void {
    try {
      ToolStore.prefCache?.putSync(key, value);
      ToolStore.prefCache?.flush();
    } catch (err) {
      console.error('ToolStore.save failed:', JSON.stringify(err));
    }
  }
}
