import React, { useState, useMemo } from 'react';
import { Row, Col, Card, Typography, Button, message } from 'antd';
import { ArrowLeftOutlined, CopyOutlined } from '@ant-design/icons';
import { buildIconPreviewGroups } from '../utils/iconUtils';

const { Title, Text } = Typography;

const IconPreview = ({ onBack }) => {
  const [copiedIcon, setCopiedIcon] = useState(null);
  const iconGroups = useMemo(() => buildIconPreviewGroups(), []);

  const copyIconName = (iconName, iconType) => {
    const textToCopy = iconType === 'backend' ? `"${iconName}"` : iconName;
    navigator.clipboard.writeText(textToCopy).then(() => {
      message.success(`已复制: ${textToCopy}`);
      setCopiedIcon(iconName);
      setTimeout(() => setCopiedIcon(null), 2000);
    }).catch(() => {
      message.error('复制失败');
    });
  };

  return (
    <div style={{
      padding: '24px',
      background: 'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)',
      minHeight: '100vh'
    }}>
      <div style={{ marginBottom: '24px' }}>
        <Button
          type="primary"
          icon={<ArrowLeftOutlined />}
          onClick={onBack}
          style={{
            marginBottom: '16px',
            background: 'linear-gradient(45deg, #1890ff, #36cfc9)',
            border: 'none',
            borderRadius: '8px',
            boxShadow: '0 4px 12px rgba(24, 144, 255, 0.3)'
          }}
        >
          返回工具面板
        </Button>
      </div>

      <div style={{
        background: 'white',
        borderRadius: '12px',
        padding: '24px',
        marginBottom: '24px',
        boxShadow: '0 4px 20px rgba(0, 0, 0, 0.08)'
      }}>
        <Title level={2} style={{
          color: '#1f2937',
          marginBottom: '8px',
          fontWeight: '600'
        }}>
          Ant Design 图标预览
        </Title>
        <Text style={{
          color: '#6b7280',
          fontSize: '16px',
          lineHeight: '1.6'
        }}>
          列表与侧栏映射同源（iconUtils.FA_ICON_ENTRIES）。复制「后端名」填进菜单 icon 即可生效。
          {copiedIcon ? ` 最近复制: ${copiedIcon}` : ''}
        </Text>
      </div>

      {iconGroups.map((group, groupIndex) => (
        <div key={`icon-group-${groupIndex}-${group.title}`} style={{ marginTop: '32px' }}>
          <div style={{
            background: 'linear-gradient(90deg, #667eea 0%, #764ba2 100%)',
            color: 'white',
            padding: '12px 20px',
            borderRadius: '8px',
            marginBottom: '20px',
            boxShadow: '0 2px 8px rgba(102, 126, 234, 0.3)'
          }}>
            <Title level={3} style={{
              color: 'white',
              margin: 0,
              fontSize: '18px',
              fontWeight: '500'
            }}>
              {group.title}
            </Title>
          </div>
          <Row gutter={[20, 20]}>
            {group.icons.map((icon, iconIndex) => (
              <Col xs={12} sm={8} md={6} lg={4} key={`${group.title}-icon-${iconIndex}-${icon.backendName}`}>
                <Card
                  hoverable
                  size="small"
                  style={{
                    textAlign: 'center',
                    height: '200px',
                    borderRadius: '12px',
                    border: '1px solid #e5e7eb',
                    transition: 'all 0.3s ease',
                    background: 'linear-gradient(145deg, #ffffff 0%, #f8fafc 100%)'
                  }}
                  styles={{
                    body: {
                      padding: '16px',
                      display: 'flex',
                      flexDirection: 'column',
                      justifyContent: 'space-between',
                      height: '100%'
                    }
                  }}
                >
                  <div>
                    <icon.component style={{
                      fontSize: '32px',
                      color: '#3b82f6',
                      marginBottom: '12px'
                    }} />
                  </div>

                  <div style={{ flex: 1 }}>
                    <div style={{
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      gap: '8px',
                      marginBottom: '12px'
                    }}>
                      <Button
                        type="default"
                        size="small"
                        icon={<CopyOutlined />}
                        onClick={() => copyIconName(icon.name, 'frontend')}
                        style={{
                          background: '#f8fafc',
                          border: '1px solid #e2e8f0',
                          borderRadius: '6px',
                          fontSize: '11px',
                          height: '28px',
                          padding: '0 16px',
                          width: '100%',
                          maxWidth: '120px',
                          color: '#6b7280'
                        }}
                      >
                        复制前端名
                      </Button>
                      <Button
                        type="default"
                        size="small"
                        icon={<CopyOutlined />}
                        onClick={() => copyIconName(icon.backendName, 'backend')}
                        style={{
                          background: '#f8fafc',
                          border: '1px solid #e2e8f0',
                          borderRadius: '6px',
                          fontSize: '11px',
                          height: '28px',
                          padding: '0 16px',
                          width: '100%',
                          maxWidth: '120px',
                          color: '#6b7280'
                        }}
                      >
                        复制后端名
                      </Button>
                    </div>
                  </div>

                  <Text type="secondary" style={{
                    fontSize: '11px',
                    color: '#4b5563',
                    lineHeight: '1.4',
                    marginTop: '8px'
                  }}>
                    {icon.desc} ({icon.backendName})
                  </Text>
                </Card>
              </Col>
            ))}
          </Row>
        </div>
      ))}
    </div>
  );
};

export default IconPreview;
