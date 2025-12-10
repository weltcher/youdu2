package com.example.youdu

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * 自定义来电弹窗视图
 * 显示顶部横幅样式的来电提示
 */
class CallOverlayView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {
    
    private val callerNameTextView: TextView
    private val callTypeTextView: TextView
    private val avatarImageView: ImageView
    private val answerButton: LinearLayout
    private val rejectButton: LinearLayout
    
    private var onAnswerClickListener: (() -> Unit)? = null
    private var onRejectClickListener: (() -> Unit)? = null
    
    init {
        LayoutInflater.from(context).inflate(R.layout.view_call_overlay, this, true)
        
        // 初始化视图
        callerNameTextView = findViewById(R.id.caller_name)
        callTypeTextView = findViewById(R.id.call_type)
        avatarImageView = findViewById(R.id.caller_avatar)
        answerButton = findViewById(R.id.answer_button)
        rejectButton = findViewById(R.id.reject_button)
        
        // 设置按钮点击事件
        answerButton.setOnClickListener {
            onAnswerClickListener?.invoke()
        }
        
        rejectButton.setOnClickListener {
            onRejectClickListener?.invoke()
        }
    }
    
    /**
     * 设置来电信息
     */
    fun setCallInfo(callerName: String, callType: String) {
        callerNameTextView.text = callerName
        
        val typeText = when (callType) {
            "voice" -> "邀请你语音通话"
            "video" -> "邀请你视频通话"
            else -> "邀请你通话"
        }
        callTypeTextView.text = typeText
    }
    
    /**
     * 设置接听按钮点击监听
     */
    fun setOnAnswerClickListener(listener: () -> Unit) {
        onAnswerClickListener = listener
    }
    
    /**
     * 设置拒绝按钮点击监听
     */
    fun setOnRejectClickListener(listener: () -> Unit) {
        onRejectClickListener = listener
    }
}
