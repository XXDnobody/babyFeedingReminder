-- 疫苗接种记录表
CREATE TABLE IF NOT EXISTS `vaccination_record` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `baby_id` BIGINT NOT NULL COMMENT '宝宝ID',
    `vaccine_code` VARCHAR(50) NOT NULL COMMENT '疫苗代码',
    `vaccine_name` VARCHAR(100) NOT NULL COMMENT '疫苗名称',
    `dose_number` INT NOT NULL COMMENT '剂次',
    `scheduled_date` DATE COMMENT '计划接种日期',
    `actual_date` DATE COMMENT '实际接种日期',
    `status` TINYINT DEFAULT 0 COMMENT '状态: 0-待接种 1-已接种 2-已逾期 3-已跳过',
    `vaccination_site` VARCHAR(200) COMMENT '接种地点',
    `batch_number` VARCHAR(100) COMMENT '疫苗批号',
    `reaction` VARCHAR(500) COMMENT '接种后反应',
    `remark` TEXT COMMENT '备注',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP,
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted` TINYINT DEFAULT 0 COMMENT '逻辑删除: 0-未删除 1-已删除',
    INDEX `idx_baby_id` (`baby_id`),
    INDEX `idx_vaccine_code` (`vaccine_code`),
    INDEX `idx_scheduled_date` (`scheduled_date`),
    INDEX `idx_status` (`status`),
    UNIQUE KEY `uk_baby_vaccine_dose` (`baby_id`, `vaccine_code`, `dose_number`, `deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='疫苗接种记录表';

