package com.baby.controller;

import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baby.common.Result;
import com.baby.entity.User;
import com.baby.mapper.UserMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 用户管理控制器
 */
@Slf4j
@Tag(name = "用户管理")
@RestController
@RequestMapping("/user")
@RequiredArgsConstructor
public class UserController {
    
    private final UserMapper userMapper;
    
    @Operation(summary = "更新设备Token")
    @PostMapping("/device-token")
    public Result<Void> updateDeviceToken(@RequestHeader(value = "userId", defaultValue = "1") Long userId,
                                          @RequestBody Map<String, String> request) {
        String deviceToken = request.get("deviceToken");
        if (deviceToken == null || deviceToken.isEmpty()) {
            return Result.error(400, "设备Token不能为空");
        }
        
        User user = userMapper.selectById(userId);
        if (user == null) {
            return Result.error(404, "用户不存在");
        }
        
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, userId)
                .set(User::getDeviceToken, deviceToken));
        
        log.info("用户 {} 更新设备Token成功", userId);
        return Result.success();
    }
    
    @Operation(summary = "获取当前用户信息")
    @GetMapping("/info")
    public Result<User> getUserInfo(@RequestHeader(value = "userId", defaultValue = "1") Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            return Result.error(404, "用户不存在");
        }
        // 脱敏处理
        user.setPassword(null);
        return Result.success(user);
    }
    
    @Operation(summary = "删除设备Token（退出登录时调用）")
    @DeleteMapping("/device-token")
    public Result<Void> deleteDeviceToken(@RequestHeader(value = "userId", defaultValue = "1") Long userId) {
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, userId)
                .set(User::getDeviceToken, null));
        
        log.info("用户 {} 删除设备Token成功", userId);
        return Result.success();
    }
}
