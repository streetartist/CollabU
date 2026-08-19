# CollabU Frontend (Vue3) - Dockerfile
# 多阶段构建：阶段1 用 Node 构建静态资源，阶段2 用 Nginx 托管并反向代理后端

# ---------- 阶段 1: 构建 ----------
FROM node:20-alpine AS build

WORKDIR /app

# 先复制依赖清单以利用 Docker 层缓存
COPY package*.json ./
RUN npm ci

# 复制源码并构建
COPY . .
RUN npm run build

# ---------- 阶段 2: 运行 (Nginx) ----------
FROM nginx:1.27-alpine

# 使用自定义 Nginx 配置（静态托管 + 后端反向代理）
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 将构建产物复制到 Nginx 站点根目录
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
