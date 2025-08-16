# Dockerfile

# 构建阶段
FROM node:18-alpine AS builder

WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 package 文件
COPY package.json pnpm-lock.yaml ./

# 安装依赖
RUN pnpm install --no-frozen-lockfile

# 复制源代码
COPY . .

# 构建应用（如果有构建步骤）
RUN pnpm build

# 生产阶段
FROM node:18-alpine AS production

WORKDIR /app

# 安装 pnpm
RUN npm install -g pnpm

# 复制 package 文件
COPY package.json pnpm-lock.yaml ./

# 安装生产依赖
RUN pnpm install --prod --no-frozen-lockfile

# 从构建阶段复制构建产物（根据你的项目结构调整）
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/app ./app

# 复制其他必要文件
COPY --from=builder /app/.next ./.next 2>/dev/null || echo "No Next.js build"
COPY --from=builder /app/public ./public 2>/dev/null || echo "No public directory"

# 创建非 root 用户
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

USER nextjs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["pnpm", "start"]