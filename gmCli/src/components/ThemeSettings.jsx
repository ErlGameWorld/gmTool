import React from 'react';
import { Modal, Radio, Space, Typography, Card, Divider } from 'antd';
import { useTheme, THEMES } from '../contexts/ThemeContext';

const { Title, Text } = Typography;

const ThemeSettings = ({ open, onClose }) => {
  const { currentTheme, switchTheme, themeConfigs } = useTheme();

  const handleThemeChange = (theme) => {
    switchTheme(theme);
  };

  const themeOptions = [
    {
      value: THEMES.DEFAULT,
      label: '默认主题',
      description: '蓝色系专业主题',
      previewColors: ['#667eea', '#764ba2', '#f5f7fa']
    },
    {
      value: THEMES.GREEN,
      label: '绿色护眼',
      description: '绿色系护眼主题',
      previewColors: ['#388e3c', '#4caf50', '#f1f8e9']
    },
    {
      value: THEMES.WARM_GRAY,
      label: '暖灰色系',
      description: '暖灰色护眼主题',
      previewColors: ['#6c757d', '#495057', '#f8f9fa']
    },
    {
      value: THEMES.DARK_GRAY,
      label: '暗灰色系',
      description: '暗灰色护眼主题',
      previewColors: ['#2d3748', '#4a5568', '#1a202c']
    },
    {
      value: THEMES.PURPLE,
      label: '紫色优雅',
      description: '紫色系优雅主题',
      previewColors: ['#9c27b0', '#7b1fa2', '#f3e5f5']
    },
    {
      value: THEMES.ORANGE,
      label: '橙色活力',
      description: '橙色系活力主题',
      previewColors: ['#ff6b35', '#ff8e53', '#fff8f0']
    }
  ]

  return (
    <Modal
      title="主题设置"
      open={open}
      onCancel={onClose}
      footer={null}
      width={600}
      style={{ top: 20 }}
    >
      <div style={{ padding: '16px 0' }}>
        <Text type="secondary">
          选择适合您视觉习惯的主题，设置将自动保存到本地。
        </Text>
        
        <Divider style={{ margin: '20px 0' }} />
        
        <Radio.Group 
          value={currentTheme} 
          onChange={(e) => handleThemeChange(e.target.value)}
          style={{ width: '100%' }}
        >
          <Space direction="vertical" style={{ width: '100%' }} size="middle">
            {themeOptions.map((option) => (
              <Card
                key={option.value}
                style={{
                  border: currentTheme === option.value 
                    ? '2px solid #1890ff' 
                    : '1px solid #d9d9d9',
                  cursor: 'pointer',
                  transition: 'all 0.3s',
                  backgroundColor: currentTheme === option.value ? '#f0f8ff' : '#fff'
                }}
                onClick={() => handleThemeChange(option.value)}
                hoverable
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                  <Radio key={option.value} value={option.value} />
                  
                  {/* 颜色预览 */}
                  <div style={{ display: 'flex', gap: '4px' }}>
                    {option.previewColors.map((color, index) => (
                      <div
                        key={`${option.value}-color-${index}-${color}`}
                        style={{
                          width: '24px',
                          height: '24px',
                          backgroundColor: color,
                          borderRadius: '4px',
                          border: '1px solid #d9d9d9'
                        }}
                        title={`主题色 ${index + 1}`}
                      />
                    ))}
                  </div>
                  
                  <div style={{ flex: 1 }}>
                    <Title level={5} style={{ margin: 0 }}>
                      {option.label}
                    </Title>
                    <Text type="secondary" style={{ fontSize: '12px' }}>
                      {option.description}
                    </Text>
                  </div>
                  
                  {currentTheme === option.value && (
                    <Text type="success" style={{ fontSize: '12px' }}>
                      当前使用
                    </Text>
                  )}
                </div>
              </Card>
            ))}
          </Space>
        </Radio.Group>
        
        <Divider style={{ margin: '20px 0' }} />
        
        <div style={{ textAlign: 'center' }}>
          <Text type="secondary" style={{ fontSize: '12px' }}>
            主题设置已自动保存到本地存储，下次访问时自动应用。
          </Text>
        </div>
      </div>
    </Modal>
  );
};

export default ThemeSettings;