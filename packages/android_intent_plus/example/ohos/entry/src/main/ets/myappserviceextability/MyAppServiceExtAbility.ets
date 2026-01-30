
/*
* Copyright (C) 2026 Huawei Device Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import { AppServiceExtensionAbility, Want } from '@kit.AbilityKit';
import { rpc } from '@kit.IPCKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = '[MyAppServiceExtAbility]';
const DOMAIN_NUMBER: number = 0xFF00;

class StubTest extends rpc.RemoteObject {
  constructor(des: string) {
    super(des);
  }

  onRemoteMessageRequest(code: number,
    data: rpc.MessageSequence,
    reply: rpc.MessageSequence,
    options: rpc.MessageOption): boolean | Promise<boolean> {
    // 处理客户端发送的消息
    return true;
  }
}

export default class MyAppServiceExtAbility extends AppServiceExtensionAbility {
  onCreate(want: Want): void {
    let appServiceExtensionContext = this.context;
    hilog.info(DOMAIN_NUMBER, TAG, `onCreate, want: ${want.abilityName}`);
    // ···
  }

  onRequest(want: Want, startId: number): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onRequest, want: ${want.abilityName}`);
  }

  onConnect(want: Want): rpc.RemoteObject {
    hilog.info(DOMAIN_NUMBER, TAG, `onConnect, want: ${want.abilityName}`);
    return new StubTest('test');
  }

  onDisconnect(want: Want): void {
    hilog.info(DOMAIN_NUMBER, TAG, `onDisconnect, want: ${want.abilityName}`);
  }

  onDestroy(): void {
    hilog.info(DOMAIN_NUMBER, TAG, 'onDestroy');
  }
};
