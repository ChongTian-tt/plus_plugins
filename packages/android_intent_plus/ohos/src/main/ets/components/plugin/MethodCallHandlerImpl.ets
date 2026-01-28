import { MethodChannel, MethodCall, MethodResult, BinaryMessenger, MethodCallHandler, Any } from '@ohos/flutter_ohos';
import { WantSender } from './WantSender';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Want, common, insightIntent } from '@kit.AbilityKit';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';


const TAG = 'MethodCallHandlerImpl';
const CHANNEL_NAME = 'dev.fluttercommunity.plus/android_intent';

export class MethodCallHandlerImpl implements MethodCallHandler {
  private sender: WantSender;
  private methodChannel: MethodChannel | null = null;

  constructor(sender: WantSender) {
    this.sender = sender;
  }

  startListening(messenger: BinaryMessenger): void {
    if (this.methodChannel != null) {
      hilog.info(0x0000, TAG, "Setting a method call handler before the last was disposed.");
      this.stopListening();
    }
    hilog.info(0x0000, TAG, 'startListening');
    this.methodChannel = new MethodChannel(messenger, CHANNEL_NAME);
    this.methodChannel.setMethodCallHandler(this);
  }

  stopListening(): void {
    if (this.methodChannel == null) {
      hilog.info(0x0000, TAG, "Tried to stop listening when no methodChannel had been initialized.");
      return;
    }
    this.methodChannel.setMethodCallHandler(null);
    this.methodChannel = null;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    hilog.info(0x0000, TAG, 'onMethodCall');
    let want = this.getCallArguments(call);
    try {
      switch (call.method) {
        case 'launch':
          await this.launch(want);
          result.success(null);
          break;

        case 'sendService':
          await this.sender.sendService(want);
          result.success(null);
          break;

        case 'sendBroadcast':
          this.sender.sendBroadcast(want, result);
          break;

        case 'launchChooser':
          const title = call.argument('chooserTitle') as string;
          await this.sender.launchChooser(want, title);
          result.success(null);
          break;

        case 'parseAndLaunch':
          const uri = call.argument('uri') as string;
          want = this.sender.parse(uri);
          await this.sender.send(want);
          result.success(null);
          break;

        case 'canResolveActivity':
          // 此功能仅系统应用支持 三方应用不支持
          result.notImplemented();
          break;

        case 'getResolvedActivity':
          // 此功能仅系统应用支持 三方应用不支持
          result.notImplemented();
          break;

        default:
          result.notImplemented();
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Error handling method call: ${error.message}`);
      result.error('error', error.message, null);
    }
  }

  private getCallArguments(call: MethodCall): Want {
    const action = call.argument('action') as string;
    const flags = call.argument('flags') as number | null;
    const category = call.argument('category') as string | null;
    const data = call.argument('data') as string | null;

    // 从Map中获取参数
    const rawArgsMap: ESObject = call.argument("arguments");
    let args: Record<string, Object> = {};

    // 检查是否有forEach方法可用
    if (rawArgsMap && typeof rawArgsMap.forEach === 'function') {
      rawArgsMap.forEach((value: ESObject, key: string) => {
        hilog.info(0x0000, TAG, `Map Key: ${key}, Value: ${value}, Type: ${typeof value}`);
        args[key] = this.recursivelyConvertMap(value);
      });
    }

    // 获取参数前先进行详细调试日志
    const rawArrayArguments = call.argument('arrayArguments') as Record<string, Object[]>;
    const packageName = call.argument('package') as string | null;
    const componentName = call.argument('componentName') as string | null;
    const type = call.argument('type') as string | null;
    const entities = call.argument('entities') as string[] | null;
    hilog.info(0x0000, TAG, 'entities is ' + JSON.stringify(entities));

    // 合并arguments和arrayArguments
    let mergedArguments: Record<string, Object> = {};

    // 使用转换后的args
    this.getMergeArgs(args, mergedArguments, rawArrayArguments);

    let want: Want | null = this.sender.buildWant(
      action,
      flags,
      category,
      data,
      mergedArguments,
      packageName,
      componentName,
      type,
      entities
    );

    hilog.info(0x0000, TAG, 'want is ' + JSON.stringify(want));
    if (want) {
      return want;
    } else {
      return {} as Want;
    }
  }

  private recursivelyConvertMap(obj: ESObject): Object {
    // 如果是基本类型，直接返回
    if (obj === null || typeof obj !== 'object') {
      return obj;
    }

    // 先检查是否是数组（数组也有 forEach 方法，必须先判断）
    if (Array.isArray(obj)) {
      const result: Object[] = [];
      for (let i = 0; i < obj.length; i++) {
        result.push(this.recursivelyConvertMap(obj[i]));
      }
      hilog.info(0x0000, TAG, `Converted array: ${JSON.stringify(result)}`);
      return result;
    }

    // 检查是否是 Map 对象（有 forEach 方法但不是数组）
    if (typeof (obj as ESObject).forEach === 'function') {
      const converted: Record<string, Object> = {};
      (obj as ESObject).forEach((value: ESObject, key: string) => {
        hilog.info(0x0000, TAG, `Converting nested Map - Key: ${key}, Value: ${value}, Type: ${typeof value}`);
        converted[key] = this.recursivelyConvertMap(value);
      });
      return converted;
    }

    // 如果是普通对象
    const converted: Record<string, Object> = {};
    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      converted[key] = this.recursivelyConvertMap(obj[key]);
    }
    return converted;
  }

  private getMergeArgs(args: Record<string, Object> | null, mergedArguments: Record<string, Object>,
    arrayArguments: Record<string, Object[]> | null) {
    hilog.info(0x0000, TAG,
      'getMergeArgs called - args: ' + JSON.stringify(args) + ', arrayArguments: ' + JSON.stringify(arrayArguments));

    // 复制 arguments
    if (args && typeof args === 'object' && !Array.isArray(args)) {
      const argKeys = Object.keys(args);
      hilog.info(0x0000, TAG, 'Processing ' + argKeys.length + ' argument keys: ' + JSON.stringify(argKeys));
      for (let i = 0; i < argKeys.length; i++) {
        const key = argKeys[i];
        mergedArguments[key] = args[key];
        hilog.info(0x0000, TAG, 'Added argument: ' + key + ' = ' + JSON.stringify(args[key]));
      }
    } else {
      hilog.info(0x0000, TAG, 'Arguments not processed, either null or not an object');
    }

    // 合并 arrayArguments
    if (arrayArguments && typeof arrayArguments === 'object' && !Array.isArray(arrayArguments)) {
      const arrayKeys = Object.keys(arrayArguments);
      hilog.info(0x0000, TAG, 'Processing ' + arrayKeys.length + ' array argument keys: ' + JSON.stringify(arrayKeys));
      for (let i = 0; i < arrayKeys.length; i++) {
        const key = arrayKeys[i];
        // 对数组参数也进行递归转换
        mergedArguments[key] = this.recursivelyConvertMap(arrayArguments[key]);
        hilog.info(0x0000, TAG, 'Added array argument: ' + key + ' = ' + JSON.stringify(arrayArguments[key]));
      }
    } else {
      hilog.info(0x0000, TAG, 'Array arguments not processed, either null or not an object');
    }
  }

  private async launch(want: Want): Promise<void> {
    // 兼容部分场景 data 可能被编码成 geo%3A...
    try {
      if (want.uri && want.uri.startsWith('geo%3A')) {
        want.uri = decodeURIComponent(want.uri);
      }

      await this.sender.send(want);
    } catch (error) {
      hilog.error(0x0000, TAG, `Error handling launch: ${error.message}`);
    }
  }
}
