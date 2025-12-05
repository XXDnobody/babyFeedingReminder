package com.baby.controller;

import com.baby.common.Result;
import com.baby.dto.LoginRequest;
import com.baby.dto.LoginResponse;
import com.baby.dto.SmsCodeRequest;
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
    
    @Operation(summary = "手机号密码登录")
    @PostMapping("/phone/login")
    public Result<LoginResponse> phoneLogin(@RequestBody LoginRequest request) {
        if (request.getPhone() == null || request.getPhone().isEmpty()) {
            return Result.error(400, "手机号不能为空");
        }
        if (request.getPassword() == null || request.getPassword().isEmpty()) {
            return Result.error(400, "密码不能为空");
        }
        if (request.getAgreedTerms() == null || !request.getAgreedTerms()) {
            return Result.error(400, "请先同意用户服务协议和隐私政策");
        }
        
        try {
            LoginResponse response = authService.loginWithPhone(request);
            log.info("手机号登录成功: userId={}", response.getUserId());
            return Result.success(response);
        } catch (Exception e) {
            log.error("手机号登录失败: {}", e.getMessage());
            return Result.error(500, e.getMessage());
        }
    }
    
    @Operation(summary = "手机号注册")
    @PostMapping("/phone/register")
    public Result<LoginResponse> phoneRegister(@RequestBody LoginRequest request) {
        if (request.getPhone() == null || request.getPhone().isEmpty()) {
            return Result.error(400, "手机号不能为空");
        }
        if (request.getPassword() == null || request.getPassword().length() < 6) {
            return Result.error(400, "密码不能少于6位");
        }
        if (request.getSmsCode() == null || request.getSmsCode().isEmpty()) {
            return Result.error(400, "验证码不能为空");
        }
        if (request.getAgreedTerms() == null || !request.getAgreedTerms()) {
            return Result.error(400, "请先同意用户服务协议和隐私政策");
        }
        
        try {
            LoginResponse response = authService.registerWithPhone(request);
            log.info("手机号注册成功: userId={}", response.getUserId());
            return Result.success(response);
        } catch (Exception e) {
            log.error("手机号注册失败: {}", e.getMessage());
            return Result.error(500, e.getMessage());
        }
    }
    
    @Operation(summary = "发送短信验证码")
    @PostMapping("/sms/send")
    public Result<Void> sendSmsCode(@RequestBody SmsCodeRequest request) {
        if (request.getPhone() == null || request.getPhone().isEmpty()) {
            return Result.error(400, "手机号不能为空");
        }
        if (request.getScene() == null || request.getScene().isEmpty()) {
            return Result.error(400, "场景类型不能为空");
        }
        
        try {
            authService.sendSmsCode(request.getPhone(), request.getScene());
            log.info("发送验证码成功: phone={}, scene={}", request.getPhone(), request.getScene());
            return Result.success();
        } catch (Exception e) {
            log.error("发送验证码失败: {}", e.getMessage());
            return Result.error(500, e.getMessage());
        }
    }
    
    @Operation(summary = "重置密码")
    @PostMapping("/phone/reset-password")
    public Result<Void> resetPassword(@RequestBody LoginRequest request) {
        if (request.getPhone() == null || request.getPhone().isEmpty()) {
            return Result.error(400, "手机号不能为空");
        }
        if (request.getSmsCode() == null || request.getSmsCode().isEmpty()) {
            return Result.error(400, "验证码不能为空");
        }
        if (request.getNewPassword() == null || request.getNewPassword().length() < 6) {
            return Result.error(400, "新密码不能少于6位");
        }
        
        try {
            authService.resetPassword(request);
            log.info("重置密码成功: phone={}", request.getPhone());
            return Result.success();
        } catch (Exception e) {
            log.error("重置密码失败: {}", e.getMessage());
            return Result.error(500, e.getMessage());
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
