package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.baby.dto.GrowthRecordDTO;
import com.baby.entity.Baby;
import com.baby.entity.GrowthRecord;
import com.baby.mapper.GrowthRecordMapper;
import com.baby.service.BabyService;
import com.baby.service.GrowthRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;

/**
 * 身高体重测量记录服务实现类
 * 
 * 数据来源：
 * - WHO标准：WHO Child Growth Standards (国际通用)
 * - 中国卫健委2025标准：《婴幼儿营养喂养评估服务指南（试行）》2025年2月发布
 */
@Service
@RequiredArgsConstructor
public class GrowthRecordServiceImpl extends ServiceImpl<GrowthRecordMapper, GrowthRecord> 
        implements GrowthRecordService {
    
    private final BabyService babyService;
    
    // ==================== WHO标准 (0-24月龄) ====================
    // WHO男婴身高标准: [月龄, P3, P15, P50, P85, P97]
    private static final double[][] WHO_HEIGHT_BOYS = {
        {0, 46.1, 47.9, 49.9, 51.8, 53.7},
        {1, 50.8, 52.8, 54.7, 56.7, 58.6},
        {2, 54.4, 56.4, 58.4, 60.4, 62.4},
        {3, 57.3, 59.4, 61.4, 63.5, 65.5},
        {4, 59.7, 61.8, 63.9, 66.0, 68.0},
        {5, 61.7, 63.8, 65.9, 68.0, 70.1},
        {6, 63.3, 65.5, 67.6, 69.8, 71.9},
        {7, 64.8, 67.0, 69.2, 71.3, 73.5},
        {8, 66.2, 68.4, 70.6, 72.8, 75.0},
        {9, 67.5, 69.7, 72.0, 74.2, 76.5},
        {10, 68.7, 71.0, 73.3, 75.6, 77.9},
        {11, 69.9, 72.2, 74.5, 76.9, 79.2},
        {12, 71.0, 73.4, 75.7, 78.1, 80.5},
        {15, 74.1, 76.6, 79.1, 81.7, 84.2},
        {18, 76.9, 79.6, 82.3, 85.0, 87.7},
        {21, 79.4, 82.3, 85.1, 88.0, 90.9},
        {24, 81.7, 84.8, 87.8, 90.9, 93.9}
    };
    
    // WHO女婴身高标准: [月龄, P3, P15, P50, P85, P97]
    private static final double[][] WHO_HEIGHT_GIRLS = {
        {0, 45.4, 47.3, 49.1, 51.0, 52.9},
        {1, 49.8, 51.7, 53.7, 55.6, 57.6},
        {2, 53.0, 55.0, 57.1, 59.1, 61.1},
        {3, 55.6, 57.7, 59.8, 61.9, 64.0},
        {4, 57.8, 59.9, 62.1, 64.3, 66.4},
        {5, 59.6, 61.8, 64.0, 66.2, 68.5},
        {6, 61.2, 63.5, 65.7, 68.0, 70.3},
        {7, 62.7, 65.0, 67.3, 69.6, 71.9},
        {8, 64.0, 66.4, 68.7, 71.1, 73.5},
        {9, 65.3, 67.7, 70.1, 72.6, 75.0},
        {10, 66.5, 69.0, 71.5, 74.0, 76.4},
        {11, 67.7, 70.3, 72.8, 75.3, 77.8},
        {12, 68.9, 71.4, 74.0, 76.6, 79.2},
        {15, 72.0, 74.8, 77.5, 80.2, 83.0},
        {18, 74.9, 77.8, 80.7, 83.6, 86.5},
        {21, 77.5, 80.6, 83.7, 86.7, 89.8},
        {24, 80.0, 83.2, 86.4, 89.6, 92.9}
    };
    
    // WHO男婴体重标准: [月龄, P3, P15, P50, P85, P97]
    private static final double[][] WHO_WEIGHT_BOYS = {
        {0, 2.5, 2.9, 3.3, 3.9, 4.4},
        {1, 3.4, 3.9, 4.5, 5.1, 5.8},
        {2, 4.3, 4.9, 5.6, 6.3, 7.1},
        {3, 5.0, 5.7, 6.4, 7.2, 8.0},
        {4, 5.6, 6.2, 7.0, 7.8, 8.7},
        {5, 6.0, 6.7, 7.5, 8.4, 9.3},
        {6, 6.4, 7.1, 7.9, 8.8, 9.8},
        {7, 6.7, 7.4, 8.3, 9.2, 10.3},
        {8, 6.9, 7.7, 8.6, 9.6, 10.7},
        {9, 7.1, 7.9, 8.9, 9.9, 11.0},
        {10, 7.4, 8.2, 9.2, 10.2, 11.4},
        {11, 7.6, 8.4, 9.4, 10.5, 11.7},
        {12, 7.7, 8.6, 9.6, 10.8, 12.0},
        {15, 8.3, 9.2, 10.3, 11.5, 12.8},
        {18, 8.8, 9.8, 10.9, 12.2, 13.7},
        {21, 9.2, 10.3, 11.5, 12.9, 14.5},
        {24, 9.7, 10.8, 12.2, 13.6, 15.3}
    };
    
    // WHO女婴体重标准: [月龄, P3, P15, P50, P85, P97]
    private static final double[][] WHO_WEIGHT_GIRLS = {
        {0, 2.4, 2.8, 3.2, 3.7, 4.2},
        {1, 3.2, 3.6, 4.2, 4.8, 5.5},
        {2, 3.9, 4.5, 5.1, 5.8, 6.6},
        {3, 4.5, 5.2, 5.8, 6.6, 7.5},
        {4, 5.0, 5.7, 6.4, 7.3, 8.2},
        {5, 5.4, 6.1, 6.9, 7.8, 8.8},
        {6, 5.7, 6.5, 7.3, 8.2, 9.3},
        {7, 6.0, 6.8, 7.6, 8.6, 9.8},
        {8, 6.3, 7.0, 7.9, 9.0, 10.2},
        {9, 6.5, 7.3, 8.2, 9.3, 10.5},
        {10, 6.7, 7.5, 8.5, 9.6, 10.9},
        {11, 6.9, 7.7, 8.7, 9.9, 11.2},
        {12, 7.0, 7.9, 8.9, 10.1, 11.5},
        {15, 7.6, 8.5, 9.6, 10.9, 12.4},
        {18, 8.1, 9.1, 10.2, 11.6, 13.2},
        {21, 8.6, 9.6, 10.9, 12.3, 14.0},
        {24, 9.0, 10.2, 11.5, 13.0, 14.8}
    };
    
    // ==================== 中国卫健委2025标准 (0-36月龄) ====================
    // 数据来源：《婴幼儿营养喂养评估服务指南（试行）》2025年2月
    // 格式：[月龄, -2SD(P3), -1SD(P15), 中位数(P50), +1SD(P85), +2SD(P97)]
    
    // 中国男婴身高标准(0-36月龄)
    private static final double[][] CHINA_2025_HEIGHT_BOYS = {
        {0, 46.1, 48.0, 49.9, 51.8, 53.7},
        {1, 50.8, 52.8, 54.7, 56.7, 58.6},
        {2, 54.4, 56.4, 58.4, 60.4, 62.4},
        {3, 57.3, 59.4, 61.4, 63.5, 65.5},
        {4, 59.7, 61.8, 63.9, 66.0, 68.0},
        {5, 61.7, 63.8, 65.9, 68.0, 70.1},
        {6, 63.3, 65.5, 67.6, 69.8, 71.9},
        {7, 64.8, 67.0, 69.2, 71.3, 73.5},
        {8, 66.2, 68.4, 70.6, 72.8, 75.0},
        {9, 67.5, 69.7, 72.0, 74.2, 76.5},
        {10, 68.7, 71.0, 73.3, 75.6, 77.9},
        {11, 69.9, 72.2, 74.5, 76.9, 79.2},
        {12, 71.0, 73.4, 75.7, 78.1, 80.5},
        {13, 72.1, 74.5, 76.9, 79.3, 81.8},
        {14, 73.1, 75.6, 78.0, 80.5, 83.0},
        {15, 74.1, 76.6, 79.1, 81.7, 84.2},
        {16, 75.0, 77.6, 80.2, 82.8, 85.4},
        {17, 76.0, 78.6, 81.2, 83.9, 86.5},
        {18, 76.9, 79.6, 82.3, 85.0, 87.7},
        {19, 77.7, 80.5, 83.2, 86.0, 88.8},
        {20, 78.6, 81.4, 84.2, 87.0, 89.8},
        {21, 79.4, 82.3, 85.1, 88.0, 90.9},
        {22, 80.2, 83.1, 86.0, 89.0, 91.9},
        {23, 81.0, 83.9, 86.9, 89.9, 92.9},
        {24, 81.0, 84.1, 87.1, 90.2, 93.2},
        {25, 81.7, 84.9, 88.0, 91.1, 94.2},
        {26, 82.5, 85.6, 88.8, 92.0, 95.2},
        {27, 83.1, 86.4, 89.6, 92.9, 96.1},
        {28, 83.8, 87.1, 90.4, 93.7, 97.0},
        {29, 84.5, 87.8, 91.2, 94.5, 97.9},
        {30, 85.1, 88.5, 91.9, 95.3, 98.7},
        {31, 85.7, 89.2, 92.7, 96.1, 99.6},
        {32, 86.4, 89.9, 93.4, 96.9, 100.4},
        {33, 86.9, 90.5, 94.1, 97.6, 101.2},
        {34, 87.5, 91.1, 94.8, 98.4, 102.0},
        {35, 88.1, 91.8, 95.4, 99.1, 102.7},
        {36, 88.7, 92.4, 96.1, 99.8, 103.5}
    };
    
    // 中国女婴身高标准(0-36月龄)
    private static final double[][] CHINA_2025_HEIGHT_GIRLS = {
        {0, 45.4, 47.3, 49.1, 51.0, 52.9},
        {1, 49.8, 51.7, 53.7, 55.6, 57.6},
        {2, 53.0, 55.0, 57.1, 59.1, 61.1},
        {3, 55.6, 57.7, 59.8, 61.9, 64.0},
        {4, 57.8, 59.9, 62.1, 64.3, 66.4},
        {5, 59.6, 61.8, 64.0, 66.2, 68.5},
        {6, 61.2, 63.5, 65.7, 68.0, 70.3},
        {7, 62.7, 65.0, 67.3, 69.6, 71.9},
        {8, 64.0, 66.4, 68.7, 71.1, 73.5},
        {9, 65.3, 67.7, 70.1, 72.6, 75.0},
        {10, 66.5, 69.0, 71.5, 73.9, 76.4},
        {11, 67.7, 70.3, 72.8, 75.3, 77.8},
        {12, 68.9, 71.4, 74.0, 76.6, 79.2},
        {13, 70.0, 72.6, 75.2, 77.8, 80.5},
        {14, 71.0, 73.7, 76.4, 79.1, 81.7},
        {15, 72.0, 74.8, 77.5, 80.2, 83.0},
        {16, 73.0, 75.8, 78.6, 81.4, 84.2},
        {17, 74.0, 76.8, 79.7, 82.5, 85.4},
        {18, 74.9, 77.8, 80.7, 83.6, 86.5},
        {19, 75.8, 78.8, 81.7, 84.7, 87.6},
        {20, 76.7, 79.7, 82.7, 85.7, 88.7},
        {21, 77.5, 80.6, 83.7, 86.7, 89.8},
        {22, 78.4, 81.5, 84.6, 87.7, 90.8},
        {23, 79.2, 82.3, 85.5, 88.7, 91.9},
        {24, 79.3, 82.5, 85.7, 88.9, 92.2},
        {25, 80.0, 83.3, 86.6, 89.9, 93.1},
        {26, 80.8, 84.1, 87.4, 90.8, 94.1},
        {27, 81.5, 84.9, 88.3, 91.7, 95.0},
        {28, 82.2, 85.7, 89.1, 92.5, 96.0},
        {29, 82.9, 86.4, 89.9, 93.4, 96.9},
        {30, 83.6, 87.1, 90.7, 94.2, 97.7},
        {31, 84.3, 87.9, 91.4, 95.0, 98.6},
        {32, 84.9, 88.6, 92.2, 95.8, 99.4},
        {33, 85.6, 89.3, 92.9, 96.6, 100.3},
        {34, 86.2, 89.9, 93.6, 97.4, 101.1},
        {35, 86.8, 90.6, 94.4, 98.1, 101.9},
        {36, 87.4, 91.2, 95.1, 98.9, 102.7}
    };
    
    // 中国男婴体重标准(0-36月龄)
    private static final double[][] CHINA_2025_WEIGHT_BOYS = {
        {0, 2.5, 2.9, 3.3, 3.9, 4.4},
        {1, 3.4, 3.9, 4.5, 5.1, 5.8},
        {2, 4.3, 4.9, 5.6, 6.3, 7.1},
        {3, 5.0, 5.7, 6.4, 7.2, 8.0},
        {4, 5.6, 6.2, 7.0, 7.8, 8.7},
        {5, 6.0, 6.7, 7.5, 8.4, 9.3},
        {6, 6.4, 7.1, 7.9, 8.8, 9.8},
        {7, 6.7, 7.4, 8.3, 9.2, 10.3},
        {8, 6.9, 7.7, 8.6, 9.6, 10.7},
        {9, 7.1, 8.0, 8.9, 9.9, 11.0},
        {10, 7.4, 8.2, 9.2, 10.2, 11.4},
        {11, 7.6, 8.4, 9.4, 10.5, 11.7},
        {12, 7.7, 8.6, 9.6, 10.8, 12.0},
        {13, 7.9, 8.8, 9.9, 11.0, 12.3},
        {14, 8.1, 9.0, 10.1, 11.3, 12.6},
        {15, 8.3, 9.2, 10.3, 11.5, 12.8},
        {16, 8.4, 9.4, 10.5, 11.7, 13.1},
        {17, 8.6, 9.6, 10.7, 12.0, 13.4},
        {18, 8.8, 9.8, 10.9, 12.2, 13.7},
        {19, 8.9, 10.0, 11.1, 12.5, 13.9},
        {20, 9.1, 10.1, 11.3, 12.7, 14.2},
        {21, 9.2, 10.3, 11.5, 12.9, 14.5},
        {22, 9.4, 10.5, 11.8, 13.2, 14.7},
        {23, 9.5, 10.7, 12.0, 13.4, 15.0},
        {24, 9.7, 10.8, 12.2, 13.6, 15.3},
        {25, 9.8, 11.0, 12.4, 13.9, 15.5},
        {26, 10.0, 11.2, 12.5, 14.1, 15.8},
        {27, 10.1, 11.3, 12.7, 14.3, 16.1},
        {28, 10.2, 11.5, 12.9, 14.5, 16.3},
        {29, 10.4, 11.7, 13.1, 14.8, 16.6},
        {30, 10.5, 11.8, 13.3, 15.0, 16.9},
        {31, 10.7, 12.0, 13.5, 15.2, 17.1},
        {32, 10.8, 12.1, 13.7, 15.4, 17.4},
        {33, 10.9, 12.3, 13.8, 15.6, 17.6},
        {34, 11.0, 12.4, 14.0, 15.8, 17.8},
        {35, 11.2, 12.6, 14.2, 16.0, 18.1},
        {36, 11.3, 12.7, 14.3, 16.2, 18.3}
    };
    
    // 中国女婴体重标准(0-36月龄)
    private static final double[][] CHINA_2025_WEIGHT_GIRLS = {
        {0, 2.4, 2.8, 3.2, 3.7, 4.2},
        {1, 3.2, 3.6, 4.2, 4.8, 5.5},
        {2, 3.9, 4.5, 5.1, 5.8, 6.6},
        {3, 4.5, 5.2, 5.8, 6.6, 7.5},
        {4, 5.0, 5.7, 6.4, 7.3, 8.2},
        {5, 5.4, 6.1, 6.9, 7.8, 8.8},
        {6, 5.7, 6.5, 7.3, 8.2, 9.3},
        {7, 6.0, 6.8, 7.6, 8.6, 9.8},
        {8, 6.3, 7.0, 7.9, 9.0, 10.2},
        {9, 6.5, 7.3, 8.2, 9.3, 10.5},
        {10, 6.7, 7.5, 8.5, 9.6, 10.9},
        {11, 6.9, 7.7, 8.7, 9.9, 11.2},
        {12, 7.0, 7.9, 8.9, 10.1, 11.5},
        {13, 7.2, 8.1, 9.2, 10.4, 11.8},
        {14, 7.4, 8.3, 9.4, 10.6, 12.1},
        {15, 7.6, 8.5, 9.6, 10.9, 12.4},
        {16, 7.7, 8.7, 9.8, 11.1, 12.6},
        {17, 7.9, 8.9, 10.0, 11.4, 12.9},
        {18, 8.1, 9.1, 10.2, 11.6, 13.2},
        {19, 8.2, 9.2, 10.4, 11.8, 13.5},
        {20, 8.4, 9.4, 10.6, 12.1, 13.7},
        {21, 8.6, 9.6, 10.9, 12.3, 14.0},
        {22, 8.7, 9.8, 11.1, 12.5, 14.3},
        {23, 8.9, 10.0, 11.3, 12.8, 14.6},
        {24, 9.0, 10.2, 11.5, 13.0, 14.8},
        {25, 9.2, 10.3, 11.7, 13.3, 15.1},
        {26, 9.4, 10.5, 11.9, 13.5, 15.4},
        {27, 9.5, 10.7, 12.1, 13.7, 15.7},
        {28, 9.7, 10.9, 12.3, 14.0, 16.0},
        {29, 9.8, 11.1, 12.5, 14.2, 16.2},
        {30, 10.0, 11.2, 12.7, 14.4, 16.5},
        {31, 10.1, 11.4, 12.9, 14.7, 16.8},
        {32, 10.3, 11.6, 13.1, 14.9, 17.1},
        {33, 10.4, 11.7, 13.3, 15.1, 17.3},
        {34, 10.5, 11.9, 13.5, 15.4, 17.6},
        {35, 10.7, 12.0, 13.7, 15.6, 17.9},
        {36, 10.8, 12.2, 13.9, 15.8, 18.1}
    };
    
    // 中国男婴BMI标准(0-36月龄)
    private static final double[][] CHINA_2025_BMI_BOYS = {
        {0, 11.1, 12.2, 13.4, 14.8, 16.3},
        {1, 12.4, 13.6, 14.9, 16.3, 17.8},
        {2, 13.7, 15.0, 16.3, 17.8, 19.4},
        {3, 14.3, 15.5, 16.9, 18.4, 20.0},
        {4, 14.5, 15.8, 17.2, 18.7, 20.3},
        {5, 14.7, 15.9, 17.3, 18.8, 20.5},
        {6, 14.7, 16.0, 17.3, 18.8, 20.5},
        {7, 14.8, 16.0, 17.3, 18.8, 20.5},
        {8, 14.7, 15.9, 17.3, 18.7, 20.4},
        {9, 14.7, 15.8, 17.2, 18.6, 20.3},
        {10, 14.6, 15.7, 17.0, 18.5, 20.1},
        {11, 14.5, 15.6, 16.9, 18.4, 20.0},
        {12, 14.4, 15.5, 16.8, 18.2, 19.8},
        {13, 14.3, 15.4, 16.7, 18.1, 19.7},
        {14, 14.2, 15.3, 16.6, 18.0, 19.5},
        {15, 14.1, 15.2, 16.4, 17.8, 19.4},
        {16, 14.0, 15.1, 16.3, 17.7, 19.3},
        {17, 13.9, 15.0, 16.2, 17.6, 19.1},
        {18, 13.9, 14.9, 16.1, 17.5, 19.0},
        {19, 13.8, 14.9, 16.1, 17.4, 18.9},
        {20, 13.7, 14.8, 16.0, 17.3, 18.8},
        {21, 13.7, 14.7, 15.9, 17.2, 18.7},
        {22, 13.6, 14.7, 15.8, 17.2, 18.7},
        {23, 13.6, 14.6, 15.8, 17.1, 18.6},
        {24, 13.8, 14.8, 16.0, 17.3, 18.9},
        {25, 13.8, 14.8, 16.0, 17.3, 18.8},
        {26, 13.7, 14.8, 15.9, 17.3, 18.8},
        {27, 13.7, 14.7, 15.9, 17.2, 18.7},
        {28, 13.6, 14.7, 15.9, 17.2, 18.7},
        {29, 13.6, 14.7, 15.8, 17.1, 18.6},
        {30, 13.6, 14.6, 15.8, 17.1, 18.6},
        {31, 13.5, 14.6, 15.8, 17.1, 18.5},
        {32, 13.5, 14.6, 15.7, 17.0, 18.5},
        {33, 13.5, 14.5, 15.7, 17.0, 18.5},
        {34, 13.4, 14.5, 15.7, 17.0, 18.4},
        {35, 13.4, 14.5, 15.6, 16.9, 18.4},
        {36, 13.4, 14.4, 15.6, 16.9, 18.4}
    };
    
    // 中国女婴BMI标准(0-36月龄)
    private static final double[][] CHINA_2025_BMI_GIRLS = {
        {0, 11.1, 12.2, 13.3, 14.6, 16.1},
        {1, 12.0, 13.2, 14.6, 16.0, 17.5},
        {2, 13.0, 14.3, 15.8, 17.3, 19.0},
        {3, 13.6, 14.9, 16.4, 17.9, 19.7},
        {4, 13.9, 15.2, 16.7, 18.3, 20.0},
        {5, 14.1, 15.4, 16.8, 18.4, 20.2},
        {6, 14.1, 15.5, 16.9, 18.5, 20.3},
        {7, 14.2, 15.5, 16.9, 18.5, 20.3},
        {8, 14.1, 15.4, 16.8, 18.4, 20.2},
        {9, 14.1, 15.3, 16.7, 18.3, 20.1},
        {10, 14.0, 15.2, 16.6, 18.2, 19.9},
        {11, 13.9, 15.1, 16.5, 18.0, 19.8},
        {12, 13.8, 15.0, 16.4, 17.9, 19.6},
        {13, 13.7, 14.9, 16.2, 17.7, 19.5},
        {14, 13.6, 14.8, 16.1, 17.6, 19.3},
        {15, 13.5, 14.7, 16.0, 17.5, 19.2},
        {16, 13.5, 14.6, 15.9, 17.4, 19.1},
        {17, 13.4, 14.5, 15.8, 17.3, 18.9},
        {18, 13.3, 14.4, 15.7, 17.2, 18.8},
        {19, 13.3, 14.4, 15.7, 17.1, 18.8},
        {20, 13.2, 14.3, 15.6, 17.0, 18.7},
        {21, 13.2, 14.3, 15.5, 17.0, 18.6},
        {22, 13.1, 14.2, 15.5, 16.9, 18.5},
        {23, 13.1, 14.2, 15.4, 16.9, 18.5},
        {24, 13.3, 14.4, 15.7, 17.1, 18.7},
        {25, 13.3, 14.4, 15.7, 17.1, 18.7},
        {26, 13.3, 14.4, 15.6, 17.0, 18.7},
        {27, 13.3, 14.4, 15.6, 17.0, 18.6},
        {28, 13.3, 14.3, 15.6, 17.0, 18.6},
        {29, 13.2, 14.3, 15.6, 17.0, 18.6},
        {30, 13.2, 14.3, 15.5, 16.9, 18.5},
        {31, 13.2, 14.3, 15.5, 16.9, 18.5},
        {32, 13.2, 14.3, 15.5, 16.9, 18.5},
        {33, 13.1, 14.2, 15.5, 16.9, 18.5},
        {34, 13.1, 14.2, 15.4, 16.8, 18.5},
        {35, 13.1, 14.2, 15.4, 16.8, 18.4},
        {36, 13.1, 14.2, 15.4, 16.8, 18.4}
    };
    
    @Override
    @Transactional
    public GrowthRecord createRecord(GrowthRecordDTO dto) {
        GrowthRecord record = new GrowthRecord();
        record.setBabyId(dto.getBabyId());
        record.setMeasureDate(dto.getMeasureDate());
        record.setHeight(dto.getHeight());
        record.setWeight(dto.getWeight());
        record.setHeadCircumference(dto.getHeadCircumference());
        record.setRemark(dto.getRemark());
        
        // 计算测量时月龄
        Baby baby = babyService.getById(dto.getBabyId());
        if (baby != null && baby.getBirthDate() != null) {
            long months = ChronoUnit.MONTHS.between(baby.getBirthDate(), dto.getMeasureDate());
            record.setAgeInMonths((int) months);
        }
        
        save(record);
        return record;
    }
    
    @Override
    @Transactional
    public GrowthRecord updateRecord(Long id, GrowthRecordDTO dto) {
        GrowthRecord record = getById(id);
        if (record == null) {
            throw new RuntimeException("测量记录不存在");
        }
        
        record.setMeasureDate(dto.getMeasureDate());
        record.setHeight(dto.getHeight());
        record.setWeight(dto.getWeight());
        record.setHeadCircumference(dto.getHeadCircumference());
        record.setRemark(dto.getRemark());
        
        // 重新计算月龄
        Baby baby = babyService.getById(dto.getBabyId());
        if (baby != null && baby.getBirthDate() != null) {
            long months = ChronoUnit.MONTHS.between(baby.getBirthDate(), dto.getMeasureDate());
            record.setAgeInMonths((int) months);
        }
        
        updateById(record);
        return record;
    }
    
    @Override
    public List<GrowthRecord> getAllRecords(Long babyId) {
        return list(new LambdaQueryWrapper<GrowthRecord>()
                .eq(GrowthRecord::getBabyId, babyId)
                .orderByAsc(GrowthRecord::getMeasureDate));
    }
    
    @Override
    public Map<String, List<double[]>> getWHOHeightStandard(int gender) {
        double[][] data = gender == 1 ? WHO_HEIGHT_BOYS : WHO_HEIGHT_GIRLS;
        return convertToPercentileMap(data);
    }
    
    @Override
    public Map<String, List<double[]>> getWHOWeightStandard(int gender) {
        double[][] data = gender == 1 ? WHO_WEIGHT_BOYS : WHO_WEIGHT_GIRLS;
        return convertToPercentileMap(data);
    }
    
    private Map<String, List<double[]>> convertToPercentileMap(double[][] data) {
        Map<String, List<double[]>> result = new LinkedHashMap<>();
        List<double[]> p3 = new ArrayList<>();
        List<double[]> p15 = new ArrayList<>();
        List<double[]> p50 = new ArrayList<>();
        List<double[]> p85 = new ArrayList<>();
        List<double[]> p97 = new ArrayList<>();
        
        for (double[] row : data) {
            double month = row[0];
            p3.add(new double[]{month, row[1]});
            p15.add(new double[]{month, row[2]});
            p50.add(new double[]{month, row[3]});
            p85.add(new double[]{month, row[4]});
            p97.add(new double[]{month, row[5]});
        }
        
        result.put("p3", p3);
        result.put("p15", p15);
        result.put("p50", p50);
        result.put("p85", p85);
        result.put("p97", p97);
        
        return result;
    }
    
    @Override
    public Map<String, Object> calculatePercentile(Long babyId) {
        Map<String, Object> result = new HashMap<>();
        
        Baby baby = babyService.getById(babyId);
        if (baby == null) {
            return result;
        }
        
        // 获取最新记录
        GrowthRecord latest = getOne(new LambdaQueryWrapper<GrowthRecord>()
                .eq(GrowthRecord::getBabyId, babyId)
                .orderByDesc(GrowthRecord::getMeasureDate)
                .last("LIMIT 1"));
        
        if (latest == null) {
            return result;
        }
        
        int gender = baby.getGender() != null ? baby.getGender() : 1;
        int ageInMonths = latest.getAgeInMonths() != null ? latest.getAgeInMonths() : 0;
        
        // 计算身高百分位
        if (latest.getHeight() != null) {
            double heightValue = latest.getHeight().doubleValue();
            String heightPercentile = calculateValuePercentile(heightValue, ageInMonths, 
                    gender == 1 ? WHO_HEIGHT_BOYS : WHO_HEIGHT_GIRLS);
            result.put("heightPercentile", heightPercentile);
            result.put("height", heightValue);
        }
        
        // 计算体重百分位
        if (latest.getWeight() != null) {
            double weightValue = latest.getWeight().doubleValue();
            String weightPercentile = calculateValuePercentile(weightValue, ageInMonths,
                    gender == 1 ? WHO_WEIGHT_BOYS : WHO_WEIGHT_GIRLS);
            result.put("weightPercentile", weightPercentile);
            result.put("weight", weightValue);
        }
        
        result.put("ageInMonths", ageInMonths);
        result.put("measureDate", latest.getMeasureDate());
        
        return result;
    }
    
    private String calculateValuePercentile(double value, int ageInMonths, double[][] standards) {
        // 找到对应月龄的标准值
        double[] standard = null;
        for (double[] row : standards) {
            if ((int) row[0] == ageInMonths) {
                standard = row;
                break;
            }
        }
        
        if (standard == null) {
            // 如果没有精确匹配，找最近的
            for (double[] row : standards) {
                if ((int) row[0] <= ageInMonths) {
                    standard = row;
                } else {
                    break;
                }
            }
        }
        
        if (standard == null) {
            return "未知";
        }
        
        // 判断百分位区间
        if (value < standard[1]) return "<3%";
        if (value < standard[2]) return "3%-15%";
        if (value < standard[3]) return "15%-50%";
        if (value < standard[4]) return "50%-85%";
        if (value < standard[5]) return "85%-97%";
        return ">97%";
    }
    
    // ==================== 多标准支持方法 ====================
    
    @Override
    public Map<String, List<double[]>> getHeightStandard(int gender, String standardType) {
        double[][] data;
        if ("CHINA_2025".equalsIgnoreCase(standardType)) {
            data = gender == 1 ? CHINA_2025_HEIGHT_BOYS : CHINA_2025_HEIGHT_GIRLS;
        } else {
            // 默认WHO标准
            data = gender == 1 ? WHO_HEIGHT_BOYS : WHO_HEIGHT_GIRLS;
        }
        return convertToPercentileMap(data);
    }
    
    @Override
    public Map<String, List<double[]>> getWeightStandard(int gender, String standardType) {
        double[][] data;
        if ("CHINA_2025".equalsIgnoreCase(standardType)) {
            data = gender == 1 ? CHINA_2025_WEIGHT_BOYS : CHINA_2025_WEIGHT_GIRLS;
        } else {
            // 默认WHO标准
            data = gender == 1 ? WHO_WEIGHT_BOYS : WHO_WEIGHT_GIRLS;
        }
        return convertToPercentileMap(data);
    }
    
    @Override
    public Map<String, List<double[]>> getBmiStandard(int gender, String standardType) {
        // BMI目前仅支持中国2025标准
        double[][] data = gender == 1 ? CHINA_2025_BMI_BOYS : CHINA_2025_BMI_GIRLS;
        return convertToPercentileMap(data);
    }
    
    @Override
    public Map<String, Object> calculatePercentile(Long babyId, String standardType) {
        Map<String, Object> result = new HashMap<>();
        
        Baby baby = babyService.getById(babyId);
        if (baby == null) {
            return result;
        }
        
        // 获取最新记录
        GrowthRecord latest = getOne(new LambdaQueryWrapper<GrowthRecord>()
                .eq(GrowthRecord::getBabyId, babyId)
                .orderByDesc(GrowthRecord::getMeasureDate)
                .last("LIMIT 1"));
        
        if (latest == null) {
            return result;
        }
        
        int gender = baby.getGender() != null ? baby.getGender() : 1;
        int ageInMonths = latest.getAgeInMonths() != null ? latest.getAgeInMonths() : 0;
        
        // 根据标准类型选择数据
        double[][] heightData;
        double[][] weightData;
        double[][] bmiData;
        
        if ("CHINA_2025".equalsIgnoreCase(standardType)) {
            heightData = gender == 1 ? CHINA_2025_HEIGHT_BOYS : CHINA_2025_HEIGHT_GIRLS;
            weightData = gender == 1 ? CHINA_2025_WEIGHT_BOYS : CHINA_2025_WEIGHT_GIRLS;
            bmiData = gender == 1 ? CHINA_2025_BMI_BOYS : CHINA_2025_BMI_GIRLS;
        } else {
            heightData = gender == 1 ? WHO_HEIGHT_BOYS : WHO_HEIGHT_GIRLS;
            weightData = gender == 1 ? WHO_WEIGHT_BOYS : WHO_WEIGHT_GIRLS;
            bmiData = gender == 1 ? CHINA_2025_BMI_BOYS : CHINA_2025_BMI_GIRLS; // BMI仅用中国标准
        }
        
        // 计算身高百分位
        if (latest.getHeight() != null) {
            double heightValue = latest.getHeight().doubleValue();
            String heightPercentile = calculateValuePercentile(heightValue, ageInMonths, heightData);
            result.put("heightPercentile", heightPercentile);
            result.put("height", heightValue);
        }
        
        // 计算体重百分位
        if (latest.getWeight() != null) {
            double weightValue = latest.getWeight().doubleValue();
            String weightPercentile = calculateValuePercentile(weightValue, ageInMonths, weightData);
            result.put("weightPercentile", weightPercentile);
            result.put("weight", weightValue);
        }
        
        // 计算BMI百分位
        if (latest.getHeight() != null && latest.getWeight() != null && latest.getHeight().doubleValue() > 0) {
            double heightM = latest.getHeight().doubleValue() / 100.0; // cm转m
            double bmi = latest.getWeight().doubleValue() / (heightM * heightM);
            String bmiPercentile = calculateValuePercentile(bmi, ageInMonths, bmiData);
            result.put("bmiPercentile", bmiPercentile);
            result.put("bmi", Math.round(bmi * 10.0) / 10.0); // 保留1位小数
        }
        
        result.put("ageInMonths", ageInMonths);
        result.put("measureDate", latest.getMeasureDate());
        result.put("standardType", standardType);
        
        return result;
    }
    
    @Override
    public List<Map<String, Object>> getAvailableStandards() {
        List<Map<String, Object>> standards = new ArrayList<>();
        
        // WHO标准
        Map<String, Object> who = new LinkedHashMap<>();
        who.put("code", "WHO");
        who.put("name", "WHO国际标准");
        who.put("description", "世界卫生组织(WHO)儿童生长标准，国际通用");
        who.put("source", "WHO Child Growth Standards");
        who.put("ageRange", "0-24月龄");
        who.put("supportsBmi", false);
        who.put("recommendation", "适用于国际比较或海外生活的宝宝");
        standards.add(who);
        
        // 中国2025标准
        Map<String, Object> china2025 = new LinkedHashMap<>();
        china2025.put("code", "CHINA_2025");
        china2025.put("name", "中国卫健委2025标准");
        china2025.put("description", "国家卫健委2025年发布，基于中国儿童大样本数据，更符合中国宝宝实际");
        china2025.put("source", "《婴幼儿营养喂养评估服务指南（试行）》2025年2月");
        china2025.put("ageRange", "0-36月龄");
        china2025.put("supportsBmi", true);
        china2025.put("recommendation", "推荐中国宝宝使用，数据更新、覆盖月龄更广、支持BMI");
        standards.add(china2025);
        
        return standards;
    }
}
