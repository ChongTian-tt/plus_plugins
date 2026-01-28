# Android 前台服务 Demo 说明

这个 demo 展示了如何使用 `android_intent_plus` 插件来启动和停止 Android 前台服务。

## 功能说明

### 1. 前台服务特点
- 启动服务时会在通知栏显示一个持久通知
- 通知显示 "Android Intent Plus 服务运行中"
- 点击通知可以返回应用
- 通知不能被用户滑动删除（onGoing = true）
- 服务运行期间会持续显示在通知栏

### 2. 实现的功能
- ✅ 启动前台服务（点击 "Tap here to start service" 按钮）
- ✅ 停止前台服务（点击 "Tap here to stop service" 按钮）
- ✅ 服务启动/停止日志输出到 Logcat

## 如何测试

### 步骤 1：运行应用
```bash
cd example
flutter run
```

### 步骤 2：启动服务
1. 在应用主界面，点击 **"Tap here to start service"** 按钮
2. 观察通知栏，会出现一个持久通知显示 "Android Intent Plus 服务运行中"
3. 下拉通知栏可以看到完整的通知内容

### 步骤 3：验证服务正在运行
- 方法 1：检查通知栏是否显示服务通知
- 方法 2：打开设备的 "设置 > 应用 > android_intent_example > 正在运行的服务"
- 方法 3：查看 Logcat 日志：
  ```bash
  adb logcat | grep MyForegroundService
  ```

### 步骤 4：停止服务
1. 点击 **"Tap here to stop service"** 按钮
2. 通知栏中的服务通知会立即消失
3. Logcat 会输出 "Service onDestroy() - Service stopped"

## 代码说明

### 关键文件

#### 1. `MyForegroundService.java`
前台服务实现类，主要功能：
- `onCreate()`: 创建通知渠道
- `onStartCommand()`: 启动前台服务并显示通知
- `onDestroy()`: 服务停止时的清理工作
- `createNotification()`: 创建通知对象

#### 2. `AndroidManifest.xml`
服务配置：
```xml
<!-- 前台服务权限 -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />

<!-- 服务声明 -->
<service
    android:name=".MyForegroundService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="specialUse">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
    </intent-filter>
</service>
```

#### 3. `main.dart`
Flutter 侧调用代码：
```dart
// 启动服务
void _startService() {
  const intent = AndroidIntent(
    action: 'android.intent.action.MAIN',
    package: 'io.flutter.plugins.androidintentexample',
    componentName: 'io.flutter.plugins.androidintentexample.MyForegroundService',
  );
  intent.sendService();
}

// 停止服务
void _stopService() {
  const intent = AndroidIntent(
    action: 'android.intent.action.MAIN',
    package: 'io.flutter.plugins.androidintentexample',
    componentName: 'io.flutter.plugins.androidintentexample.MyForegroundService',
  );
  intent.stopService();
}
```

## 技术要点

### 1. 前台服务类型
Android 14+ 需要声明前台服务类型：
- 使用 `specialUse` 类型用于演示目的
- 生产环境应根据实际用途选择合适的类型（如 dataSync、mediaPlayback 等）

### 2. 通知渠道
Android 8.0+ 必须创建通知渠道才能显示通知：
```java
NotificationChannel channel = new NotificationChannel(
    CHANNEL_ID,
    "Android Intent Example Service",
    NotificationManager.IMPORTANCE_DEFAULT
);
```

### 3. PendingIntent 标志
Android 12+ 需要明确指定 PendingIntent 的可变性：
```java
PendingIntent pendingIntent = PendingIntent.getActivity(
    this,
    0,
    notificationIntent,
    Build.VERSION.SDK_INT >= Build.VERSION_CODES.M 
        ? PendingIntent.FLAG_IMMUTABLE 
        : 0
);
```

### 4. 完整组件名
启动服务需要指定完整的组件名：
- `package`: 应用包名
- `componentName`: 完整的服务类名（包名.类名）

## 查看日志

使用以下命令查看服务运行日志：

```bash
# 只看服务相关日志
adb logcat | grep MyForegroundService

# 看所有相关日志
adb logcat | grep -E "MyForegroundService|IntentSender"

# 清空日志后重新开始
adb logcat -c && adb logcat | grep MyForegroundService
```

## 预期输出

### 启动服务时的日志：
```
D/MyForegroundService: Service onCreate()
D/MyForegroundService: Service onStartCommand()
D/MyForegroundService: Service started as foreground service with notification
V/IntentSender: Sending service intent Intent { act=android.intent.action.MAIN pkg=io.flutter.plugins.androidintentexample cmp=io.flutter.plugins.androidintentexample/.MyForegroundService }
```

### 停止服务时的日志：
```
V/IntentSender: Stopping service Intent { act=android.intent.action.MAIN pkg=io.flutter.plugins.androidintentexample cmp=io.flutter.plugins.androidintentexample/.MyForegroundService }
D/MyForegroundService: Service onDestroy() - Service stopped
```

## 常见问题

### Q1: 通知没有显示？
A: 检查是否授予了通知权限。在设备设置中找到应用，确保通知权限已开启。

### Q2: 服务无法启动？
A: 确保：
1. AndroidManifest.xml 中正确声明了服务
2. 已添加 FOREGROUND_SERVICE 权限
3. package 和 componentName 参数正确

### Q3: Android 14+ 设备上服务启动失败？
A: 确保添加了 `FOREGROUND_SERVICE_SPECIAL_USE` 权限，并在 service 标签中声明了 `foregroundServiceType`。

### Q4: 点击通知没有反应？
A: 检查 PendingIntent 的标志是否正确设置（Android 12+ 需要 FLAG_IMMUTABLE）。

## 扩展建议

如果你想进一步扩展这个 demo，可以考虑：

1. **添加服务内部逻辑**：在 `onStartCommand()` 中添加后台任务（如定时任务、下载等）
2. **通知操作按钮**：在通知中添加快捷操作按钮
3. **服务状态回调**：通过 EventChannel 将服务状态回传给 Flutter
4. **多种服务类型**：实现不同类型的服务（前台服务、后台服务、绑定服务）
5. **服务生命周期管理**：添加更复杂的启动/停止逻辑

## 参考资料

- [Android 前台服务文档](https://developer.android.com/develop/background-work/services/foreground-services)
- [Android 通知文档](https://developer.android.com/develop/ui/views/notifications)
- [Android Intent 文档](https://developer.android.com/reference/android/content/Intent)
