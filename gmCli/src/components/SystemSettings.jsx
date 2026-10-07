import React, { useState, useEffect } from 'react'
import { Modal, Tabs, Radio, Space, message, Card, Row, Col, Select, Button, Divider } from 'antd'
import { SettingFilled, BulbOutlined, UserOutlined, DeleteOutlined } from '@ant-design/icons'
import { useTheme, THEMES } from '../contexts/ThemeContext'
import axios from '../apiClient'

const { Option } = Select

const SystemSettings = ({ open, onClose, currentUser }) => {
  const { currentTheme, switchTheme, themeConfigs } = useTheme()
  
  // 默认服务器设置状态
  const [defaultServersConfig, setDefaultServersConfig] = useState({
    single: null, // 单选模式默认服务器ID
    multi: [],   // 多选模式默认服务器ID数组
    group: []    // 分组模式默认分组名称数组
  })
  const [servers, setServers] = useState([])
  const [groups, setGroups] = useState([])
  const [dropdownOpen, setDropdownOpen] = useState(false) // 控制下拉列表显示状态
  
  // 加载默认服务器配置
  const loadDefaultServersConfig = () => {
    try {
      const savedConfig = localStorage.getItem('defaultServersConfig')
      if (savedConfig) {
        setDefaultServersConfig(JSON.parse(savedConfig))
      }
    } catch (error) {
    }
  }
  
  // 获取服务器列表
  const fetchServers = async () => {
    try {
      const apiBase = import.meta.env.PROD ? '' : '/api'
      const response = await axios.get(`${apiBase}/servers`)
      
      let serverList = []
      if (response.data && response.data.success && response.data.data) {
        serverList = response.data.data.dataSource || []
      } else {
        serverList = response.data || []
      }
      
      const processedServerList = serverList.map(server => ({
        ...server,
        group: server.group || '默认分组'
      }))
      
      setServers(processedServerList)
      
      // 提取分组信息
      const uniqueGroups = [...new Set(processedServerList.map(server => server.group))]
      setGroups(uniqueGroups.map(group => ({
        name: group,
        count: processedServerList.filter(server => server.group === group).length
      })))
    } catch (error) {
    }
  }
  
  // 设置默认服务器
  const handleSetDefaultServer = (mode, value) => {
    const newConfig = { ...defaultServersConfig }
    
    if (mode === 'single') {
      newConfig.single = value
      // 在单选模式下，选择服务器后保持下拉列表打开
      setDropdownOpen(true)
    } else if (mode === 'multi') {
      newConfig.multi = Array.isArray(value) ? value : [value]
    } else if (mode === 'group') {
      newConfig.group = Array.isArray(value) ? value : [value]
    }
    
    setDefaultServersConfig(newConfig)
    localStorage.setItem('defaultServersConfig', JSON.stringify(newConfig))
    message.success(`已设置${getModeDisplayName(mode)}默认选择`)
  }
  
  // 清除默认服务器设置
  const handleClearDefaultServer = (mode) => {
    const newConfig = { ...defaultServersConfig }
    
    if (mode === 'single') {
      newConfig.single = null
    } else if (mode === 'multi') {
      newConfig.multi = []
    } else if (mode === 'group') {
      newConfig.group = []
    }
    
    setDefaultServersConfig(newConfig)
    localStorage.setItem('defaultServersConfig', JSON.stringify(newConfig))
    message.success(`已清除${getModeDisplayName(mode)}默认选择`)
  }
  
  // 获取模式显示名称
  const getModeDisplayName = (mode) => {
    const modeNames = {
      single: '单选服务器',
      multi: '多选服务器', 
      group: '分组选择'
    }
    return modeNames[mode] || mode
  }
  
  // 获取显示名称
  const getDisplayName = (mode, value) => {
    if (mode === 'single') {
      const server = servers.find(s => s.id === value)
      return server ? server.name : '未知服务器'
    } else if (mode === 'multi') {
      return value.map(id => {
        const server = servers.find(s => s.id === id)
        return server ? server.name : '未知服务器'
      }).join(', ')
    } else if (mode === 'group') {
      return value.join(', ')
    }
    return ''
  }

  const handleThemeChange = (newTheme) => {
    switchTheme(newTheme)
    message.success(`主题已切换为${themeConfigs[newTheme].name}`)
  }

  const themeOptions = [
    { value: THEMES.DEFAULT, label: '默认蓝色', icon: '🔵', description: '蓝色系专业主题' },
    { value: THEMES.GREEN, label: '绿色护眼', icon: '🟢', description: '绿色系护眼主题' },
    { value: THEMES.WARM_GRAY, label: '暖灰色系', icon: '⚪', description: '暖灰色护眼主题' },
    { value: THEMES.DARK_GRAY, label: '暗灰色系', icon: '⚫', description: '暗灰色护眼主题' },
    { value: THEMES.PURPLE, label: '紫色优雅', icon: '🟣', description: '紫色系优雅主题' },
    { value: THEMES.ORANGE, label: '橙色活力', icon: '🟠', description: '橙色系活力主题' }
  ]

  // 组件挂载时加载配置和服务器列表
  useEffect(() => {
    if (open) {
      loadDefaultServersConfig()
      fetchServers()
    }
  }, [open])

  // 当系统设置界面关闭时，重置下拉框状态
  useEffect(() => {
    if (!open) {
      setDropdownOpen(false)
    }
  }, [open])

  const items = [
    {
      key: 'theme',
      label: (
        <span>
          <BulbOutlined />
          主题设置
        </span>
      ),
      children: (
        <div style={{ padding: '20px 0' }}>
          <h3>选择主题</h3>
          <p style={{ color: '#666', marginBottom: 20 }}>选择您喜欢的界面主题风格</p>
          
          <Radio.Group 
            value={currentTheme} 
            onChange={(e) => handleThemeChange(e.target.value)}
            style={{ width: '100%' }}
          >
            <Row gutter={[16, 16]}>
              {themeOptions.map(option => (
                <Col span={12} key={option.value}>
                  <Card 
                    hoverable
                    style={{ 
                      border: currentTheme === option.value ? '2px solid #1890ff' : '1px solid #d9d9d9',
                      cursor: 'pointer'
                    }}
                    onClick={() => handleThemeChange(option.value)}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', marginBottom: 8 }}>
                      <span style={{ fontSize: '20px', marginRight: 8 }}>{option.icon}</span>
                      <Radio key={option.value} value={option.value} style={{ marginRight: 'auto' }}>
                        <strong>{option.label}</strong>
                      </Radio>
                    </div>
                    <p style={{ color: '#666', fontSize: '12px', margin: 0 }}>
                      {option.description}
                    </p>
                  </Card>
                </Col>
              ))}
            </Row>
          </Radio.Group>
          
          <div style={{ marginTop: 24, padding: 16, backgroundColor: '#f5f5f5', borderRadius: 6 }}>
            <h4 style={{ marginBottom: 8 }}>当前主题</h4>
            <p style={{ margin: 0, color: '#666' }}>
              已选择：<strong>{themeConfigs[currentTheme]?.name || '默认主题'}</strong>
            </p>
          </div>
        </div>
      ),
    },
    {
      key: 'servers',
      label: (
        <span>
          <SettingFilled />
          默认服务器设置
        </span>
      ),
      children: (
        <div style={{ padding: '20px 0' }}>
          <h3>默认服务器设置</h3>
          <p style={{ color: '#666', marginBottom: 20 }}>
            为每种选择模式设置默认服务器或分组，切换模式或刷新页面时会自动加载默认选择
          </p>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* 单选服务器模式 */}
            <Card 
              size="small" 
              title="单选服务器模式" 
              extra={
                <Button 
                  type="link" 
                  danger 
                  size="small"
                  icon={<DeleteOutlined />}
                  onClick={() => handleClearDefaultServer('single')}
                  disabled={!defaultServersConfig.single}
                >
                  清除
                </Button>
              }
            >
              <Select
                style={{ width: '100%' }}
                placeholder="选择默认服务器"
                value={defaultServersConfig.single}
                onChange={(value) => handleSetDefaultServer('single', value)}
                // 控制下拉列表的显示状态
                open={dropdownOpen}
                onOpenChange={(open) => {
                  // 只有当用户点击外部时才关闭下拉列表
                  if (!open) {
                    setDropdownOpen(false)
                  }
                }}
                // 点击下拉列表时保持打开状态
                onClick={() => {
                  setDropdownOpen(true)
                }}
              >
                {servers.map(server => (
                  <Option key={server.id} value={server.id}>
                    {server.name} ({server.serverAddress}:{server.port})
                  </Option>
                ))}
              </Select>
              {defaultServersConfig.single && (
                <div style={{ marginTop: 8, color: '#52c41a', fontSize: '12px' }}>
                  当前默认：{getDisplayName('single', defaultServersConfig.single)}
                </div>
              )}
            </Card>
            
            {/* 多选服务器模式 */}
            <Card 
              size="small" 
              title="多选服务器模式" 
              extra={
                <Button 
                  type="link" 
                  danger 
                  size="small"
                  icon={<DeleteOutlined />}
                  onClick={() => handleClearDefaultServer('multi')}
                  disabled={defaultServersConfig.multi.length === 0}
                >
                  清除
                </Button>
              }
            >
              <Select
                mode="multiple"
                style={{ width: '100%' }}
                placeholder="选择默认服务器（可多选）"
                value={defaultServersConfig.multi}
                onChange={(value) => handleSetDefaultServer('multi', value)}
              >
                {servers.map(server => (
                  <Option key={server.id} value={server.id}>
                    {server.name} ({server.serverAddress}:{server.port})
                  </Option>
                ))}
              </Select>
              {defaultServersConfig.multi.length > 0 && (
                <div style={{ marginTop: 8, color: '#52c41a', fontSize: '12px' }}>
                  当前默认：{getDisplayName('multi', defaultServersConfig.multi)}
                </div>
              )}
            </Card>
            
            {/* 分组选择模式 */}
            <Card 
              size="small" 
              title="分组选择模式" 
              extra={
                <Button 
                  type="link" 
                  danger 
                  size="small"
                  icon={<DeleteOutlined />}
                  onClick={() => handleClearDefaultServer('group')}
                  disabled={defaultServersConfig.group.length === 0}
                >
                  清除
                </Button>
              }
            >
              <Select
                mode="multiple"
                style={{ width: '100%' }}
                placeholder="选择默认分组（可多选）"
                value={defaultServersConfig.group}
                onChange={(value) => handleSetDefaultServer('group', value)}
              >
                {groups.map(group => (
                  <Option key={group.name} value={group.name}>
                    {group.name} ({group.count}台)
                  </Option>
                ))}
              </Select>
              {defaultServersConfig.group.length > 0 && (
                <div style={{ marginTop: 8, color: '#52c41a', fontSize: '12px' }}>
                  当前默认：{getDisplayName('group', defaultServersConfig.group)}
                </div>
              )}
            </Card>
          </div>
          
          <div style={{ marginTop: 24, padding: 16, backgroundColor: '#f5f5f5', borderRadius: 6 }}>
            <h4 style={{ marginBottom: 8 }}>配置说明</h4>
            <ul style={{ margin: 0, color: '#666', paddingLeft: 16 }}>
              <li>设置默认选择后，切换选择模式时会自动加载对应的默认服务器或分组</li>
              <li>刷新页面后也会自动恢复默认选择</li>
              <li>如果没有设置默认选择，系统会自动选择第一个服务器或分组</li>
              <li>配置信息保存在浏览器本地存储中</li>
            </ul>
          </div>
        </div>
      ),
    },
    {
      key: 'profile',
      label: (
        <span>
          <UserOutlined />
          个人信息
        </span>
      ),
      children: (
        <div style={{ padding: '20px 0' }}>
          <h3>个人信息</h3>
          <div style={{ 
            background: '#f5f5f5', 
            padding: '16px', 
            borderRadius: '6px',
            marginTop: '16px'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '12px' }}>
              <UserOutlined style={{ fontSize: '16px', color: '#1890ff', marginRight: '8px' }} />
              <span style={{ fontWeight: '500' }}>用户名：</span>
              <span style={{ marginLeft: '8px' }}>{currentUser?.name || '未知用户'}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', marginBottom: '12px' }}>
              <span style={{ fontWeight: '500', minWidth: '60px' }}>角色：</span>
              <span style={{ marginLeft: '8px' }}>{currentUser?.role || 'GM管理员'}</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <span style={{ fontWeight: '500', minWidth: '60px' }}>登录时间：</span>
              <span style={{ marginLeft: '8px' }}>{new Date().toLocaleString('zh-CN')}</span>
            </div>
          </div>
        </div>
      ),
    },
  ]

  return (
    <Modal
      title={
        <Space>
          <SettingFilled style={{ color: '#1890ff' }} />
          系统设置
        </Space>
      }
      open={open}
      onCancel={onClose}
      footer={null}
      width={800}
      style={{ top: 20 }}
    >
      <Tabs defaultActiveKey="theme" items={items} />
    </Modal>
  )
}

export default SystemSettings