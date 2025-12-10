package com.example.youdu

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity
 * 处理 Flutter 与原生 Android 的通信
 */
class MainActivity : FlutterActivity() {
    
    companion object {
        private const val CALL_CHANNEL = "com.example.youdu/call"
        private const val TAG = "MainActivity"
    }
    
    private var methodChannel: MethodChannel? = null
    private var pendingCallData: Map<String, Any?>? = null
    private var stopAudioReceiver: BroadcastReceiver? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "🔧 [configureFlutterEngine] 开始配置 Flutter 引擎")
        
        // 创建 MethodChannel
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CALL_CHANNEL
        )
        
        Log.d(TAG, "✅ [configureFlutterEngine] MethodChannel 已创建")
        
        // 设置方法调用处理器
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // 启动来电前台服务
                "startCallService" -> {
                    startCallService()
                    result.success(true)
                }
                
                // 显示来电弹窗
                "showCallOverlay" -> {
                    Log.d(TAG, "📲 [MethodChannel] 收到 showCallOverlay 请求")
                    Log.d(TAG, "📲 [MethodChannel] 原始参数: ${call.arguments}")
                    
                    val callerName = call.argument<String>("callerName") ?: "未知来电"
                    val callerId = call.argument<Int>("callerId") ?: 0
                    val callType = call.argument<String>("callType") ?: "voice"
                    val channelName = call.argument<String>("channelName") ?: ""
                    val isGroupCall = call.argument<Boolean>("isGroupCall") ?: false
                    val groupId = call.argument<Int>("groupId")
                    val members = call.argument<List<Map<String, Any>>>("members")
                    
                    Log.d(TAG, "📲 [MethodChannel] 解析后的参数:")
                    Log.d(TAG, "   - callerName: $callerName")
                    Log.d(TAG, "   - callerId: $callerId")
                    Log.d(TAG, "   - callType: $callType")
                    Log.d(TAG, "   - channelName: $channelName")
                    Log.d(TAG, "   - isGroupCall: $isGroupCall")
                    Log.d(TAG, "   - groupId: $groupId")
                    Log.d(TAG, "   - members: ${members?.size ?: 0} 个")
                    if (members != null) {
                        Log.d(TAG, "   - members 详情: $members")
                    }
                    
                    showCallOverlay(callerName, callerId, callType, channelName, isGroupCall, groupId, members)
                    result.success(true)
                }
                
                // 关闭来电弹窗
                "dismissCallOverlay" -> {
                    dismissCallOverlay()
                    result.success(true)
                }
                
                // 停止来电前台服务
                "stopCallService" -> {
                    stopCallService()
                    result.success(true)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // 检查是否有待处理的来电数据
        if (pendingCallData != null) {
            Log.d(TAG, "📲 [configureFlutterEngine] 发现待处理的来电数据，立即发送")
            Log.d(TAG, "📲 待处理的数据: $pendingCallData")
            
            // 🔴 关键：延迟更长时间，确保 Flutter 端完全准备好并且 mobile_home_page 已加载
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                if (methodChannel != null) {
                    Log.d(TAG, "📤 [configureFlutterEngine] 发送待处理的来电数据到 Flutter")
                    methodChannel?.invokeMethod("onIncomingCall", pendingCallData)
                    pendingCallData = null
                    Log.d(TAG, "✅ [configureFlutterEngine] 待处理的来电数据已发送")
                } else {
                    Log.e(TAG, "❌ [configureFlutterEngine] MethodChannel 仍未准备，无法发送数据")
                }
            }, 1000) // 增加延迟到 1 秒
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 🔴 如果是来电相关的 Intent，设置锁屏显示标志，确保直接打开应用
        if (intent?.action == "incoming_call") {
            Log.d(TAG, "🔒 检测到来电 Intent，设置锁屏显示标志，直接打开应用")
            
            // 🔴 关键：设置锁屏显示标志，确保应用直接显示在锁屏上方，不显示系统提醒窗口
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                // Android 8.1+ 使用新 API
                setShowWhenLocked(true)
                setTurnScreenOn(true)
                
                // 🔴 主动请求解锁（Android 8.1+）
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                keyguardManager.requestDismissKeyguard(this, null)
                Log.d(TAG, "🔓 已请求解锁屏幕")
            } else {
                // 旧版本使用窗口标志
                @Suppress("DEPRECATION")
                window.addFlags(
                    android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                )
            }
            
            Log.d(TAG, "✅ 锁屏显示标志已设置，应用将直接显示")
        }
        
        // 🔴 关键修复：在 onCreate 中就注册广播接收器，确保后台也能收到广播
        registerStopAudioReceiver()
        
        // 检查是否是从来电弹窗打开的
        handleIncomingCallIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        // 🔴 如果是来电相关的 Intent，设置锁屏显示标志
        if (intent?.action == "incoming_call") {
            Log.d(TAG, "🔒 检测到来电 Intent (onNewIntent)，设置锁屏显示标志")
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
                
                // 🔴 主动请求解锁（Android 8.1+）
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                keyguardManager.requestDismissKeyguard(this, null)
                Log.d(TAG, "🔓 已请求解锁屏幕 (onNewIntent)")
            } else {
                @Suppress("DEPRECATION")
                window.addFlags(
                    android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    android.view.WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
                )
            }
            
            Log.d(TAG, "✅ 锁屏显示标志已设置 (onNewIntent)")
        }
        
        // 处理新的 Intent
        handleIncomingCallIntent(intent)
    }
    
    /**
     * 处理来电 Intent
     */
    private fun handleIncomingCallIntent(intent: Intent?) {
        Log.d(TAG, "🔍 [handleIncomingCallIntent] 检查 Intent")
        Log.d(TAG, "   - Intent action: ${intent?.action}")
        
        // 处理拒绝通话
        if (intent?.action == "call_rejected") {
            val callerId = intent.getIntExtra(CallForegroundService.EXTRA_CALLER_ID, 0)
            val callType = intent.getStringExtra(CallForegroundService.EXTRA_CALL_TYPE)
            
            Log.d(TAG, "❌ [handleIncomingCallIntent] 收到拒绝通话请求")
            Log.d(TAG, "   - callerId: $callerId")
            Log.d(TAG, "   - callType: $callType")
            
            // 通知 Flutter 发送拒绝消息
            if (methodChannel != null) {
                methodChannel?.invokeMethod("onCallRejected", mapOf(
                    "callerId" to callerId,
                    "callType" to callType
                ))
                Log.d(TAG, "✅ [handleIncomingCallIntent] 已通知 Flutter 发送拒绝消息")
            } else {
                Log.d(TAG, "⚠️ [handleIncomingCallIntent] MethodChannel 未准备")
            }
            return
        }
        
        // 处理来电
        if (intent?.action == "incoming_call") {
            val callerName = intent.getStringExtra(CallForegroundService.EXTRA_CALLER_NAME)
            val callerId = intent.getIntExtra(CallForegroundService.EXTRA_CALLER_ID, 0)
            val callType = intent.getStringExtra(CallForegroundService.EXTRA_CALL_TYPE)
            val channelName = intent.getStringExtra(CallForegroundService.EXTRA_CHANNEL_NAME)
            val isGroupCall = intent.getBooleanExtra(CallForegroundService.EXTRA_IS_GROUP_CALL, false)
            val isAnswered = intent.getBooleanExtra("isAnswered", false) // 🔴 新增：是否已接听
            val groupId = if (intent.hasExtra(CallForegroundService.EXTRA_GROUP_ID)) {
                intent.getIntExtra(CallForegroundService.EXTRA_GROUP_ID, 0)
            } else null
            val members = intent.getStringExtra(CallForegroundService.EXTRA_MEMBERS)
            
            val callTypeStr = if (isGroupCall) "群组通话" else "单人通话"
            Log.d(TAG, "📲 [handleIncomingCallIntent] 收到来电信息:")
            Log.d(TAG, "   - 来电者: $callerName")
            Log.d(TAG, "   - 来电者ID: $callerId")
            Log.d(TAG, "   - 通话类型: $callType ($callTypeStr)")
            Log.d(TAG, "   - 频道名称: $channelName")
            Log.d(TAG, "   - 已接听: $isAnswered") // 🔴 新增日志
            if (isGroupCall) {
                Log.d(TAG, "   - 群组ID: $groupId")
                Log.d(TAG, "   - 成员信息: $members")
            }
            
            val callData = mutableMapOf<String, Any?>(
                "callerName" to callerName,
                "callerId" to callerId,
                "callType" to callType,
                "channelName" to channelName,
                "isGroupCall" to isGroupCall,
                "isAnswered" to isAnswered // 🔴 新增：传递已接听标志
            )
            
            if (isGroupCall && groupId != null) {
                callData["groupId"] = groupId
                if (members != null) {
                    callData["members"] = members
                }
            }
            
            // 如果 methodChannel 已经准备好，直接发送
            if (methodChannel != null) {
                Log.d(TAG, "✅ [handleIncomingCallIntent] MethodChannel 已准备，直接发送")
                methodChannel?.invokeMethod("onIncomingCall", callData)
            } else {
                // 否则缓存数据，等待 Flutter 引擎准备好
                Log.d(TAG, "⏳ [handleIncomingCallIntent] MethodChannel 未准备，缓存数据")
                pendingCallData = callData
            }
        } else {
            Log.d(TAG, "ℹ️ [handleIncomingCallIntent] Intent action 不是 incoming_call")
        }
    }
    
    /**
     * 启动来电前台服务
     */
    private fun startCallService() {
        Log.d(TAG, "🚀 [MainActivity] 启动来电前台服务...")
        
        val serviceIntent = Intent(this, CallForegroundService::class.java).apply {
            action = CallForegroundService.ACTION_START_SERVICE
        }
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Log.d(TAG, "📱 [MainActivity] Android 8.0+，使用 startForegroundService")
                startForegroundService(serviceIntent)
            } else {
                Log.d(TAG, "📱 [MainActivity] Android 8.0以下，使用 startService")
                startService(serviceIntent)
            }
            Log.d(TAG, "✅ [MainActivity] 前台服务启动命令已发送")
        } catch (e: Exception) {
            Log.e(TAG, "❌ [MainActivity] 启动前台服务失败: ${e.message}", e)
        }
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
        members: List<Map<String, Any>>? = null
    ) {
        val callTypeStr = if (isGroupCall) "群组通话" else "单人通话"
        Log.d(TAG, "📲 [MainActivity] 显示来电弹窗: $callerName, 类型: $callType ($callTypeStr)")
        if (isGroupCall) {
            Log.d(TAG, "   - 群组ID: $groupId")
            Log.d(TAG, "   - 成员数: ${members?.size ?: 0}")
        }
        
        val serviceIntent = Intent(this, CallForegroundService::class.java).apply {
            action = CallForegroundService.ACTION_SHOW_CALL_OVERLAY
            putExtra(CallForegroundService.EXTRA_CALLER_NAME, callerName)
            putExtra(CallForegroundService.EXTRA_CALLER_ID, callerId)
            putExtra(CallForegroundService.EXTRA_CALL_TYPE, callType)
            putExtra(CallForegroundService.EXTRA_CHANNEL_NAME, channelName)
            putExtra(CallForegroundService.EXTRA_IS_GROUP_CALL, isGroupCall)
            if (isGroupCall && groupId != null) {
                putExtra(CallForegroundService.EXTRA_GROUP_ID, groupId)
                // 将成员列表序列化为 JSON 字符串
                if (members != null) {
                    val membersJson = android.text.TextUtils.join(",", members.map { member ->
                        "{\"user_id\":${member["user_id"]},\"display_name\":\"${member["display_name"]}\"}"
                    })
                    putExtra(CallForegroundService.EXTRA_MEMBERS, "[$membersJson]")
                }
            }
        }
        
        Log.d(TAG, "📤 [MainActivity] 发送显示弹窗命令到服务...")
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }
    
    /**
     * 关闭来电弹窗
     */
    private fun dismissCallOverlay() {
        Log.d(TAG, "❌ [MainActivity] 关闭来电弹窗")
        
        val serviceIntent = Intent(this, CallForegroundService::class.java).apply {
            action = CallForegroundService.ACTION_DISMISS_CALL_OVERLAY
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }
    
    /**
     * 停止来电前台服务
     */
    private fun stopCallService() {
        val serviceIntent = Intent(this, CallForegroundService::class.java).apply {
            action = CallForegroundService.ACTION_STOP_SERVICE
        }
        startService(serviceIntent)
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // 🔴 只在销毁时取消注册广播接收器
        unregisterStopAudioReceiver()
        methodChannel?.setMethodCallHandler(null)
    }
    
    /**
     * 注册停止音频广播接收器
     */
    private fun registerStopAudioReceiver() {
        if (stopAudioReceiver != null) {
            Log.d(TAG, "⚠️ 广播接收器已注册，跳过")
            return
        }
        
        stopAudioReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                Log.d(TAG, "📡 收到停止音频广播")
                
                // 通知 Flutter 停止音频
                if (methodChannel != null) {
                    Log.d(TAG, "🔇 通知 Flutter 停止播放音频")
                    methodChannel?.invokeMethod("stopCallAudio", null)
                } else {
                    Log.d(TAG, "⚠️ MethodChannel 未准备，无法停止音频")
                }
            }
        }
        
        val filter = IntentFilter("com.example.youdu.STOP_CALL_AUDIO")
        
        // 🔴 Android 13+ 需要明确指定接收器导出标志
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(stopAudioReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(stopAudioReceiver, filter)
        }
        
        Log.d(TAG, "✅ 广播接收器已注册")
    }
    
    /**
     * 取消注册停止音频广播接收器
     */
    private fun unregisterStopAudioReceiver() {
        if (stopAudioReceiver != null) {
            try {
                unregisterReceiver(stopAudioReceiver)
                stopAudioReceiver = null
                Log.d(TAG, "✅ 停止音频广播接收器已取消注册")
            } catch (e: Exception) {
                Log.e(TAG, "❌ 取消注册停止音频广播接收器失败: $e")
            }
        }
    }
}
