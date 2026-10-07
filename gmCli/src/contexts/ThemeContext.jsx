import React, { createContext, useContext, useState, useEffect } from 'react';

// 定义主题类型
const THEMES = {
  DEFAULT: 'default',      // 默认蓝色系
  GREEN: 'green',          // 绿色护眼系
  WARM_GRAY: 'warmGray',   // 暖灰色系
  DARK_GRAY: 'darkGray',   // 暗灰色系
  PURPLE: 'purple',        // 紫色优雅系
  ORANGE: 'orange'         // 橙色活力系
};

// 主题配置
const THEME_CONFIGS = {
  [THEMES.DEFAULT]: {
    name: '默认主题',
    description: '蓝色系专业主题',
    colors: {
      primary: '#667eea',
      secondary: '#764ba2',
      background: 'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)',
      header: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
      sidebar: 'linear-gradient(180deg, #f8f9fa 0%, #e9ecef 100%)',
      content: 'rgba(248, 250, 255, 0.95)',
      text: '#333',
      textLight: '#6c757d'
    }
  },
  [THEMES.PURPLE]: {
    name: '紫色优雅',
    description: '紫色系优雅主题',
    colors: {
      primary: '#9c27b0',
      secondary: '#7b1fa2',
      background: 'linear-gradient(135deg, #f3e5f5 0%, #e1bee7 100%)',
      header: 'linear-gradient(135deg, #9c27b0 0%, #7b1fa2 100%)',
      sidebar: 'linear-gradient(180deg, #f3e5f5 0%, #fce4ec 100%)',
      content: 'rgba(255, 248, 255, 0.95)',
      text: '#4a148c',
      textLight: '#7b1fa2'
    }
  },
  [THEMES.GREEN]: {
    name: '绿色护眼',
    description: '绿色系护眼主题',
    colors: {
      primary: '#388e3c',
      secondary: '#4caf50',
      background: 'linear-gradient(135deg, #f1f8e9 0%, #dcedc8 100%)',
      header: 'linear-gradient(135deg, #388e3c 0%, #4caf50 100%)',
      sidebar: 'linear-gradient(180deg, #f1f8e9 0%, #e8f5e9 100%)',
      content: 'rgba(250, 255, 248, 0.95)',
      text: '#2e7d32',
      textLight: '#66bb6a'
    }
  },
  [THEMES.WARM_GRAY]: {
    name: '暖灰色系',
    description: '暖灰色护眼主题',
    colors: {
      primary: '#6c757d',
      secondary: '#495057',
      background: 'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)',
      header: 'linear-gradient(135deg, #6c757d 0%, #495057 100%)',
      sidebar: 'linear-gradient(180deg, #f8f9fa 0%, #e9ecef 100%)',
      content: 'rgba(250, 250, 250, 0.95)',
      text: '#495057',
      textLight: '#6c757d'
    }
  },
  [THEMES.DARK_GRAY]: {
    name: '暗灰色系',
    description: '暗灰色护眼主题',
    colors: {
      primary: '#2d3748',
      secondary: '#4a5568',
      background: 'linear-gradient(135deg, #2d3748 0%, #4a5568 100%)',
      header: 'linear-gradient(135deg, #1a202c 0%, #2d3748 100%)',
      sidebar: 'linear-gradient(180deg, #2d3748 0%, #1a202c 100%)',
      content: 'rgba(45, 55, 72, 0.95)',
      text: '#e2e8f0',
      textLight: '#a0aec0'
    }
  },
  [THEMES.ORANGE]: {
    name: '橙色活力',
    description: '橙色系活力主题',
    colors: {
      primary: '#ff6b35',
      secondary: '#ff8e53',
      background: 'linear-gradient(135deg, #fff8f0 0%, #ffe8d6 100%)',
      header: 'linear-gradient(135deg, #ff6b35 0%, #ff8e53 100%)',
      sidebar: 'linear-gradient(180deg, #fff8f0 0%, #ffe8d6 100%)',
      content: 'rgba(255, 253, 248, 0.95)',
      text: '#5c3c1d',
      textLight: '#8a6d3b'
    }
  }
};

// 创建主题上下文
const ThemeContext = createContext();

// 主题提供者组件
export const ThemeProvider = ({ children }) => {
  const [currentTheme, setCurrentTheme] = useState(THEMES.WARM_GRAY);

  // 从本地存储加载主题设置
  useEffect(() => {
    const savedTheme = localStorage.getItem('gm-theme');
    if (savedTheme && THEMES[savedTheme.toUpperCase()]) {
      setCurrentTheme(savedTheme);
    }
  }, []);

  // 切换主题
  const switchTheme = (theme) => {
    // 检查主题是否在THEMES对象的值中
    if (Object.values(THEMES).includes(theme)) {
      setCurrentTheme(theme);
      localStorage.setItem('gm-theme', theme);
    }
  };

  // 获取当前主题配置
  const getCurrentThemeConfig = () => THEME_CONFIGS[currentTheme];

  // 应用主题样式到文档根元素
  useEffect(() => {
    const themeConfig = getCurrentThemeConfig();
    const root = document.documentElement;
    
    // 设置CSS变量
    Object.entries(themeConfig.colors).forEach(([key, value]) => {
      root.style.setProperty(`--theme-${key}`, value);
    });

    // 设置主题类名
    root.setAttribute('data-theme', currentTheme);
  }, [currentTheme]);

  const value = {
    currentTheme,
    themes: THEMES,
    themeConfigs: THEME_CONFIGS,
    switchTheme,
    getCurrentThemeConfig
  };

  return (
    <ThemeContext.Provider value={value}>
      {children}
    </ThemeContext.Provider>
  );
};

// 使用主题的钩子
export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error('useTheme must be used within a ThemeProvider');
  }
  return context;
};

export { THEMES };