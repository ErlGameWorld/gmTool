import React, { createContext, useContext, useState, useEffect, useRef } from 'react';

const AuthContext = createContext();

// 密码加密工具函数 - 直接内嵌在AuthContext中

/**
 * 检查浏览器是否支持加密API
 * @returns {boolean} 是否支持加密API
 */
const isCryptoSupported = () => {
  return typeof window !== 'undefined' && 
         window.crypto && 
         window.crypto.subtle && 
         typeof TextEncoder !== 'undefined' && 
         typeof TextDecoder !== 'undefined';
};

/**
 * 生成随机盐值
 * @param {number} length 盐值长度
 * @returns {string} base64编码的随机盐值
 */
const generateSalt = (length = 16) => {
  const array = new Uint8Array(length);
  window.crypto.getRandomValues(array);
  return btoa(String.fromCharCode.apply(null, array));
};

/**
 * 使用SHA-256对密码进行哈希处理
 * @param {string} password 密码
 * @param {string} salt 盐值
 * @returns {Promise<string>} base64编码的哈希值
 */
const hashPassword = async (password, salt) => {
  const encoder = new TextEncoder();
  const data = encoder.encode(password + salt);
  const hashBuffer = await window.crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return btoa(String.fromCharCode.apply(null, hashArray));
};

/**
 * 加密密码以便安全传输
 * 使用业界标准方案：盐值 + SHA-256哈希
 * @param {string} password 原始密码
 * @returns {Promise<object>} 包含加密密码和盐值的对象
 */
const encryptPassword = async (password) => {
  try {
    // 检查是否支持加密API
    if (!isCryptoSupported()) {
      throw new Error('浏览器不支持加密操作');
    }
    
    // 生成随机盐值
    const salt = generateSalt();
    
    // 对密码进行哈希处理
    const hashedPassword = await hashPassword(password, salt);
    
    // 返回加密后的数据
    return {
      encryptedPassword: hashedPassword,
      salt: salt,
      timestamp: Date.now() // 添加时间戳防止重放攻击
    };
  } catch (error) {
    console.error('密码加密失败:', error);
    throw new Error('密码加密失败，请重试');
  }
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const refreshTimerRef = useRef(null);

  // 初始化时验证Token（业界通用方案：检查过期时间）
  useEffect(() => {
    const initAuth = async () => {
      const token = localStorage.getItem('gm_token');
      const savedUser = localStorage.getItem('gm_user');
      const tokenExpiry = localStorage.getItem('gm_token_expiry');
      
      // 检查token是否过期
      if (token && savedUser && tokenExpiry && Date.now() < parseInt(tokenExpiry, 10)) {
        try {
          // 验证Token是否有效
          const apiBase = import.meta.env.PROD ? '' : '/api';
          const response = await fetch(`${apiBase}/auth/verify`, {
            headers: {
              'Authorization': `Bearer ${token}`,
            },
          });
          
          if (response.ok) {
            const data = await response.json();
            if (data.valid) {
              setUser(data.user);
              
              // 设置token自动刷新定时器（在过期前5分钟刷新）
              const remainingTime = parseInt(tokenExpiry, 10) - Date.now() - 5 * 60 * 1000;
              if (remainingTime > 0) {
                // 清理之前的定时器
                if (refreshTimerRef.current) {
                  clearTimeout(refreshTimerRef.current);
                }
                refreshTimerRef.current = setTimeout(() => {
                  refreshToken();
                }, remainingTime);
              }
            } else {
              logout();
            }
          } else {
            logout();
          }
        } catch (error) {
          logout();
        }
      } else {
        // Token过期或不存在，清除状态
        logout();
      }
      setLoading(false);
    };

    initAuth();
    
    // 清理定时器
    return () => {
      if (refreshTimerRef.current) {
        clearTimeout(refreshTimerRef.current);
        refreshTimerRef.current = null;
      }
    };
  }, []);

  const login = async (username, password) => {
    try {
      // 开发模式下使用/api前缀，生产模式下直接使用后端路径
      const apiBase = import.meta.env.PROD ? '' : '/api';
      
      // 安全传输密码：使用盐值 + SHA-256哈希
      let loginData = { username, password };
      let isEncrypted = false;
      
      if (isCryptoSupported()) {
        try {
          const encryptedData = await encryptPassword(password);
          loginData = {
            username,
            encryptedPassword: encryptedData.encryptedPassword,
            salt: encryptedData.salt,
            timestamp: encryptedData.timestamp
          };
          isEncrypted = true;
        } catch (encryptionError) {
          console.warn('密码加密失败，使用明文传输:', encryptionError);
        }
      }
      
      const response = await fetch(`${apiBase}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Password-Encrypted': isEncrypted ? 'true' : 'false'
        },
        body: JSON.stringify(loginData),
      });

      const data = await response.json();

      if (response.ok) {
        // 登录成功
        localStorage.setItem('gm_token', data.token);
        localStorage.setItem('gm_user', JSON.stringify(data.user));
        // 设置token过期时间（24小时）
        localStorage.setItem('gm_token_expiry', Date.now() + 24 * 60 * 60 * 1000);
        setUser(data.user);
        return { success: true };
      } else {
        // 登录失败，处理错误信息
        return { success: false, message: data.error || data.message || '登录失败' };
      }
    } catch (error) {
      return { success: false, message: '网络错误，请稍后重试' };
    }
  };

  // Token刷新函数
  const refreshToken = async () => {
    const token = localStorage.getItem('gm_token');
    if (!token) return;
    
    try {
      const apiBase = import.meta.env.PROD ? '' : '/api';
      const response = await fetch(`${apiBase}/auth/refresh`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });
      
      if (response.ok) {
        const data = await response.json();
        if (data.token) {
          localStorage.setItem('gm_token', data.token);
          localStorage.setItem('gm_token_expiry', Date.now() + 24 * 60 * 60 * 1000);
          
          // 重新设置刷新定时器
          if (refreshTimerRef.current) {
            clearTimeout(refreshTimerRef.current);
          }
          refreshTimerRef.current = setTimeout(() => {
            refreshToken();
          }, 23 * 60 * 60 * 1000 - 5 * 60 * 1000); // 23小时55分钟后刷新
        }
      }
    } catch (error) {
      console.error('Token刷新失败:', error);
    }
  };

  const logout = () => {
    localStorage.removeItem('gm_token');
    localStorage.removeItem('gm_user');
    localStorage.removeItem('gm_token_expiry');
    setUser(null);
    
    // 清理定时器
    if (refreshTimerRef.current) {
      clearTimeout(refreshTimerRef.current);
      refreshTimerRef.current = null;
    }
    
    // 调用登出API
    const apiBase = import.meta.env.PROD ? '' : '/api';
    fetch(`${apiBase}/auth/logout`, { method: 'POST' }).catch((error) => {
      console.warn('登出API调用失败:', error);
    });
  };

  const hasPermission = (permission) => {
    if (!user) return false;
    
    // 管理员拥有所有权限
    if (user.role === 'admin' || user.permissions === 'all') {
      return true;
    }
    
    // 检查具体权限
    return user.permissions && user.permissions.includes(permission);
  };

  const value = React.useMemo(() => ({
    user,
    loading,
    login,
    logout,
    hasPermission,
  }), [user, loading]);

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};