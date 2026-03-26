// PM2 Ecosystem Configuration
// 文档：https://pm2.keymetrics.io/docs/usage/application-declaration/
// 使用：pm2 start ecosystem.config.cjs

module.exports = {
  apps: [
    {
      name: 'keleme-api',
      script: 'dist/index.js',
      cwd: __dirname,

      // ── 实例与模式 ────────────────────────────────────────
      instances: 'max',         // 按 CPU 核心数自动扩展（cluster 模式）
      exec_mode: 'cluster',     // 多进程负载均衡
      // 注意：如果遇到 SSE 流式接口在 cluster 模式下的问题，
      //       可改为 exec_mode: 'fork', instances: 1

      // ── 环境变量 ──────────────────────────────────────────
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      env_development: {
        NODE_ENV: 'development',
        PORT: 3000,
      },

      // ── 日志 ──────────────────────────────────────────────
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: 'logs/error.log',
      out_file: 'logs/out.log',
      merge_logs: true,           // cluster 模式下合并日志
      log_type: 'json',           // 配合 Pino JSON 输出

      // ── 自动重启 ──────────────────────────────────────────
      max_memory_restart: '512M', // 内存超 512M 自动重启
      restart_delay: 5000,        // 重启间隔 5 秒
      max_restarts: 10,           // 最大连续重启次数
      min_uptime: 10000,          // 启动后 10 秒内崩溃视为启动失败

      // ── 文件监听（仅开发环境使用） ────────────────────────
      watch: false,               // 生产环境关闭
      ignore_watch: ['node_modules', 'logs', '.git', 'prisma/migrations'],

      // ── 优雅关闭 ──────────────────────────────────────────
      kill_timeout: 10000,        // 与 src/index.ts shutdown timeout 一致
      listen_timeout: 10000,      // 等待进程 ready 超时
      shutdown_with_message: true, // 发送 shutdown 消息

      // ── 健康检查（需要 pm2-auto-pull 或外部监控） ─────────
      // PM2 Plus 用户可启用：
      // health_check: {
      //   url: 'http://localhost:3000/health',
      //   interval: 30000,
      // },
    },
  ],

  // ── 部署配置（可选，用于 pm2 deploy） ─────────────────────
  deploy: {
    production: {
      user: 'deploy',
      host: ['your-server-ip'],
      ref: 'origin/main',
      repo: 'git@github.com:your-org/keleme.git',
      path: '/var/www/keleme',
      'pre-deploy-local': '',
      'post-deploy':
        'cd backend && npm ci --omit=dev && npx prisma generate && npx prisma migrate deploy && npm run build && pm2 reload ecosystem.config.cjs --env production',
      'pre-setup': '',
      env: {
        NODE_ENV: 'production',
      },
    },
  },
};
