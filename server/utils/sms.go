package utils

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
)

// SMSConfig 短信配置
type SMSConfig struct {
	Account  string // 短信平台账号
	Password string // 短信平台密码
	APIURL   string // 短信平台API地址
}

// SMSResponse 短信平台响应
type SMSResponse struct {
	Code    int    `json:"code"`
	Msg     string `json:"msg"`
	Smsid   string `json:"smsid"`
}

// DefaultSMSConfig 默认短信配置（互亿无线）
var DefaultSMSConfig = SMSConfig{
	Account:  "C56967717",
	Password: "740aa34fc6146f5734ad080e415a1d89",
	APIURL:   "https://106.ihuyi.com/webservice/sms.php",
}

// SendLoginSMS 发送登录验证码短信
// phone: 手机号
// code: 6位数字验证码
func SendLoginSMS(phone, code string) error {
	// 构建短信内容
	content := fmt.Sprintf("您的验证码是：%s。请不要把验证码泄露给其他人。", code)

	return SendSMS(phone, content)
}

// SendSMS 发送短信
func SendSMS(phone, content string) error {
	// 构建请求参数
	params := url.Values{}
	params.Set("method", "Submit")
	params.Set("account", DefaultSMSConfig.Account)
	params.Set("password", DefaultSMSConfig.Password)
	params.Set("mobile", phone)
	params.Set("content", content)
	params.Set("format", "json")

	// 构建完整URL
	fullURL := fmt.Sprintf("%s?%s", DefaultSMSConfig.APIURL, params.Encode())

	LogDebug("📱 发送短信请求: phone=%s, content=%s", phone, content)

	// 发送HTTP请求
	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return fmt.Errorf("创建请求失败: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("发送请求失败: %v", err)
	}
	defer resp.Body.Close()

	// 读取响应
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取响应失败: %v", err)
	}

	LogDebug("📱 短信平台响应: %s", string(body))

	// 解析响应
	var smsResp SMSResponse
	if err := json.Unmarshal(body, &smsResp); err != nil {
		// 尝试解析为其他格式
		LogDebug("⚠️ JSON解析失败，原始响应: %s", string(body))
		// 检查是否包含成功标识
		if strings.Contains(string(body), "提交成功") || strings.Contains(string(body), "success") {
			LogDebug("✅ 短信发送成功（根据响应内容判断）")
			return nil
		}
		return fmt.Errorf("解析响应失败: %v", err)
	}

	// 检查发送结果
	// 互亿无线返回码: 2表示成功
	if smsResp.Code == 2 {
		LogDebug("✅ 短信发送成功: smsid=%s", smsResp.Smsid)
		return nil
	}

	return fmt.Errorf("短信发送失败: code=%d, msg=%s", smsResp.Code, smsResp.Msg)
}
