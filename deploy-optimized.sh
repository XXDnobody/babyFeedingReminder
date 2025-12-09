#!/bin/bash

# ====================================
# 性能优化部署脚本
# ====================================

echo "🚀 开始部署优化后的系统..."

# 1. 停止现有容器
echo "📦 停止现有容器..."
docker-compose down

# 2. 清理旧的构建缓存（可选）
echo "🧹 清理Docker缓存..."
docker system prune -f

# 3. 重新构建并启动服务
echo "🔨 重新构建服务..."
docker-compose build --no-cache backend

echo "▶️  启动所有服务..."
docker-compose up -d

# 4. 等待MySQL就绪
echo "⏳ 等待MySQL就绪..."
sleep 15

# 5. 执行数据库索引优化
echo "🔧 执行数据库索引优化..."
docker exec -i baby-feeding-mysql mysql -uroot -p${MYSQL_ROOT_PASSWORD:-root123} baby_feeding < backend/src/main/resources/db/migration/V002__add_performance_indexes.sql

# 6. 查看服务状态
echo "📊 服务状态："
docker-compose ps

# 7. 查看资源使用情况
echo ""
echo "💻 容器资源使用情况："
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" baby-feeding-backend baby-feeding-mysql baby-feeding-redis

echo ""
echo "✅ 部署完成！"
echo ""
echo "🔍 性能优化要点："
echo "  ✓ Redis缓存已启用（5分钟-24小时分级缓存）"
echo "  ✓ 数据库索引已优化（11个新增复合索引）"
echo "  ✓ Docker资源限制已配置（2核4G优化分配）"
echo ""
echo "📈 监控命令："
echo "  docker logs -f baby-feeding-backend     # 查看后端日志"
echo "  docker stats                            # 实时资源监控"
echo "  docker exec -it baby-feeding-redis redis-cli INFO stats  # Redis统计"
echo ""
