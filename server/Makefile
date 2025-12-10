.PHONY: help run build clean test install docker-build docker-up docker-down setup-db

# 默认目标
help:
	@echo "可用的命令:"
	@echo "  make run          - 运行开发服务器"
	@echo "  make build        - 构建可执行文件"
	@echo "  make clean        - 清理构建文件"
	@echo "  make test         - 运行测试"
	@echo "  make install      - 安装依赖"
	@echo "  make setup-db     - 初始化数据库"
	@echo "  make docker-build - 构建 Docker 镜像"
	@echo "  make docker-up    - 启动 Docker 容器"
	@echo "  make docker-down  - 停止 Docker 容器"

# 运行开发服务器
run:
	go run main.go

# 构建可执行文件
build:
	go build -o youdu-server main.go

# 清理构建文件
clean:
	rm -f youdu-server youdu-server.exe

# 运行测试
test:
	go test -v ./...

# 安装依赖
install:
	go mod download
	go mod tidy

# 初始化数据库
setup-db:
	psql -U postgres -c "CREATE DATABASE youdu_db;"
	psql -U postgres -d youdu_db -f db/init.sql

# 构建 Docker 镜像
docker-build:
	docker-compose build

# 启动 Docker 容器
docker-up:
	docker-compose up -d

# 停止 Docker 容器
docker-down:
	docker-compose down

# 查看 Docker 日志
docker-logs:
	docker-compose logs -f

# 重启 Docker 容器
docker-restart:
	docker-compose restart youdu-server

