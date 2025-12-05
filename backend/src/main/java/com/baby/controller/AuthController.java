package com.baby.controller;

import com.baby.common.Result;
import com.baby.dto.LoginRequest;
import com.baby.dto.LoginResponse;
import com.baby.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

/**
 * 认证控制器
 */
@Slf4j
@Tag(name = "用户认证")
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final AuthService authService;
    
    @Operation(summary = "Apple登录")
    @PostMapping("/apple")
    public Result<LoginResponse> appleLogin(@RequestBody LoginRequest request) {
        if (request.getIdentityToken() == null || request.getIdentityToken().isEmpty()) {
            return Result.error(400, "identityToken不能为空");
        }
        if (request.getAgreedTerms() == null || !request.getAgreedTerms()) {
            return Result.error(400, "请先同意用户服务协议和隐私政策");
        }
        
        try {
            LoginResponse response = authService.loginWithApple(request);
            log.info("Apple登录成功: userId={}", response.getUserId());
            return Result.success(response);
        } catch (Exception e) {
            log.error("Apple登录失败: {}", e.getMessage());
            return Result.error(500, "登录失败: " + e.getMessage());
        }
    }
    
    @Operation(summary = "微信登录")
    @PostMapping("/wechat")
    public Result<LoginResponse> wechatLogin(@RequestBody LoginRequest request) {
        if (request.getCode() == null || request.getCode().isEmpty()) {
            return Result.error(400, "微信授权code不能为空");
        }
        if (request.getAgreedTerms() == null || !request.getAgreedTerms()) {
            return Result.error(400, "请先同意用户服务协议和隐私政策");
        }
        
        try {
            LoginResponse response = authService.loginWithWechat(request);
            log.info("微信登录成功: userId={}", response.getUserId());
            return Result.success(response);
        } catch (Exception e) {
            log.error("微信登录失败: {}", e.getMessage());
            return Result.error(500, "登录失败: " + e.getMessage());
        }
    }
    
    @Operation(summary = "刷新Token")
    @PostMapping("/refresh")
    public Result<LoginResponse> refreshToken(@RequestHeader("Authorization") String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return Result.error(401, "无效的Token");
        }
        
        String token = authorization.substring(7);
        try {
            LoginResponse response = authService.refreshToken(token);
            return Result.success(response);
        } catch (Exception e) {
            log.error("刷新Token失败: {}", e.getMessage());
            return Result.error(401, "Token已过期，请重新登录");
        }
    }
    
    @Operation(summary = "退出登录")
    @PostMapping("/logout")
    public Result<Void> logout(@RequestHeader(value = "userId", defaultValue = "1") Long userId) {
        authService.logout(userId);
        log.info("用户 {} 退出登录", userId);
        return Result.success();
    }
    
    @Operation(summary = "检查登录状态")
    @GetMapping("/check")
    public Result<Boolean> checkLoginStatus(@RequestHeader("Authorization") String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return Result.success(false);
        }
        
        String token = authorization.substring(7);
        boolean valid = authService.validateToken(token);
        return Result.success(valid);
    }
}
