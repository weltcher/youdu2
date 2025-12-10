package utils

import (
	"fmt"

	rtctokenbuilder "github.com/AgoraIO/Tools/DynamicKey/AgoraDynamicKey/go/src/rtctokenbuilder2"
)

// GenerateRtcToken 生成 Agora RTC Token（使用官方SDK）
// appID: Agora App ID
// appCertificate: Agora App Certificate
// channelName: 频道名称
// uid: 用户ID（0表示任意用户）
// expirationTimeInSeconds: token 有效期（秒）
//
// 参考: github.com/AgoraIO/Tools/DynamicKey/AgoraDynamicKey/go/src/rtctokenbuilder2
// 示例: BuildTokenWithUid(appId, appCertificate, channelName, uid, role, tokenExpire, privilegeExpire)
func GenerateRtcToken(appID, appCertificate, channelName string, uid uint32, expirationTimeInSeconds uint32) (string, error) {
	if appID == "" || appCertificate == "" {
		return "", fmt.Errorf("appID or appCertificate is empty")
	}

	if expirationTimeInSeconds == 0 {
		expirationTimeInSeconds = 3600 // 默认1小时
	}

	// 使用 RolePublisher 角色（允许发送和接收音视频流）
	// tokenExpire: token本身的过期时间（秒）
	// privilegeExpire: 权限的过期时间（秒）
	// 官方示例: BuildTokenWithUid(appId, appCertificate, channelName, uid, RolePublisher, tokenExpire, privilegeExpire)
	token, err := rtctokenbuilder.BuildTokenWithUid(
		appID,
		appCertificate,
		channelName,
		uid,
		rtctokenbuilder.RolePublisher, // 使用Publisher角色，可以发送和接收音视频
		expirationTimeInSeconds,       // token过期时间
		expirationTimeInSeconds,       // 权限过期时间
	)

	if err != nil {
		return "", fmt.Errorf("failed to build token: %v", err)
	}

	return token, nil
}

// GenerateRtcTokenWithAccount 使用用户账号生成 Token
// 参考官方示例: BuildTokenWithUserAccount
func GenerateRtcTokenWithAccount(appID, appCertificate, channelName string, userAccount string, expirationTimeInSeconds uint32) (string, error) {
	if appID == "" || appCertificate == "" {
		return "", fmt.Errorf("appID or appCertificate is empty")
	}

	if expirationTimeInSeconds == 0 {
		expirationTimeInSeconds = 3600 // 默认1小时
	}

	// 使用官方SDK的 BuildTokenWithUserAccount 方法
	token, err := rtctokenbuilder.BuildTokenWithUserAccount(
		appID,
		appCertificate,
		channelName,
		userAccount,
		rtctokenbuilder.RolePublisher, // 使用Publisher角色
		expirationTimeInSeconds,       // token过期时间
		expirationTimeInSeconds,       // 权限过期时间
	)

	if err != nil {
		return "", fmt.Errorf("failed to build token with account: %v", err)
	}

	return token, nil
}

// GenerateRtcTokenWithPrivilege 生成带详细权限控制的 RTC Token
// 参考官方示例: BuildTokenWithUidAndPrivilege
func GenerateRtcTokenWithPrivilege(
	appID, appCertificate, channelName string,
	uid uint32,
	tokenExpire uint32,
	joinChannelPrivilegeExpire uint32,
	pubAudioPrivilegeExpire uint32,
	pubVideoPrivilegeExpire uint32,
	pubDataStreamPrivilegeExpire uint32,
) (string, error) {
	if appID == "" || appCertificate == "" {
		return "", fmt.Errorf("appID or appCertificate is empty")
	}

	// 使用官方SDK的 BuildTokenWithUidAndPrivilege 方法
	// 可以对不同的权限设置不同的过期时间
	token, err := rtctokenbuilder.BuildTokenWithUidAndPrivilege(
		appID,
		appCertificate,
		channelName,
		uid,
		tokenExpire,
		joinChannelPrivilegeExpire,
		pubAudioPrivilegeExpire,
		pubVideoPrivilegeExpire,
		pubDataStreamPrivilegeExpire,
	)

	if err != nil {
		return "", fmt.Errorf("failed to build token with privilege: %v", err)
	}

	return token, nil
}
