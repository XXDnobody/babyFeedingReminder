-- 疫苗接种记录表增加替代疫苗相关字段
ALTER TABLE `vaccination_record` 
ADD COLUMN `is_free` TINYINT DEFAULT 1 COMMENT '是否免费: 1-国家免费 0-自费' AFTER `status`,
ADD COLUMN `original_vaccine_code` VARCHAR(50) COMMENT '原始疫苗代码（如果选择了替代疫苗）' AFTER `is_free`,
ADD COLUMN `price` DECIMAL(10,2) COMMENT '疫苗价格（元）' AFTER `original_vaccine_code`;
