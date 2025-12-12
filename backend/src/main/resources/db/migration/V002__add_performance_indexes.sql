-- ====================================
-- 数据库索引优化方案
-- 适用于1万用户规模性能优化
-- ====================================

USE baby_feeding;

-- 1. 喂养记录表优化索引
-- 已有索引：idx_baby_id, idx_start_time, idx_baby_start
-- 新增复合索引用于统计查询（已按时间范围过滤）
CREATE INDEX IF NOT EXISTS idx_feeding_baby_time_deleted 
ON feeding_record(baby_id, start_time, deleted);

-- 用于按喂养类型统计
CREATE INDEX IF NOT EXISTS idx_feeding_type_baby 
ON feeding_record(feeding_type, baby_id, deleted);

-- 2. 睡眠记录表优化索引
-- 已有索引：idx_baby_id, idx_start_time, idx_baby_start
-- 新增复合索引用于睡眠类型统计
CREATE INDEX IF NOT EXISTS idx_sleep_baby_type_time 
ON sleep_record(baby_id, sleep_type, start_time, deleted);

-- 用于时间范围查询（覆盖start_time和end_time）
CREATE INDEX IF NOT EXISTS idx_sleep_time_range 
ON sleep_record(baby_id, start_time, end_time, deleted);

-- 3. 换尿布记录表优化索引
-- 已有索引：idx_baby_id, idx_record_time, idx_baby_time
-- 新增复合索引用于类型统计
CREATE INDEX IF NOT EXISTS idx_excretion_baby_type_time 
ON excretion_record(baby_id, excretion_type, record_time, deleted);

-- 用于异常记录查询
CREATE INDEX IF NOT EXISTS idx_excretion_abnormal 
ON excretion_record(baby_id, has_abnormal, record_time, deleted);

-- 4. 提醒任务表优化索引
-- 已有索引：idx_user_id, idx_scheduled_time, idx_status, idx_user_status
-- 新增复合索引用于定时任务扫描（按状态和时间）
CREATE INDEX IF NOT EXISTS idx_reminder_status_time 
ON reminder(status, scheduled_time, deleted);

-- 用于按宝宝ID查询待发送提醒
CREATE INDEX IF NOT EXISTS idx_reminder_baby_status 
ON reminder(baby_id, status, scheduled_time, deleted);

-- 5. 生长记录表优化索引
-- 新增复合索引用于时间序列查询
CREATE INDEX IF NOT EXISTS idx_growth_baby_date 
ON growth_record(baby_id, measure_date, deleted);

-- 6. 疫苗接种记录表优化索引
-- 已有索引：idx_baby_id, idx_vaccine_code, idx_scheduled_date, idx_status
-- 新增复合索引用于状态和日期联合查询
CREATE INDEX IF NOT EXISTS idx_vaccination_status_date 
ON vaccination_record(baby_id, status, scheduled_date, deleted);

-- 7. 用户表优化（如果用户量增长）
-- 已有索引：idx_phone, idx_apple_id, idx_wechat_open_id
-- 新增索引用于设备推送查询
CREATE INDEX IF NOT EXISTS idx_user_device_token 
ON user(device_token, deleted) 
WHERE device_token IS NOT NULL;

-- ====================================
-- 查看索引创建情况
-- ====================================
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX
FROM 
    INFORMATION_SCHEMA.STATISTICS
WHERE 
    TABLE_SCHEMA = 'baby_feeding'
    AND INDEX_NAME NOT IN ('PRIMARY')
ORDER BY 
    TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX;

-- ====================================
-- 分析表统计信息（优化查询计划）
-- ====================================
ANALYZE TABLE feeding_record;
ANALYZE TABLE sleep_record;
ANALYZE TABLE excretion_record;
ANALYZE TABLE reminder;
ANALYZE TABLE growth_record;
ANALYZE TABLE vaccination_record;

-- ====================================
-- 慢查询监控建议
-- ====================================
-- 在my.cnf中添加以下配置：
-- slow_query_log = 1
-- long_query_time = 2
-- slow_query_log_file = /var/log/mysql/slow.log
