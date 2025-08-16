# Dockerfile

# 构建阶段
FROM node:20-alpine AS builder

WORKDIR /app

# 安装 pnpm 和 curl（用于健康检查）
RUN npm install -g pnpm curl

# 复制 package 文件
COPY package.json pnpm-lock.yaml ./

# 安装所有依赖
RUN pnpm install --frozen-lockfile

# 复制源代码
COPY . .

# 构建应用（如果有构建步骤）
RUN pnpm build

# 生产阶段
FROM node:20-alpine AS production

WORKDIR /app

# 安装 curl（用于健康检查）
RUN apk add --no-cache curl

# 从构建阶段复制 node_modules
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml

# 复制构建产物和必要文件
COPY --from=builder /app/dist ./dist 2>/dev/null || echo "No dist directory"
COPY --from=builder /app/app ./app 2>/dev/null || echo "No app directory"
COPY --from=builder /app/public ./public 2>/dev/null || echo "No public directory"
COPY --from=builder /app/.next ./.next 2>/dev/null || echo "No Next.js build"

# 复制启动脚本
COPY --from=builder /app/*.js ./ 2>/dev/null || echo "No js files in root"
COPY --from=builder /app/*.json ./ 2>/dev/null || echo "No json files in root"

# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 设置权限
RUN chown -R nextjs:nodejs /app
USER nextjs

EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# 启动应用
CMD ["pnpm", "start"]