-- 换尿布记录表
CREATE TABLE IF NOT EXISTS `excretion_record` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `baby_id` BIGINT NOT NULL COMMENT '宝宝ID',
    `excretion_type` TINYINT NOT NULL COMMENT '排泄类型: 1-大便 2-小便',
    `record_time` DATETIME NOT NULL COMMENT '记录时间',
    `color` VARCHAR(20) COMMENT '颜色（大便）: 黄色、绿色、棕色、黑色等',
    `texture` VARCHAR(20) COMMENT '性状（大便）: 稀、软、硬、颗粒状等',
    `amount` VARCHAR(20) COMMENT '量: 少量、适中、大量',
    `has_abnormal` TINYINT DEFAULT 0 COMMENT '是否异常: 0-否 1-是',
    `remark` TEXT COMMENT '备注',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除',
    INDEX `idx_baby_id` (`baby_id`),
    INDEX `idx_record_time` (`record_time`),
    INDEX `idx_baby_time` (`baby_id`, `record_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='换尿布记录表';

