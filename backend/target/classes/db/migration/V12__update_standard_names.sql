-- 更新生长标准类型名称

-- 更新 CHINA_2025 标准名称
UPDATE `growth_standard_type` 
SET `name` = '卫健委2025喂养评估指南(0-3岁)',
    `description` = '国家卫健委《婴幼儿营养喂养评估服务指南（试行）》2025年2月发布，基于中国儿童数据，覆盖0-36月龄',
    `source` = '国家卫健委《婴幼儿营养喂养评估服务指南（试行）》2025年2月'
WHERE `code` = 'CHINA_2025';

-- 更新 WS_T_423_2022 标准名称
UPDATE `growth_standard_type` 
SET `name` = '卫健委2022儿童生长标准(0-7岁)',
    `description` = '国家卫健委发布的《7岁以下儿童生长标准》WS/T 423-2022，覆盖0-84月龄',
    `source` = '国家卫健委 WS/T 423-2022《7岁以下儿童生长标准》'
WHERE `code` = 'WS_T_423_2022';
