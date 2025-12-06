-- 将喂养设置表中的时间字段从 TIME 改为 VARCHAR
ALTER TABLE feeding_setting
MODIFY COLUMN reminder_start_time VARCHAR(10) DEFAULT '06:00:00' COMMENT '提醒时段开始时间',
MODIFY COLUMN reminder_end_time VARCHAR(10) DEFAULT '22:00:00' COMMENT '提醒时段结束时间';