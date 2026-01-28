import { FlutterAbility, FlutterEngine } from '@ohos/flutter_ohos';
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
// 导入OhosIntentPlugin
import OhosIntentPlugin from 'android_intent_plus';

import { commonEventManager } from '@kit.BasicServicesKit';
import { promptAction, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { notificationManager } from '@kit.NotificationKit';

interface Info {
  events: string[]
}

//订阅者信息
let subscribeInfo: Info = {
  events: ["com.example.broadcast"],
}

const TAG = 'OhosIntentPlugin'

export default class EntryAbility extends FlutterAbility {
  //用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作
  private subscriber: commonEventManager.CommonEventSubscriber | null = null

  async configureFlutterEngine(flutterEngine: FlutterEngine) {
    // 获取插件实例并设置上下文
    try {
      // 通过反射或直接导入的方式来设置上下文
      // 由于我们无法直接访问已注册的实例，我们直接调用插件的静态方法来设置全局上下文
      const pluginInstance: OhosIntentPlugin = new OhosIntentPlugin();
      if (pluginInstance && typeof pluginInstance.setContext === 'function') {
        pluginInstance.setContext(this.context);
        hilog.info(0x0000, TAG, "global context set successfully");
      }

      // 通知授权
      const isEnabled = await notificationManager.isNotificationEnabled();
      if (!isEnabled) {
        let requestEnableNotificationCallback = (err: BusinessError): void => {
          if (err) {
            hilog.error(0x0000, TAG, `requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
          } else {
            hilog.info(0x0000, TAG, ` requestEnableNotification success`);
          }
        };
        // 添加延时避免重复请求
        setTimeout(() => {
          notificationManager.requestEnableNotification(this.context, requestEnableNotificationCallback);
        }, 1000); // 1秒延时
      }


      //创建订阅者回调
      this.subscriber = await commonEventManager.createSubscriber(subscribeInfo)
      hilog.info(0x0000, TAG, "CreateSubscriber")

      commonEventManager.subscribe(this.subscriber, async (err: BusinessError, data: commonEventManager.CommonEventData) => {
        if (err) {
          hilog.error(0x0000, TAG,`Failed to subscribe. Code is ${err.code}, message is ${err.message}`);
          return;
        }
        hilog.info(0x0000, TAG, `Succeeded in subscribing, data is ${JSON.stringify(data)}`);
        await promptAction.openToast({ message: 'Broadcast Received!' })
      });
    } catch (error) {
      hilog.error(0x0000, TAG,"Failed to set context for OhosIntentPlugin:", error);
    }
    super.configureFlutterEngine(flutterEngine);
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }
}
