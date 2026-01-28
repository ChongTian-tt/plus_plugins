import {
  FlutterPlugin,
  FlutterPluginBinding,
} from '@ohos/flutter_ohos';
import { MethodCallHandlerImpl } from './MethodCallHandlerImpl';
import { WantSender } from './WantSender';
import { common } from '@kit.AbilityKit';

let globalCtx: common.UIAbilityContext | null = null;

/** OhosIntentPlugin **/
export default class OhosIntentPlugin implements FlutterPlugin {
  private sender: WantSender | null = null;
  private impl: MethodCallHandlerImpl | null = null;

  getUniqueClassName(): string {
    return 'OhosIntentPlugin'
  }

  // 使用 UIAbility 的context
  setContext(context: common.UIAbilityContext): void {
    globalCtx = context;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    if (globalCtx) {
      this.sender = new WantSender(globalCtx);
      this.impl = new MethodCallHandlerImpl(this.sender);
      this.impl.startListening(binding.getBinaryMessenger());
    }
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.impl?.stopListening();
    this.sender = null;
    this.impl = null;
    globalCtx = null;
  }
}
