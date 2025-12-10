package middleware

import (
	"bytes"
	"encoding/json"
	"io"
	"time"

	"youdu-server/utils"

	"github.com/gin-gonic/gin"
)

// 自定义响应写入器，用于捕获响应内容
type responseWriter struct {
	gin.ResponseWriter
	body *bytes.Buffer
}

func (w responseWriter) Write(b []byte) (int, error) {
	w.body.Write(b)
	return w.ResponseWriter.Write(b)
}

// LoggerMiddleware 记录所有HTTP请求和响应的中间件
func LoggerMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		startTime := time.Now()

		// 跳过批量在线状态查询接口的日志记录
		isSkipLogging := c.Request.URL.Path == "/api/user/batch-online-status"

		// 读取请求体
		var requestBody []byte
		if c.Request.Body != nil {
			requestBody, _ = io.ReadAll(c.Request.Body)
			// 重新设置请求体，因为已经被读取了
			c.Request.Body = io.NopCloser(bytes.NewBuffer(requestBody))
		}

		// 创建自定义响应写入器
		blw := &responseWriter{
			ResponseWriter: c.Writer,
			body:           bytes.NewBufferString(""),
		}
		c.Writer = blw

		// 如果是跳过日志的接口，直接处理请求
		if isSkipLogging {
			c.Next()
			return
		}

		// 记录请求信息
		utils.LogDebug("\n========== 请求开始 ==========")
		utils.LogDebug("时间: %s", startTime.Format("2006-01-02 15:04:05"))
		utils.LogDebug("方法: %s", c.Request.Method)
		utils.LogDebug("路径: %s", c.Request.URL.Path)
		utils.LogDebug("客户端IP: %s", c.ClientIP())
		utils.LogDebug("User-Agent: %s", c.Request.UserAgent())

		// 记录请求头
		utils.LogDebug("请求头:")
		for key, values := range c.Request.Header {
			for _, value := range values {
				utils.LogDebug("  %s: %s", key, value)
			}
		}

		// 记录查询参数
		if len(c.Request.URL.RawQuery) > 0 {
			utils.LogDebug("查询参数: %s", c.Request.URL.RawQuery)
		}

		// 记录请求体（跳过上传接口，避免打印大量二进制数据）
		isUploadEndpoint := c.Request.URL.Path == "/api/upload/video/chunk" ||
			c.Request.URL.Path == "/api/upload/image" ||
			c.Request.URL.Path == "/api/upload/file" ||
			c.Request.URL.Path == "/api/upload/avatar"

		if len(requestBody) > 0 && !isUploadEndpoint {
			// 尝试格式化JSON
			var prettyJSON bytes.Buffer
			if err := json.Indent(&prettyJSON, requestBody, "", "  "); err == nil {
				utils.LogDebug("请求体 (JSON):\n%s", prettyJSON.String())
			} else {
				utils.LogDebug("请求体: %s", string(requestBody))
			}
		} else if len(requestBody) > 0 && isUploadEndpoint {
			if c.Request.URL.Path == "/api/upload/video/chunk" {
				utils.LogDebug("请求体: [视频分片数据，已跳过]")
			} else {
				utils.LogDebug("请求体: [文件上传数据，已跳过]")
			}
		}

		// 处理请求
		c.Next()

		// 计算耗时
		duration := time.Since(startTime)

		// 记录响应信息
		utils.LogDebug("---------- 响应信息 ----------")
		utils.LogDebug("状态码: %d", c.Writer.Status())
		utils.LogDebug("耗时: %v", duration)

		// 记录响应头
		utils.LogDebug("响应头:")
		for key, values := range c.Writer.Header() {
			for _, value := range values {
				utils.LogDebug("  %s: %s", key, value)
			}
		}

		// 记录响应体（跳过上传接口，避免打印大量数据）
		responseBody := blw.body.String()

		if len(responseBody) > 0 && !isUploadEndpoint {
			// 尝试格式化JSON
			var prettyJSON bytes.Buffer
			if err := json.Indent(&prettyJSON, []byte(responseBody), "", "  "); err == nil {
				utils.LogDebug("响应体 (JSON):\n%s", prettyJSON.String())
			} else {
				utils.LogDebug("响应体: %s", responseBody)
			}
		} else if len(responseBody) > 0 && isUploadEndpoint {
			if c.Request.URL.Path == "/api/upload/video/chunk" {
				utils.LogDebug("响应体: [视频上传响应，已跳过]")
			} else {
				utils.LogDebug("响应体: [文件上传响应，已跳过]")
			}
		}

		utils.LogDebug("========== 请求结束 ==========\n")
	}
}
