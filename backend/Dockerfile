# CollabU Backend (Flask) - Dockerfile
# 生产环境使用 Gunicorn + eventlet worker 以支持 Flask-SocketIO 的 WebSocket

FROM python:3.11-slim

# 避免生成 .pyc 并保证日志实时输出
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 先复制依赖清单以利用 Docker 层缓存
COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

# 安装 curl 用于容器健康检查（python:3.11-slim 默认不含 curl）
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# 复制后端源码
COPY . .

# 确保上传目录存在（生产数据会通过 volume 挂载覆盖）
RUN mkdir -p /app/uploads /app/instance

EXPOSE 5000

# 启动时先执行数据库迁移建表，再以 eventlet worker 启动 Gunicorn。
# eventlet 与 Flask-SocketIO 配合以支持 WebSocket 实时功能。
CMD ["sh", "-c", "flask db upgrade && gunicorn --worker-class gunicorn.workers.geventlet.EventletWorker --workers 1 --bind 0.0.0.0:5000 'app:create_app()'"]
