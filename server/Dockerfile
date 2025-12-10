# 多阶段构建 Dockerfile

# 第一阶段：构建
FROM golang:1.21-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装必要的工具
RUN apk add --no-cache git

# 复制 go.mod 和 go.sum
COPY go.mod ./

# 下载依赖
RUN go mod download

# 复制源代码
COPY . .

# 构建应用
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o youdu-server main.go

# 第二阶段：运行
FROM alpine:latest

# 安装 CA 证书
RUN apk --no-cache add ca-certificates tzdata

# 设置时区
ENV TZ=Asia/Shanghai

# 创建非 root 用户
RUN addgroup -g 1000 youdu && \
    adduser -D -u 1000 -G youdu youdu

# 设置工作目录
WORKDIR /home/youdu

# 从构建阶段复制二进制文件
COPY --from=builder /app/youdu-server .
COPY --from=builder /app/.env.example .env

# 修改文件所有者
RUN chown -R youdu:youdu /home/youdu

# 切换到非 root 用户
USER youdu

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

# 运行应用
CMD ["./youdu-server"]

