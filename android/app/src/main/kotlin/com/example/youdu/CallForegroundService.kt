package com.example.youdu

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * 来电前台服务
 * 保持服务在后台运行，监听来电事件
 */
class CallForegroundService : Service() {
    
    companion object {
        const val CHANNEL_ID = "call_service_channel"
        const val NOTIFICATION_ID = 1001
        
        // Intent 额外数据键
        const val EXTRA_CALLER_NAME = "caller_name"
        const val EXTRA_CALLER_ID = "caller_id"
        const val EXTRA_CALL_TYPE = "call_type"
        const val EXTRA_CHANNEL_NAME = "channel_name"
        const val EXTRA_IS_GROUP_CALL = "is_group_call"
        const val EXTRA_GROUP_ID = "group_id"
        const val EXTRA_MEMBERS = "members"
        
        // 动作
        const val ACTION_START_SERVICE = "START_SERVICE"
        const val ACTION_SHOW_CALL_OVERLAY = "SHOW_CALL_OVERLAY"
        const val ACTION_DISMISS_CALL_OVERLAY = "DISMISS_CALL_OVERLAY"
        const val ACTION_STOP_SERVICE = "STOP_SERVICE"
        
        // 用于跟踪当前的 CallOverlayActivity 实例
        var currentCallOverlayActivity: CallOverlayActivity? = null
    }
    
    private val TAG = "CallForegroundService"
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, " [CallForegroundService] onStartCommand 被调用，action: ${intent?.action}")
        
        when (intent?.action) {
            ACTION_START_SERVICE -> {
                Log.d(TAG, " [CallForegroundService] 启动前台服务...")
                createNotificationChannel()
                val notification = createNotification()
                
                // Android 14+ (API 34+) 需要显式指定前台服务类型
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(
                        NOTIFICATION_ID, 
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                    )
                    Log.d(TAG, " [CallForegroundService] 前台服务已启动（Android 14+，类型: PHONE_CALL），通知ID: $NOTIFICATION_ID")
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                    Log.d(TAG, " [CallForegroundService] 前台服务已启动，通知ID: $NOTIFICATION_ID")
                }
            }
            ACTION_SHOW_CALL_OVERLAY -> {
                Log.d(TAG, " [CallForegroundService] 收到显示弹窗命令")
                val callerName = intent.getStringExtra(EXTRA_CALLER_NAME) ?: "未知来电"
                val callerId = intent.getIntExtra(EXTRA_CALLER_ID, 0)
                val callType = intent.getStringExtra(EXTRA_CALL_TYPE) ?: "voice"
                val channelName = intent.getStringExtra(EXTRA_CHANNEL_NAME) ?: ""
                val isGroupCall = intent.getBooleanExtra(EXTRA_IS_GROUP_CALL, false)
                val groupId = if (intent.hasExtra(EXTRA_GROUP_ID)) intent.getIntExtra(EXTRA_GROUP_ID, 0) else null
                val members = intent.getStringExtra(EXTRA_MEMBERS)
                
                val callTypeStr = if (isGroupCall) "群组通话" else "单人通话"
                Log.d(TAG, " [CallForegroundService] 来电信息: $callerName, ID: $callerId, 类型: $callType ($callTypeStr)")
                if (isGroupCall) {
                    Log.d(TAG, "   - 群组ID: $groupId")
                    Log.d(TAG, "   - 成员信息: $members")
                }
                showCallOverlay(callerName, callerId, callType, channelName, isGroupCall, groupId, members)
            }
            ACTION_DISMISS_CALL_OVERLAY -> {
                Log.d(TAG, " [CallForegroundService] 收到关闭弹窗命令")
                dismissCallOverlay()
            }
            ACTION_STOP_SERVICE -> {
                Log.d(TAG, " [CallForegroundService] 停止前台服务")
                stopForeground(true)
                stopSelf()
            }
            else -> {
                Log.w(TAG, " [CallForegroundService] 未知的 action: ${intent?.action}")
            }
        }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    /**
     * 创建通知渠道
     * 🔴 修复：将前台服务通知渠道设置为最小优先级，使其不在通知栏显示
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 前台服务通知渠道 - 设置为最小优先级，不在通知栏显示
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "来电服务",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "保持来电服务运行"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            
            // 来电通知渠道（高优先级）
            val callChannel = NotificationChannel(
                "call_channel",
                "来电通知",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "显示来电通知"
                setShowBadge(true)
                enableVibration(true)
                enableLights(true)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(serviceChannel)
            notificationManager.createNotificationChannel(callChannel)
        }
    }
    
    /**
     * 创建前台服务通知
     * 🔴 修复：创建一个不可见的通知，使服务在后台运行而不在通知栏显示
     */
    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("")
            .setContentText("")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setVisibility(NotificationCompat.VISIBILITY_SECRET)
            .setShowWhen(false)
            .setOngoing(true)
            .build()
    }
    
    /**
     * 显示来电弹窗
     */
    private fun showCallOverlay(
        callerName: String,
        callerId: Int,
        callType: String,
        channelName: String,
        isGroupCall: Boolean = false,
        groupId: Int? = null,
        members: String? = null
    ) {
        Log.d(TAG, "🎯 [CallForegroundService] 准备启动 CallOverlayActivity...")
        
        val overlayIntent = Intent(this, CallOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra(EXTRA_CALLER_NAME, callerName)
            putExtra(EXTRA_CALLER_ID, callerId)
            putExtra(EXTRA_CALL_TYPE, callType)
            putExtra(EXTRA_CHANNEL_NAME, channelName)
            putExtra(EXTRA_IS_GROUP_CALL, isGroupCall)
            if (isGroupCall && groupId != null) {
                putExtra(EXTRA_GROUP_ID, groupId)
                if (members != null) {
                    putExtra(EXTRA_MEMBERS, members)
                }
            }
        }
        
        try {
            // 方案1: 使用全屏通知（推荐）
            Log.d(TAG, "🚀 [CallForegroundService] 方案1: 使用全屏通知...")
            val fullScreenIntent = PendingIntent.getActivity(
                this,
                0,
                overlayIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            // 创建全屏通知
            val notification = NotificationCompat.Builder(this, "call_channel")
                .setContentTitle("来电: $callerName")
                .setContentText("点击接听")
                .setSmallIcon(android.R.drawable.ic_menu_call)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_CALL)
                .setFullScreenIntent(fullScreenIntent, true)
                .setAutoCancel(true)
                .setOngoing(true)
                .setDefaults(NotificationCompat.DEFAULT_ALL)
                .setVibrate(longArrayOf(0, 1000, 1000, 1000))
                .build()
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.notify(NOTIFICATION_ID + 1, notification)
            
            Log.d(TAG, "✅ [CallForegroundService] 全屏通知已发送")
            
            // 方案2: 备用 - 尝试直接启动（可能被阻止）
            try {
                Log.d(TAG, "🚀 [CallForegroundService] 方案2: 尝试直接启动 Activity...")
                startActivity(overlayIntent)
                Log.d(TAG, "✅ [CallForegroundService] Activity 直接启动成功")
            } catch (directStartException: Exception) {
                Log.w(TAG, "⚠️ [CallForegroundService] Activity 直接启动被阻止: ${directStartException.message}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ [CallForegroundService] 显示来电弹窗失败: ${e.message}", e)
        }
    }
    
    /**
     * 关闭来电弹窗
     */
    private fun dismissCallOverlay() {
        try {
            Log.d(TAG, "❌ [CallForegroundService] 开始关闭来电弹窗...")
            
            // 关闭当前的 CallOverlayActivity
            currentCallOverlayActivity?.let { activity ->
                Log.d(TAG, "✅ [CallForegroundService] 找到活动的弹窗 Activity，正在关闭...")
                activity.finish()
                currentCallOverlayActivity = null
            } ?: run {
                Log.w(TAG, "⚠️ [CallForegroundService] 没有找到活动的弹窗 Activity")
            }
            
            // 取消来电通知
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.cancel(NOTIFICATION_ID + 1)
            Log.d(TAG, "✅ [CallForegroundService] 来电通知已取消")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ [CallForegroundService] 关闭来电弹窗失败: ${e.message}", e)
        }
    }
}
