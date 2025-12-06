-- 添加默认下一顿奶源字段
ALTER TABLE `feeding_setting` 
ADD COLUMN `default_next_milk_source` TINYINT DEFAULT 0 COMMENT '默认下一顿奶源: 0-不提醒 1-亲喂/现冲 2-冷藏母乳 3-冷冻母乳'
AFTER `frozen_thaw_minutes`;
