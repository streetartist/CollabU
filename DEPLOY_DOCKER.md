# CollabU Docker Compose 部署指南

本指南使用 **Docker Compose** 一键部署 CollabU 前后端分离项目，作为宝塔面板方案（见 `DEPLOY_GUIDE.md`）的替代方案。与宝塔方式相比，Docker 方案环境隔离、可移植、升级回滚方便。

## 1. 架构总览

整个系统由 3 个容器组成（通过内部网络 `collabu-net` 通信）：

```
                      ┌─────────────────────────────────────────┐
 浏览器  ── 80 端口 ──▶│  frontend (Nginx)                      │
 (用户)                │   ▪ 托管前端静态资源 (dist)              │
                      │   ▪ 反向代理:                           │
                      │      /api      ──▶ backend:5000         │
                      │      /socket.io ──▶ backend:5000 (WS)   │
                      │      /uploads   ──▶ backend:5000         │
                      └───────────────┬─────────────────────────┘
                                      │
                                      ▼
                      ┌─────────────────────────────────────────┐
                      │  backend (Gunicorn + eventlet)          │
                      │  Flask API + SocketIO WebSocket          │
                      │  启动时执行 flask db upgrade 建表        │
                      └───────────────┬─────────────────────────┘
                                      │ DATABASE_URL
                                      ▼
                      ┌─────────────────────────────────────────┐
                      │  mysql:8.0 (MySQL 数据库，数据持久化)     │
                      └─────────────────────────────────────────┘
```

| 服务 | 镜像基础 | 端口 | 数据卷 |
|------|---------|------|--------|
| `mysql` | mysql:8.0 | 内部 3306 | `mysql_data` |
| `backend` | python:3.11-slim（自建） | 内部 5000 | `uploads_data`、`instance_data` |
| `frontend` | nginx:1.27-alpine（自建） | **80**（对外） | - |

## 2. 前置条件

- 安装了 **Docker Engine** 和 **Docker Compose v2**（`docker compose` 子命令）。
  验证：`docker compose version`
- 服务器开放 **80 端口**（若修改 `WEB_PORT` 则为对应端口）。

## 3. 开始部署

### 3.1 准备环境变量

在项目根目录创建 `.env` 文件（可从模板复制）：

```bash
cp .env.example .env
```

**必改项**（生产环境）：

| 变量 | 说明 |
|------|------|
| `SECRET_KEY` | Flask 应用密钥，改为强随机串 |
| `JWT_SECRET_KEY` | JWT 签名密钥，改为强随机串 |
| `MYSQL_ROOT_PASSWORD` | MySQL root 密码，改为强密码 |
| `MYSQL_PASSWORD` | 应用数据库用户密码，改为强密码 |
| `WEB_PORT` | 前端对外端口（默认 80，可改如 8080） |

### 3.2 构建并启动

```bash
# 构建镜像并后台启动
docker compose up -d --build

# 查看启动状态
docker compose ps

# 跟踪日志（首次启动后端会自动建表，可观察 flask db upgrade 输出）
docker compose logs -f backend
```

### 3.3 验证

浏览器访问 `http://<服务器IP>`（或带端口 `http://<服务器IP>:8080`）。

1. 注册一个账号 → 登录。
2. 创建团队、项目、任务。
3. 测试上传文件（`/uploads`）与实时聊天（`/socket.io` WebSocket）。

## 4. 常用运维命令

```bash
# 查看所有容器状态
docker compose ps

# 查看某个服务的日志
docker compose logs -f backend
docker compose logs -f frontend

# 重新构建并启动（代码有改动后）
docker compose up -d --build

# 停止服务（保留数据卷）
docker compose down

# 停止并删除容器与网络（保留数据卷）
docker compose down

# 彻底清理（连同数据卷一起删除！会丢失数据库与上传文件，慎用）
docker compose down -v
```

## 5. 数据持久化与备份

- 数据库、上传文件、SQLite 实例数据分别存放在命名卷 `mysql_data`、`uploads_data`、`instance_data` 中，**容器重建不丢失**。
- **备份数据库**：
  ```bash
  docker compose exec mysql sh -c 'exec mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' > backup.sql
  ```
- 备份上传文件：备份 `uploads_data` 卷内容（可用 `docker run --rm -v collabu_uploads_data:/data -v $(pwd):/backup alpine tar czf /backup/uploads.tar.gz -C /data .`）。

## 6. 反向代理细节（对应宝塔方案）

本方案由 `frontend` 容器内的 Nginx 完成宝塔方案中的“前端托管 + 反向代理”，配置见 `frontend/nginx.conf`：

| 路径 | 反代目标 | 说明 |
|------|---------|------|
| `/` | 静态文件 | Vue Router history 模式，`try_files ... /index.html` 防止刷新 404 |
| `/api` | `backend:5000` | REST API |
| `/socket.io` | `backend:5000` | WebSocket（含 `Upgrade`/`Connection` 头） |
| `/uploads` | `backend:5000` | 上传文件访问 |

> 若你希望在前置再加一层如 Nginx/负载均衡，可保留本方案的内部结构，只把 `WEB_PORT` 映射关闭，改由外部网关反代到 frontend 容器。

## 7. 常见问题

- **首次启动后前端能打开但接口 500/报错**：查看 `docker compose logs backend` 是否建表失败，通常与 `.env` 中 `MYSQL_PASSWORD`/`DATABASE_URL` 不一致有关。
- **MySQL 启动慢 / 依赖超时**：compose 已配置 `depends_on: condition: service_healthy`，backend 会等 MySQL 健康后再启动。
- **无法访问上传的文件**：确认 frontend 的 `location /uploads` 反代正常，且 backend 的 `uploads_data` 卷存在。
- **端口冲突**：80 被占用时，在 `.env` 设置 `WEB_PORT=8080` 后重新 `docker compose up -d`。
- **eventlet 与部分系统库冲突**：已锁定 eventlet worker，正常无需处理；如需更高并发可自行调整为 `--workers`，但 eventlet 下通常保持 `--workers 1` 为宜。

## 8. 文件清单

| 文件 | 作用 |
|------|------|
| `docker-compose.yml` | 编排 mysql / backend / frontend 三服务 |
| `backend/Dockerfile` | 后端镜像（Gunicorn + eventlet） |
| `frontend/Dockerfile` | 前端多阶段构建（Node 构建 + Nginx） |
| `frontend/nginx.conf` | Nginx 静态托管与反向代理配置 |
| `.env.example` | 环境变量模板（复制为 `.env`） |
| `backend/.dockerignore` / `frontend/.dockerignore` | 控制构建上下文，避免打入本地产物 |
