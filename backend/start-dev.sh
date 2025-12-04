#!/bin/bash

# 宝宝喂养提醒 - 后端开发环境启动脚本

set -e

echo "🍼 宝宝喂养提醒 - 后端服务启动"
echo "================================"

# 检查Java版本
check_java() {
    if ! command -v java &> /dev/null; then
        echo "❌ Java 未安装"
        echo ""
        echo "请安装 Java 17："
        echo "  brew install openjdk@17"
        echo ""
        echo "然后添加到 ~/.zshrc:"
        echo "  export JAVA_HOME=\$(/usr/libexec/java_home -v 17 2>/dev/null || echo \"/opt/homebrew/opt/openjdk@17\")"
        echo "  export PATH=\"\$JAVA_HOME/bin:\$PATH\""
        exit 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VERSION" -lt 17 ]; then
        echo "❌ Java 版本过低: $JAVA_VERSION (需要 17+)"
        echo "请安装 Java 17: brew install openjdk@17"
        exit 1
    fi
    echo "✅ Java 版本: $(java -version 2>&1 | head -n 1)"
}

# 检查Maven
check_maven() {
    if ! command -v mvn &> /dev/null; then
        echo "❌ Maven 未安装"
        echo "请安装: brew install maven"
        exit 1
    fi
    echo "✅ Maven 版本: $(mvn -v | head -n 1)"
}

# 检查数据库配置
check_database() {
    echo ""
    echo "📊 数据库配置检查..."
    
    # 检查是否使用Docker
    if command -v docker &> /dev/null && docker ps &> /dev/null; then
        echo "发现 Docker，可以使用 docker-compose 启动 MySQL 和 Redis"
        echo ""
        read -p "是否使用 Docker 启动数据库? (y/n): " USE_DOCKER
        if [ "$USE_DOCKER" = "y" ] || [ "$USE_DOCKER" = "Y" ]; then
            echo "启动 MySQL 和 Redis..."
            cd ..
            docker-compose up -d mysql redis
            cd backend
            echo "✅ 数据库容器已启动"
            sleep 5  # 等待数据库启动
            return
        fi
    fi
    
    echo ""
    echo "⚠️ 请确保已配置以下服务:"
    echo "   - MySQL 8.0+ (端口 3306)"
    echo "   - Redis 7.x (端口 6379)"
    echo ""
    echo "数据库配置文件: src/main/resources/application.yml"
}

# 主流程
main() {
    cd "$(dirname "$0")"
    
    check_java
    check_maven
    check_database
    
    echo ""
    echo "🚀 启动后端服务..."
    echo ""
    
    # 使用开发配置启动
    mvn spring-boot:run -Dspring-boot.run.profiles=dev
}

main "$@"
