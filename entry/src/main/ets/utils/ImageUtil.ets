import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';

export interface PickedImage {
  pixelMap: image.PixelMap;
  width: number;
  height: number;
  sizeBytes: number;
}

export class ImageUtil {
  /** 图库选图（PhotoViewPicker 免权限），返回 PixelMap 与元信息 */
  static async pick(editable: boolean): Promise<PickedImage | undefined> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const result = await picker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });
      if (result.photoUris.length === 0) {
        return undefined;
      }
      const uri = result.photoUris[0];
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const source = image.createImageSource(file.fd);
      const pm = await source.createPixelMap({ editable: editable });
      const info = pm.getImageInfoSync();
      source.release();
      fileIo.closeSync(file);
      const picked: PickedImage = {
        pixelMap: pm,
        width: info.size.width,
        height: info.size.height,
        sizeBytes: stat.size
      };
      return picked;
    } catch (err) {
      console.error('pick image failed:', JSON.stringify(err));
      return undefined;
    }
  }

  /** PixelMap → JPEG 字节 */
  static async encodeJpeg(pm: image.PixelMap, quality: number): Promise<ArrayBuffer | undefined> {
    try {
      const packer = image.createImagePacker();
      const buf = await packer.packToData(pm, { format: 'image/jpeg', quality: quality });
      packer.release();
      return buf;
    } catch (err) {
      console.error('encode jpeg failed:', JSON.stringify(err));
      return undefined;
    }
  }

  /** 保存 JPEG 到相册（在 SaveButton 安全控件回调内调用，免权限） */
  static async saveBufferToAlbum(ctx: Context, buf: ArrayBuffer): Promise<boolean> {
    try {
      const helper = photoAccessHelper.getPhotoAccessHelper(ctx);
      const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
      const file = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fileIo.writeSync(file.fd, buf);
      fileIo.closeSync(file);
      return true;
    } catch (err) {
      console.error('save to album failed:', JSON.stringify(err));
      return false;
    }
  }

  static async saveToAlbum(ctx: Context, pm: image.PixelMap, quality: number): Promise<boolean> {
    const buf = await ImageUtil.encodeJpeg(pm, quality);
    if (buf === undefined) {
      return false;
    }
    return ImageUtil.saveBufferToAlbum(ctx, buf);
  }

  static fmtSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    }
    if (bytes < 1048576) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    }
    return `${(bytes / 1048576).toFixed(2)} MB`;
  }
}
