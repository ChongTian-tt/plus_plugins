package io.flutter.plugins.androidintentexample;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;
import androidx.annotation.Nullable;

/**
 * 简单的后台服务示例
 * 用于演示 android_intent_plus 的 sendService 和 stopService 功能
 */
public class MyBackgroundService extends Service {
    private static final String TAG = "MyBackgroundService";
    
    // 服务运行状态（静态变量，方便外部查询）
    private static boolean isRunning = false;
    
    public static boolean isServiceRunning() {
        return isRunning;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "Service onCreate()");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "Service onStartCommand() - 服务已启动");
        isRunning = true;
        
        // 这里可以执行后台任务
        // 例如：数据同步、文件下载等
        
        // START_NOT_STICKY 表示服务被系统杀死后不会自动重启
        return START_NOT_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        isRunning = false;
        Log.d(TAG, "Service onDestroy() - 服务已停止");
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        // 不提供绑定功能
        return null;
    }
}
