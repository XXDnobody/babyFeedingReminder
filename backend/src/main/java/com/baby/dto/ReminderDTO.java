package com.baby.dto;

import lombok.Data;
import java.time.LocalDateTime;

/**
 * 提醒DTO
 */
@Data
public class ReminderDTO {
    private Long babyId;
    private Long userId;
    private Integer reminderType;  // 1-喂奶 2-解冻 3-小睡 4-哄睡 5-自定义
    private String title;
    private String content;
    private LocalDateTime scheduledTime;
}
