package com.baby.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baby.dto.LoginRequest;
import com.baby.dto.LoginResponse;
import com.baby.entity.User;
import com.baby.mapper.UserMapper;
import com.baby.service.AuthService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Objects;
import java.util.Date;

/**
 * 认证服务实现类
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {
    
    private final UserMapper userMapper;
    private final ObjectMapper objectMapper;
    
    @Value("${jwt.secret}")
    private String jwtSecret;
    
    @Value("${jwt.expiration}")
    private Long jwtExpiration;
    
    @Value("${wechat.appid:}")
    private String wechatAppId;
    
    @Value("${wechat.secret:}")
    private String wechatSecret;
    
    private static final long REFRESH_TOKEN_EXPIRATION = 30L * 24 * 60 * 60 * 1000; // 30天
    
    @Override
    @Transactional
    public LoginResponse loginWithApple(LoginRequest request) {
        // 解析Apple identityToken获取用户信息
        String appleUserId = parseAppleIdentityToken(request.getIdentityToken());
        
        if (appleUserId == null && request.getAppleUserId() != null) {
            appleUserId = request.getAppleUserId();
        }
        
        if (appleUserId == null) {
            throw new RuntimeException("无法解析Apple用户标识");
        }
        
        // 查找或创建用户
        User user = userMapper.selectOne(new LambdaQueryWrapper<User>()
                .eq(User::getAppleId, appleUserId));
        
        boolean isNewUser = false;
        if (user == null) {
            // 创建新用户
            user = new User();
            user.setAppleId(appleUserId);
            user.setNickname(request.getNickname() != null ? request.getNickname() : "Apple用户");
            user.setAvatarUrl(request.getAvatarUrl());
            user.setStatus(1);
            user.setAgreedTerms(1);
            userMapper.insert(user);
            isNewUser = true;
            log.info("创建新Apple用户: userId={}, appleId={}", user.getId(), appleUserId);
        } else {
            // 更新协议同意状态
            if (user.getAgreedTerms() == null || user.getAgreedTerms() == 0) {
                userMapper.update(null, new LambdaUpdateWrapper<User>()
                        .eq(User::getId, user.getId())
                        .set(User::getAgreedTerms, 1));
            }
        }
        
        // 更新设备Token
        if (request.getDeviceToken() != null) {
            userMapper.update(null, new LambdaUpdateWrapper<User>()
                    .eq(User::getId, user.getId())
                    .set(User::getDeviceToken, request.getDeviceToken()));
        }
        
        // 生成JWT Token
        String accessToken = generateToken(user.getId(), jwtExpiration);
        String refreshToken = generateToken(user.getId(), REFRESH_TOKEN_EXPIRATION);
        
        return LoginResponse.builder()
                .userId(user.getId())
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(jwtExpiration / 1000)
                .nickname(user.getNickname())
                .avatarUrl(user.getAvatarUrl())
                .isNewUser(isNewUser)
                .build();
    }
    
    @Override
    @Transactional
    public LoginResponse loginWithWechat(LoginRequest request) {
        // 使用code换取access_token和openid
        String accessTokenUrl = String.format(
                "https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code",
                wechatAppId, wechatSecret, request.getCode());
        
        RestTemplate restTemplate = new RestTemplate();
        String openId;
        String unionId = null;
        String nickname = request.getNickname();
        String avatarUrl = request.getAvatarUrl();
        
        try {
            ResponseEntity<String> response = restTemplate.getForEntity(
                    Objects.requireNonNull(accessTokenUrl), String.class);
            JsonNode jsonNode = objectMapper.readTree(response.getBody());
            
            if (jsonNode.has("errcode")) {
                throw new RuntimeException("微信授权失败: " + jsonNode.get("errmsg").asText());
            }
            
            openId = jsonNode.get("openid").asText();
            if (jsonNode.has("unionid")) {
                unionId = jsonNode.get("unionid").asText();
            }
            
            // 获取用户信息（如果有access_token）
            if (jsonNode.has("access_token") && (nickname == null || avatarUrl == null)) {
                String userInfoUrl = String.format(
                        "https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s",
                        jsonNode.get("access_token").asText(), openId);
                ResponseEntity<String> userInfoResponse = restTemplate.getForEntity(
                        Objects.requireNonNull(userInfoUrl), String.class);
                JsonNode userInfo = objectMapper.readTree(userInfoResponse.getBody());
                
                if (!userInfo.has("errcode")) {
                    if (nickname == null && userInfo.has("nickname")) {
                        nickname = userInfo.get("nickname").asText();
                    }
                    if (avatarUrl == null && userInfo.has("headimgurl")) {
                        avatarUrl = userInfo.get("headimgurl").asText();
                    }
                }
            }
        } catch (Exception e) {
            log.error("微信登录失败: {}", e.getMessage());
            throw new RuntimeException("微信登录失败: " + e.getMessage());
        }
        
        // 查找或创建用户
        User user = userMapper.selectOne(new LambdaQueryWrapper<User>()
                .eq(User::getWechatOpenId, openId));
        
        boolean isNewUser = false;
        if (user == null) {
            // 创建新用户
            user = new User();
            user.setWechatOpenId(openId);
            user.setWechatUnionId(unionId);
            user.setNickname(nickname != null ? nickname : "微信用户");
            user.setAvatarUrl(avatarUrl);
            user.setStatus(1);
            user.setAgreedTerms(1);
            userMapper.insert(user);
            isNewUser = true;
            log.info("创建新微信用户: userId={}, openId={}", user.getId(), openId);
        } else {
            // 更新用户信息
            LambdaUpdateWrapper<User> updateWrapper = new LambdaUpdateWrapper<User>()
                    .eq(User::getId, user.getId());
            
            if (unionId != null && user.getWechatUnionId() == null) {
                updateWrapper.set(User::getWechatUnionId, unionId);
            }
            if (user.getAgreedTerms() == null || user.getAgreedTerms() == 0) {
                updateWrapper.set(User::getAgreedTerms, 1);
            }
            
            userMapper.update(null, updateWrapper);
        }
        
        // 更新设备Token
        if (request.getDeviceToken() != null) {
            userMapper.update(null, new LambdaUpdateWrapper<User>()
                    .eq(User::getId, user.getId())
                    .set(User::getDeviceToken, request.getDeviceToken()));
        }
        
        // 生成JWT Token
        String accessToken = generateToken(user.getId(), jwtExpiration);
        String refreshToken = generateToken(user.getId(), REFRESH_TOKEN_EXPIRATION);
        
        return LoginResponse.builder()
                .userId(user.getId())
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(jwtExpiration / 1000)
                .nickname(user.getNickname())
                .avatarUrl(user.getAvatarUrl())
                .isNewUser(isNewUser)
                .build();
    }
    
    @Override
    public LoginResponse refreshToken(String token) {
        Claims claims = parseToken(token);
        if (claims == null) {
            throw new RuntimeException("无效的Token");
        }
        
        Long userId = Long.valueOf(claims.getSubject());
        User user = userMapper.selectById(userId);
        if (user == null || user.getStatus() != 1) {
            throw new RuntimeException("用户不存在或已禁用");
        }
        
        String accessToken = generateToken(userId, jwtExpiration);
        String refreshToken = generateToken(userId, REFRESH_TOKEN_EXPIRATION);
        
        return LoginResponse.builder()
                .userId(userId)
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .expiresIn(jwtExpiration / 1000)
                .nickname(user.getNickname())
                .avatarUrl(user.getAvatarUrl())
                .isNewUser(false)
                .build();
    }
    
    @Override
    public boolean validateToken(String token) {
        try {
            Claims claims = parseToken(token);
            return claims != null && !claims.getExpiration().before(new Date());
        } catch (Exception e) {
            return false;
        }
    }
    
    @Override
    @Transactional
    public void logout(Long userId) {
        // 清除设备Token
        userMapper.update(null, new LambdaUpdateWrapper<User>()
                .eq(User::getId, userId)
                .set(User::getDeviceToken, null));
    }
    
    /**
     * 生成JWT Token
     */
    private String generateToken(Long userId, Long expiration) {
        SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expiration);
        
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key)
                .compact();
    }
    
    /**
     * 解析JWT Token
     */
    private Claims parseToken(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8));
            return Jwts.parser()
                    .verifyWith(key)
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
        } catch (Exception e) {
            log.warn("解析Token失败: {}", e.getMessage());
            return null;
        }
    }
    
    /**
     * 解析Apple identityToken
     * identityToken是一个JWT，解析其payload获取用户信息
     */
    private String parseAppleIdentityToken(String identityToken) {
        try {
            // Apple的identityToken是JWT格式，分为三部分：header.payload.signature
            String[] parts = identityToken.split("\\.");
            if (parts.length < 2) {
                return null;
            }
            
            // 解码payload部分
            String payload = new String(Base64.getUrlDecoder().decode(parts[1]), StandardCharsets.UTF_8);
            JsonNode jsonNode = objectMapper.readTree(payload);
            
            // 获取用户标识 (sub字段)
            if (jsonNode.has("sub")) {
                return jsonNode.get("sub").asText();
            }
            
            return null;
        } catch (Exception e) {
            log.error("解析Apple identityToken失败: {}", e.getMessage());
            return null;
        }
    }
}
