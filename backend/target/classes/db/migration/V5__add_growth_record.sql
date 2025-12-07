-- 身高体重测量记录表
CREATE TABLE IF NOT EXISTS `growth_record` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `baby_id` BIGINT NOT NULL COMMENT '宝宝ID',
    `measure_date` DATE NOT NULL COMMENT '测量日期',
    `height` DECIMAL(5,2) COMMENT '身高（cm）',
    `weight` DECIMAL(5,2) COMMENT '体重（kg）',
    `head_circumference` DECIMAL(5,2) COMMENT '头围（cm）',
    `age_in_months` INT COMMENT '测量时月龄',
    `remark` TEXT COMMENT '备注',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除',
    INDEX `idx_baby_id` (`baby_id`),
    INDEX `idx_measure_date` (`measure_date`),
    INDEX `idx_baby_date` (`baby_id`, `measure_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='身高体重测量记录表';

