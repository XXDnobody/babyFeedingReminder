-- 添加下次小睡提醒开关字段
ALTER TABLE `sleep_setting` 
ADD COLUMN `next_nap_reminder_enabled` TINYINT DEFAULT 1 COMMENT '是否启用下次小睡提醒: 0-否 1-是' 
AFTER `reminder_enabled`;
