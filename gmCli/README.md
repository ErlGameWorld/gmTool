# GM工具前端项目

## 项目概述

GM工具前端是一个基于React + Vite + Ant Design构建的游戏管理工具前端界面，提供友好的用户界面来管理游戏服务器功能。

## 技术栈

### 核心框架
- **React 18.2.0** - 现代化前端框架
- **Vite 5.0.8** - 快速构建工具
- **JavaScript (ES6+)** - 主要开发语言，支持JSX语法

### UI组件库
- **Ant Design 5.12.8** - 企业级UI设计语言
- **@ant-design/icons** - 图标库

### 路由管理
- **React Router DOM 7.9.3** - 单页面应用路由

### HTTP客户端
- **Axios 1.6.2** - HTTP请求库

### 状态管理
- **React Context API** - 内置状态管理
- **useState/useEffect** - React Hooks

### 开发工具
- **@vitejs/plugin-react** - React插件
- **@types/react** - React类型定义（用于开发时类型提示）

## 项目结构

```
gmCli/
├── src/
│   ├── components/          # 可复用组件
│   ├── contexts/           # React Context状态管理
│   ├── pages/              # 页面组件
│   ├── styles/             # 样式文件
│   ├── utils/              # 工具函数
│   ├── App.jsx             # 根组件
│   ├── main.jsx            # 应用入口
│   └── index.css           # 全局样式
├── package.json            # 项目配置
├── vite.config.js          # Vite配置
└── index.html              # HTML模板
```

## 开发环境搭建

### 前置要求
- Node.js 16.0+ 
- npm 7.0+

### 安装依赖
```bash
# 进入项目目录
cd gmCli

# 安装依赖包
npm install
```

### 启动开发服务器
```bash
# 启动开发服务器（默认端口3000）
npm run dev

# 或者指定端口
npm run dev -- --port 3000
```

开发服务器启动后，访问 http://localhost:3000 即可查看应用。

### 开发环境配置

#### 后端API代理
开发环境下，前端通过Vite代理配置连接到后端服务器：

```javascript
// vite.config.js
server: {
  port: 3000,
  proxy: {
    '/api': {
      target: 'http://localhost:8080',  // 后端服务器地址
      changeOrigin: true,
      rewrite: (path) => path.replace(/^\/api/, '')
    }
  }
}
```

#### 环境变量
项目支持环境变量配置：
- 开发环境：`import.meta.env.DEV`
- 生产环境：`import.meta.env.PROD`

## 测试环境

### 单元测试
项目支持使用Jest进行单元测试：

```bash
# 安装测试依赖（如需）
npm install --save-dev jest @testing-library/react @testing-library/jest-dom

# 运行测试
npm test
```

### 组件测试示例
```javascript
import { render, screen } from '@testing-library/react'
import { AuthProvider } from './contexts/AuthContext'

describe('AuthContext', () => {
  test('should provide auth context', () => {
    render(
      <AuthProvider>
        <div>Test Component</div>
      </AuthProvider>
    )
    expect(screen.getByText('Test Component')).toBeInTheDocument()
  })
})
```

### E2E测试
推荐使用Cypress进行端到端测试：

```bash
# 安装Cypress
npm install --save-dev cypress

# 启动Cypress
npx cypress open
```

## 构建和打包

### 生产环境构建
```bash
# 构建生产版本
npm run build
```

构建完成后，生成的文件位于 `dist/` 目录：
- `dist/index.html` - 入口HTML文件
- `dist/assets/` - 静态资源文件
- `dist/manifest.json` - 资源清单

### 预览构建结果
```bash
# 预览生产构建
npm run preview
```

预览服务器默认运行在 http://localhost:4173

### 构建优化
Vite自动进行以下优化：
- 代码分割和懒加载
- Tree-shaking移除未使用代码
- 资源压缩和优化
- CSS代码分割

## 部署说明

### 静态文件部署
将 `dist/` 目录部署到任何静态文件服务器：

```bash
# 示例：部署到Nginx
sudo cp -r dist/* /var/www/html/

# 配置Nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API代理到后端
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Docker部署
创建Dockerfile：

```dockerfile
# 多阶段构建
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

构建和运行：
```bash
docker build -t gm-frontend .
docker run -p 80:80 gm-frontend
```

## 开发规范

### 代码规范
- 使用ESLint进行代码检查
- 遵循React Hooks最佳实践
- 组件采用函数式组件
- 使用PropTypes进行运行时类型检查

### 提交规范
推荐使用Conventional Commits：
```bash
feat: 新增功能
fix: 修复bug
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建工具或依赖更新
```

## 故障排除

### 常见问题

1. **端口占用**
   ```bash
   # 查找占用端口的进程
   netstat -ano | findstr :3000
   # 终止进程
   taskkill /PID <PID> /F
   ```

2. **依赖安装失败**
   ```bash
   # 清除缓存重新安装
   npm cache clean --force
   rm -rf node_modules package-lock.json
   npm install
   ```

3. **构建失败**
   - 检查Node.js版本是否符合要求
   - 确认所有依赖正确安装
   - 查看控制台错误信息

### 性能优化建议

1. **代码分割**
   ```javascript
   // 使用React.lazy进行懒加载
   const LazyComponent = React.lazy(() => import('./LazyComponent'))
   ```

2. **图片优化**
   - 使用WebP格式
   - 实现懒加载
   - 压缩图片资源

3. **缓存策略**
   - 配置HTTP缓存头
   - 使用Service Worker
   - 资源版本控制

## 技术支持

如有问题请联系开发团队或查看项目文档。