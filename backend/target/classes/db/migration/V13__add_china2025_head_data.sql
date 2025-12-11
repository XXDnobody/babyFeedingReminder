-- 为卫健委2025喂养评估指南标准添加头围数据（0-36月龄）
-- 复用WS/T 423-2022的头围数据（数据来源相同）

SET @china2025_id = (SELECT id FROM `growth_standard_type` WHERE `code` = 'CHINA_2025');
SET @wst423_id = (SELECT id FROM `growth_standard_type` WHERE `code` = 'WS_T_423_2022');

-- 复制男童头围数据（0-36月）
INSERT INTO `growth_standard_data` (`standard_type_id`, `gender`, `indicator`, `age_months`, `p3`, `p10`, `p25`, `p50`, `p75`, `p90`, `p97`)
SELECT @china2025_id, `gender`, `indicator`, `age_months`, `p3`, `p10`, `p25`, `p50`, `p75`, `p90`, `p97`
FROM `growth_standard_data`
WHERE `standard_type_id` = @wst423_id
  AND `indicator` = 'HEAD'
  AND `gender` = 1
  AND `age_months` <= 36;

-- 复制女童头围数据（0-36月）
INSERT INTO `growth_standard_data` (`standard_type_id`, `gender`, `indicator`, `age_months`, `p3`, `p10`, `p25`, `p50`, `p75`, `p90`, `p97`)
SELECT @china2025_id, `gender`, `indicator`, `age_months`, `p3`, `p10`, `p25`, `p50`, `p75`, `p90`, `p97`
FROM `growth_standard_data`
WHERE `standard_type_id` = @wst423_id
  AND `indicator` = 'HEAD'
  AND `gender` = 0
  AND `age_months` <= 36;

-- 更新CHINA_2025标准类型，标记支持头围
UPDATE `growth_standard_type` 
SET `supports_head_circumference` = 1,
    `description` = '国家卫健委2025年发布，基于中国儿童数据，覆盖0-36月龄，支持BMI和头围'
WHERE `code` = 'CHINA_2025';
