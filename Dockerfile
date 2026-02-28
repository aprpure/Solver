# 使用 Python 3.10 基础镜像（slim 变体），支持 amd64 和 arm64
FROM python:3.10-slim

# 设置环境变量，防止交互式安装提示
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# 安装 Camoufox/Firefox 运行所需的系统库
RUN apt-get update && apt-get install -y \
    # GTK / 图形库
    libgtk-3-0 \
    libdbus-glib-1-2 \
    libxt6 \
    libx11-xcb1 \
    # 音频
    libasound2 \
    # GLib
    libglib2.0-0 \
    # NSS（网络安全服务）
    libnss3 \
    # 图形合成 / 渲染
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    # 基础工具（健康检查用）
    curl \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 先复制依赖文件，利用 Docker 层缓存加速重复构建
COPY requirements.txt .

# 安装 Python 依赖包
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 预下载 Camoufox 浏览器二进制文件
# camoufox fetch 会自动检测当前架构（amd64/arm64）并下载对应版本
RUN python -m camoufox fetch

# 复制项目源代码（放在依赖安装之后，优化缓存利用）
COPY . .

# 暴露服务端口
EXPOSE 7860

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# 启动命令：使用 camoufox 浏览器，5个并发线程，开启 debug 模式
CMD ["python", "api_solver.py", "--host", "0.0.0.0", "--port", "7860", "--browser_type", "camoufox", "--thread", "2", "--debug"]
