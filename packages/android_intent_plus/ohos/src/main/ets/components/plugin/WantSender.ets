import common from '@ohos.app.ability.common';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Want, wantAgent, wantConstant, WantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager, reminderAgent } from '@kit.BackgroundTasksKit';
import { commonEventManager } from '@kit.BasicServicesKit';
import { MethodResult } from '@ohos/flutter_ohos';
import { reminderAgentManager } from '@kit.BackgroundTasksKit';


const TAG = 'WantSender';

export class WantSender {
  public context: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  // 构建Want对象
  buildWant(
    action: string | null,
    flags: number | null,
    category: string | null,
    data: string | null,
    parameters: Record<string, Object>,
    packageName: string | null,
    componentName: string | null,
    type: string | null,
    entities: string[] | null
  ): Want | null {
    if (!this.context) {
      hilog.error(0x0000, TAG, 'Context not initialized');
      return null;
    }

    let want: Want = {};
    if (action) {
      want.action = action;
    }
    if (data) {
      want.uri = data;
    }
    if (packageName) {
      want.bundleName = packageName;
    }
    if (componentName) {
      want.abilityName = componentName;
    }
    if (parameters && Object.keys(parameters).length !== 0) {
      want.parameters = parameters;
    }
    if (type) {
      want.type = type;
    }
    // 处理entities
    if (entities && entities.length > 0) {
      hilog.info(0x0000, TAG, 'entities11  is ' + JSON.stringify(entities));
      want.entities = entities;
    }
    // 处理flags
    if (flags) {
      // HarmonyOS Want flags映射
      if (flags & 0x10000000) {
        want.flags = wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION;
      }
    }

    return want;
  }

  // 启动Ability
  async send(want: Want): Promise<void> {
    if (!this.context) {
      hilog.error(0x0000, TAG, 'Context not initialized');
      return;
    }
    try {

      if (want.action == 'ohos.want.action.setAlarm' && want.parameters) {
        let alarm: reminderAgent.ReminderRequestAlarm = {
          reminderType: reminderAgent.ReminderType.REMINDER_TYPE_ALARM,  // 提醒类型为闹钟类型
          hour: want.parameters.hour as number,  // 指明提醒的目标时刻
          minute: want.parameters.minute as number,  // 指明提醒的目标分钟
          wantAgent: {  // 点击提醒通知后跳转的目标UIAbility信息
            pkgName: 'com.example.reminderagentmanager',
            abilityName: 'EntryAbility'
          },
          title: want.parameters.title as string,  // 指明提醒标题, "app.string.alarm_clock"资源文件中的value值为"闹钟"
          content:  want.parameters.content as string,  // 指明提醒内容, "app.string.alarm_clock_reach"资源文件中的value值为"闹钟时间已到"
          daysOfWeek: want.parameters.daysOfWeek as number[] // 指明每周哪几天需要重复提醒
        }
        let reminderId: number = await reminderAgentManager.publishReminder(alarm);
        hilog.info(0x0000, TAG, 'Want reminderAgentManager successfully. reminderId：' + reminderId);
      }

      await this.context.startAbility(want);
      hilog.info(0x0000, TAG, 'Want sent successfully');
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to start ability: ${error.message}`);
    }
  }

  // 启动长时任务
  async sendService(want: Want): Promise<void> {
    if (!this.context) {
      hilog.error(0x0000, TAG, 'Context not initialized');
      return;
    }

    let wants: Want[] = [];
    wants.push(want);

    let mode = backgroundTaskManager.BackgroundMode.DATA_TRANSFER;
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: wants,
      requestCode: 0
    };

    if (want.parameters) {
      if (want.parameters.actionType) {
        wantAgentInfo.actionType = want.parameters.actionType as number;
      }

      if (want.parameters.requestCode) {
        wantAgentInfo.requestCode = want.parameters.requestCode as number;
      }

      if (want.parameters.actionFlags) {
        wantAgentInfo.actionFlags = want.parameters.actionFlags as wantAgent.WantAgentFlags[];
      }

      if (want.parameters.mode) {
        mode = want.parameters.mode as backgroundTaskManager.BackgroundMode;
      }
    }

    try {
      hilog.info(0x0000, TAG, "Operation startBackgroundRunning wantAgentInfo: " + JSON.stringify(wantAgentInfo));
      // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
      let wantAgentObj: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);
      await backgroundTaskManager.startBackgroundRunning(this.context, mode, wantAgentObj);
      hilog.info(0x0000, TAG, "Operation startBackgroundRunning succeeded");
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to start service: ${error.message}`);
    }
  }

  // 发送广播
  sendBroadcast(want: Want, result: MethodResult): void {
    if (!this.context) {
      hilog.error(0x0000, TAG, 'Context not initialized');
      return;
    }

    // 准备公共事件发布的数据
    let options: commonEventManager.CommonEventPublishData = {
      code: 0,
      data: JSON.stringify(want.parameters || {}),
    }

    try {
      // 发布公共事件,使用Want对象中的action作为事件名称
      commonEventManager.publish(want.action, options, (err) => {
        if (err) {
          hilog.error(0x0000, TAG, "PublishCallBack err=" + JSON.stringify(err))
        } else {
          hilog.info(0x0000, TAG, `Succeeded in publishing common event: ${want.action}`);
          result.success(null);
        }
      })
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to publish common event: ${error.message}`);
    }
  }

  // 启动选择器
  async launchChooser(want: Want, title: string): Promise<void> {
    if (!this.context) {
      hilog.error(0x0000, TAG, 'Context not initialized');
      return;
    }

    try {
      await this.context.startAbility(want);
      hilog.info(0x0000, TAG, 'Chooser launched successfully');
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to launch chooser: ${error.message}`);
    }
  }

  // 解析json字符串为Want对象
  parse(jsonStr: string): Want {
    try {
      // 尝试解析JSON字符串
      const jsonObj: Record<string, Object> = JSON.parse(jsonStr);

      // 创建Want对象
      const want: Want = {};

      // 映射JSON对象的所有属性到Want对象
      if (jsonObj.action) {
        want.action = jsonObj.action as string;
      }

      if (jsonObj.uri) {
        want.uri = jsonObj.uri as string;
      }

      if (jsonObj.bundleName) {
        want.bundleName = jsonObj.bundleName as string;
      }

      if (jsonObj.abilityName) {
        want.abilityName = jsonObj.abilityName as string;
      }

      if (jsonObj.deviceId) {
        want.deviceId = jsonObj.deviceId as string;
      }

      if (jsonObj.type) {
        want.type = jsonObj.type as string;
      }

      if (jsonObj.flags !== undefined && jsonObj.flags !== null) {
        want.flags = jsonObj.flags as number;
      }

      if (jsonObj.parameters) {
        want.parameters = jsonObj.parameters as Record<string, Object>;
      }

      if (jsonObj.entities) {
        want.entities = jsonObj.entities as Array<string>;
      }

      if (jsonObj.moduleName) {
        want.moduleName = jsonObj.moduleName as string;
      }

      return want;
    } catch (error) {
      hilog.error(0x0000, TAG, 'Failed to parse JSON string: ' + (error as Error).message);
      // 如果JSON解析失败，返回一个空的Want对象
      return {};
    }
  }
}
