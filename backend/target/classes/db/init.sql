-- 创建数据库
CREATE DATABASE IF NOT EXISTS baby_feeding DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE baby_feeding;

-- 用户表
CREATE TABLE IF NOT EXISTS `user` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) UNIQUE COMMENT '用户名',
    `password` VARCHAR(255) COMMENT '密码（加密存储）',
    `phone` VARCHAR(20) COMMENT '手机号',
    `email` VARCHAR(100) COMMENT '邮箱',
    `nickname` VARCHAR(50) COMMENT '昵称',
    `avatar_url` VARCHAR(500) COMMENT '头像URL',
    `apple_id` VARCHAR(100) COMMENT 'Apple登录标识',
    `wechat_open_id` VARCHAR(100) COMMENT '微信OpenID',
    `wechat_union_id` VARCHAR(100) COMMENT '微信UnionID',
    `device_token` VARCHAR(255) COMMENT '设备Token（用于推送）',
    `agreed_terms` TINYINT DEFAULT 0 COMMENT '是否同意用户协议: 0-否 1-是',
    `status` TINYINT DEFAULT 1 COMMENT '账号状态: 0-禁用 1-正常',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除',
    INDEX `idx_phone` (`phone`),
    INDEX `idx_apple_id` (`apple_id`),
    INDEX `idx_wechat_open_id` (`wechat_open_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 宝宝信息表
CREATE TABLE IF NOT EXISTS `baby` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT NOT NULL COMMENT '关联用户ID',
    `nickname` VARCHAR(50) NOT NULL COMMENT '宝宝昵称',
    `birth_date` DATE NOT NULL COMMENT '出生日期',
    `gender` TINYINT COMMENT '性别: 0-女 1-男',
    `gestational_age` INT COMMENT '出生胎龄（周）',
    `height` DECIMAL(5,2) COMMENT '身高（cm）',
    `weight` DECIMAL(5,2) COMMENT '体重（kg）',
    `head_circumference` DECIMAL(5,2) COMMENT '头围（cm）',
    `avatar_url` VARCHAR(500) COMMENT '头像URL',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除',
    INDEX `idx_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='宝宝信息表';

-- 喂养记录表
CREATE TABLE IF NOT EXISTS `feeding_record` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `baby_id` BIGINT NOT NULL COMMENT '宝宝ID',
    `feeding_type` TINYINT NOT NULL COMMENT '喂养类型: 1-母乳 2-奶粉 3-混合喂养',
    `milk_source` TINYINT COMMENT '母乳来源: 1-亲喂 2-瓶装母乳（冷藏）3-瓶装母乳（冷冻）',
    `start_time` DATETIME NOT NULL COMMENT '开始时间',
    `end_time` DATETIME COMMENT '结束时间',
    `amount` INT COMMENT '奶量（毫升）',
    `duration` INT COMMENT '喂养时长（分钟）',
    `next_feeding_time` DATETIME COMMENT '下次喂奶预计时间',
    `need_thaw` TINYINT DEFAULT 0 COMMENT '是否需要提前解冻: 0-否 1-是',
    `thaw_reminder_minutes` INT COMMENT '解冻提醒时间（提前多少分钟）',
    `remark` TEXT COMMENT '备注',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除',
    INDEX `idx_baby_id` (`baby_id`),
    INDEX `idx_start_time` (`start_time`),
    INDEX `idx_baby_start` (`baby_id`, `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='喂养记录表';

-- 睡眠记录表
CREATE TABLE IF NOT EXISTS `sleep_record` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `baby_id` BIGINT NOT NULL COMMENT '宝宝ID',
    `sleep_type` TINYINT NOT NULL COMMENT '睡眠类型: 1-小睡 2-夜间睡眠',
    `start_time` DATETIME NOT NULL COMMENT '开始时间（入睡时间）',
    `end_time` DATETIME COMMENT '结束时间（醒来时间）',
    `duration` INT COMMENT '实际睡眠时长（分钟）',
    `planned_duration` INT COMMENT '计划睡眠时长（分钟）',
    `next_nap_time` DATETIME COMMENT '下次小睡预计时间',
    `soothing_reminder_minutes` INT COMMENT '哄睡提醒时间（提前多少分钟）',
    `quality` TINYINT COMMENT '睡眠质量: 1-好 2-一般 3-差',
    `remark` TEXT COMMENT '备注',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除',
    INDEX `idx_baby_id` (`baby_id`),
    INDEX `idx_start_time` (`start_time`),
    INDEX `idx_baby_start` (`baby_id`, `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='睡眠记录表';

-- 喂养设置表
CREATE TABLE IF NOT EXISTS `feeding_setting` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `baby_id` BIGINT NOT NULL UNIQUE COMMENT '宝宝ID',
    `default_feeding_type` TINYINT DEFAULT 1 COMMENT '默认喂养类型: 1-母乳 2-奶粉 3-混合喂养',
    `default_amount` INT DEFAULT 120 COMMENT '默认奶量（毫升）',
    `default_duration` INT DEFAULT 20 COMMENT '默认喂养时长（分钟）',
    `default_interval` INT DEFAULT 180 COMMENT '默认喂养间隔（分钟）',
    `reminder_start_time` TIME DEFAULT '06:00:00' COMMENT '提醒时段开始时间',
    `reminder_end_time` TIME DEFAULT '22:00:00' COMMENT '提醒时段结束时间',
    `reminder_enabled` TINYINT DEFAULT 1 COMMENT '是否启用提醒: 0-否 1-是',
    `refrigerated_thaw_minutes` INT DEFAULT 15 COMMENT '冷藏母乳解冻提前时间（分钟）',
    `frozen_thaw_minutes` INT DEFAULT 30 COMMENT '冷冻母乳解冻提前时间（分钟）',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='喂养设置表';

-- 睡眠设置表
CREATE TABLE IF NOT EXISTS `sleep_setting` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `baby_id` BIGINT NOT NULL UNIQUE COMMENT '宝宝ID',
    `default_nap_interval` INT DEFAULT 120 COMMENT '默认小睡间隔（分钟）',
    `default_nap_duration` INT DEFAULT 90 COMMENT '默认小睡时长（分钟）',
    `default_soothing_reminder_minutes` INT DEFAULT 15 COMMENT '默认哄睡提前提醒时间（分钟）',
    `reminder_start_time` TIME DEFAULT '06:00:00' COMMENT '提醒时段开始时间',
    `reminder_end_time` TIME DEFAULT '20:00:00' COMMENT '提醒时段结束时间',
    `reminder_enabled` TINYINT DEFAULT 1 COMMENT '是否启用提醒: 0-否 1-是',
    `bedtime_target` TIME DEFAULT '20:00:00' COMMENT '晚间入睡目标时间',
    `wake_time_target` TIME DEFAULT '07:00:00' COMMENT '早晨起床目标时间',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='睡眠设置表';

-- 提醒任务表
CREATE TABLE IF NOT EXISTS `reminder` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `baby_id` BIGINT NOT NULL COMMENT '宝宝ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `reminder_type` TINYINT NOT NULL COMMENT '提醒类型: 1-喂奶提醒 2-解冻提醒 3-小睡提醒 4-哄睡提醒',
    `title` VARCHAR(100) NOT NULL COMMENT '提醒标题',
    `content` VARCHAR(500) NOT NULL COMMENT '提醒内容',
    `scheduled_time` DATETIME NOT NULL COMMENT '预定提醒时间',
    `sent` TINYINT DEFAULT 0 COMMENT '是否已发送: 0-否 1-是',
    `sent_time` DATETIME COMMENT '发送时间',
    `related_record_id` BIGINT COMMENT '关联记录ID（喂养记录或睡眠记录ID）',
    `status` TINYINT DEFAULT 0 COMMENT '状态: 0-待发送 1-已发送 2-已取消',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除',
    INDEX `idx_user_id` (`user_id`),
    INDEX `idx_scheduled_time` (`scheduled_time`),
    INDEX `idx_status` (`status`),
    INDEX `idx_user_status` (`user_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='提醒任务表';

-- 插入测试用户
INSERT INTO `user` (`username`, `password`, `phone`, `nickname`, `status`) 
VALUES ('test', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBpwTTyU3VxqW.', '13800138000', '测试用户', 1);

