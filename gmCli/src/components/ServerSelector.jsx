import React, { useState, useEffect, useRef } from 'react'
import { Select, Button, Space, message, Modal, Tag, Tooltip } from 'antd'
import { DeleteOutlined, PlusOutlined } from '@ant-design/icons'
import axios from '../apiClient'

const { Option } = Select

const ServerSelector = ({ onServerChange, selectedServers = [], onReady }) => {
  const [servers, setServers] = useState([])
  const [groups, setGroups] = useState([])
  const [loading, setLoading] = useState(false)
  const [selectionMode, setSelectionMode] = useState('single') // 'single', 'multi', 'group'
  const [dropdownOpen, setDropdownOpen] = useState(false)
  const readyNotified = useRef(false)

  // 获取服务器列表
  const fetchServers = async () => {
    try {
      setLoading(true)
      const apiBase = import.meta.env.PROD ? '' : '/api'
      // 不带 page/pageSize → 后端返回全量，供顶栏选服
      const response = await axios.get(`${apiBase}/servers`)
      
      // 处理新的表格格式数据
      let serverList = []
      if (response.data && response.data.success && response.data.data) {
        // 表格格式数据
        serverList = response.data.data.dataSource || []
      } else {
        // 旧的数组格式数据
        serverList = response.data || []
      }
      
      // 为服务器数据添加默认分组信息（如果缺失）
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
      message.error('获取服务器列表失败')
    } finally {
      setLoading(false)
    }
  }

  // 删除服务器
  const handleDeleteServer = async (serverId) => {
    Modal.confirm({
      title: '确认删除',
      content: '确定要删除这个服务器吗？',
      onOk: async () => {
        try {
          const apiBase = import.meta.env.PROD ? '' : '/api'
          await axios.delete(`${apiBase}/servers/${serverId}`)
          message.success('服务器删除成功')
          fetchServers() // 刷新服务器列表
          
          // 如果删除的服务器是当前选中的，从选中列表中移除
          const updatedSelectedServers = selectedServers.filter(server => server.id !== serverId)
          onServerChange(updatedSelectedServers)
        } catch (error) {
          message.error('删除服务器失败')
        }
      }
    })
  }

  // 处理服务器选择变化
  const handleServerSelect = (values) => {
    
    if (selectionMode === 'single') {
      // 单选模式 - values 是单个值，不是数组
      const selectedServer = servers.find(server => String(server.id) === String(values))
      onServerChange(selectedServer ? [selectedServer] : [])
      setDropdownOpen(false)
    } else if (selectionMode === 'multi') {
      // 多选模式 - values 是一个数组
      if (Array.isArray(values)) {
        const selectedServersList = values.map(value => 
          servers.find(server => String(server.id) === String(value))
        ).filter(Boolean)
        onServerChange(selectedServersList)
      } else {
        // 如果values不是数组，可能是单选模式残留的值，清空选择
        onServerChange([])
      }
    } else {
      // 分组选择模式
      if (values && values.length > 0) {
        const groupServers = servers.filter(server => 
          values.includes(server.group)
        )
        onServerChange(groupServers)
      } else {
        onServerChange([])
      }
    }
  }

  // 清除选择
  const handleClearSelection = () => {
    onServerChange([])
  }

  // 加载默认服务器配置
  const loadDefaultServersConfig = () => {
    try {
      const savedConfig = localStorage.getItem('defaultServersConfig')
      if (savedConfig) {
        return JSON.parse(savedConfig)
      }
    } catch (error) {
    }
    return null
  }

  // 根据模式获取默认选择
  const getDefaultSelection = (mode) => {
    const config = loadDefaultServersConfig()
    if (!config) return null
    
    if (mode === 'single' && config.single != null) {
      const s = servers.find(server => server.id === config.single)
      return s ? [s] : null
    } else if (mode === 'multi' && Array.isArray(config.multi) && config.multi.length > 0) {
      const list = servers.filter(server => config.multi.includes(server.id))
      return list.length > 0 ? list : null
    } else if (mode === 'group' && Array.isArray(config.group) && config.group.length > 0) {
      const list = servers.filter(server => config.group.includes(server.group))
      return list.length > 0 ? list : null
    }
    return null
  }

  // 获取第一个服务器或分组作为默认选择
  const getFirstSelection = (mode) => {
    if (mode === 'single' && servers.length > 0) {
      return [servers[0]]
    } else if (mode === 'multi' && servers.length > 0) {
      return [servers[0]]
    } else if (mode === 'group' && groups.length > 0) {
      const firstGroup = groups[0].name
      return servers.filter(server => server.group === firstGroup)
    }
    return []
  }

  // 处理选择模式变化（自动加载默认选择）
  const handleSelectionModeChange = (newMode) => {
    // 先获取默认选择
    let defaultSelection = getDefaultSelection(newMode)
    
    // 如果没有默认选择，使用第一个服务器或分组
    if (!defaultSelection || defaultSelection.length === 0) {
      defaultSelection = getFirstSelection(newMode)
    }
    
    // 更新选择状态
    onServerChange(defaultSelection)
    setSelectionMode(newMode)
    setDropdownOpen(false)  // 关闭下拉列表
  }

  // 获取当前选中的值（单选为标量，多选/分组为数组）
  const getSelectedValues = () => {
    if (selectionMode === 'single') {
      return selectedServers.length > 0 ? selectedServers[0].id : undefined
    } else if (selectionMode === 'multi') {
      return selectedServers.map(server => server.id)
    } else {
      const selectedGroups = [...new Set(selectedServers.map(server => server.group).filter(Boolean))]
      return selectedGroups
    }
  }

  const [selectValue, setSelectValue] = useState(undefined)

  useEffect(() => {
    setSelectValue(getSelectedValues())
  }, [selectedServers, selectionMode])



  // 页面加载时自动恢复默认选择
  useEffect(() => {
    fetchServers()
  }, [])

  // 当服务器列表加载完成后，自动设置默认选择，并通知上层「选服栏已就绪」
  useEffect(() => {
    if (loading) return
    // 尚未拉过列表
    if (servers.length === 0 && groups.length === 0) return

    let defaultSelection = getDefaultSelection(selectionMode)
    if (!defaultSelection || defaultSelection.length === 0) {
      defaultSelection = getFirstSelection(selectionMode)
    }

    if (selectedServers.length === 0 && defaultSelection.length > 0) {
      onServerChange(defaultSelection)
    }

    if (!readyNotified.current) {
      readyNotified.current = true
      // 等父组件吃到 onServerChange 后再标记 ready，避免 autoRun 抢跑成 0 台
      setTimeout(() => onReady && onReady(), 0)
    }
  }, [servers, groups, selectionMode, loading])

  return (
    <div style={{ margin: 0, display: 'flex', alignItems: 'center' }}>
      <Space align="center" size="small">
        {/* 选择模式切换 */}
        <Select
          value={selectionMode}
          onChange={handleSelectionModeChange}
          style={{ width: 120 }}
        >
          <Option value="single">单选服务器</Option>
          <Option value="multi">多选服务器</Option>
          <Option value="group">按分组选择</Option>
        </Select>

        {/* 服务器选择器 */}
        <Select
          mode={selectionMode === 'single' ? undefined : 'multiple'}
          value={selectValue}
          onChange={handleServerSelect}
          placeholder={
            selectionMode === 'single' ? "请选择服务器" : 
            selectionMode === 'multi' ? "请选择服务器（可多选）" : "请选择分组（可多选）"
          }
          style={{ width: 300 }}
          loading={loading}
          allowClear
          // 控制下拉列表的显示状态
          open={selectionMode === 'single' ? dropdownOpen : undefined}
          onOpenChange={(open) => {
            if (selectionMode === 'single') {
              // 在单选模式下，只有当用户点击外部时才关闭下拉列表
              if (!open) {
                setDropdownOpen(false)
              }
            }
          }}
          // 使用 Select 组件自带的标签展示功能
          maxTagCount="responsive"
          // 在多选模式下，自定义标签显示，只显示服务器名称
          tagRender={selectionMode === 'multi' ? (props) => {
            const { label, value, closable, onClose } = props
            // 在多选模式下，只显示服务器名称
            const server = servers.find(s => s.id === value)
            const displayLabel = server ? server.name : label
            
            return (
              <Tag
                key={value}
                closable={closable}
                onClose={onClose}
                style={{ marginRight: 3 }}
              >
                {displayLabel}
              </Tag>
            )
          } : undefined}
          // 在单选模式下，点击下拉列表时保持打开状态
          onClick={() => {
            if (selectionMode === 'single') {
              setDropdownOpen(true)
            }
          }}
        >
          {selectionMode === 'group' ? (
            // 分组选择模式
            groups.map(group => (
              <Option key={group.name} value={group.name}>
                {group.name} ({group.count}台)
              </Option>
            ))
          ) : (
            // 单个/多个服务器选择模式
            servers.map(server => (
              <Option key={server.id} value={server.id}>
                {selectionMode === 'single' ? (
                  // 单选模式 - 下拉列表横向并列显示服务器分组、名称、IP和端口信息
                  <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 'bold', marginRight: '8px' }}>{server.name}</span>
                    <span style={{ fontSize: '12px', color: '#666', marginRight: '8px' }}>
                      {server.serverAddress}:{server.port}
                    </span>
                    {server.group && (
                      <span style={{ fontSize: '11px', color: '#666', marginLeft: '8px' }}>
                        {typeof server.group === 'string' ? server.group : server.group.name || '未分组'}
                      </span>
                    )}
                  </div>
                ) : (
                  // 多选模式 - 横向并列显示服务器名称、分组名称、IP和端口（不显示状态和删除按钮）
                  <div style={{ display: 'flex', alignItems: 'center', flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 'bold', marginRight: '8px' }}>{server.name}</span>
                    <span style={{ fontSize: '12px', color: '#666', marginRight: '8px' }}>
                      {server.serverAddress}:{server.port}
                    </span>
                    {server.group && (
                      <span style={{ fontSize: '11px', color: '#666', marginLeft: '8px' }}>
                        {typeof server.group === 'string' ? server.group : server.group.name || '未分组'}
                      </span>
                    )}
                  </div>
                )}
              </Option>
            ))
          )}
        </Select>

        {/* 清除选择按钮 */}
        <Button 
          onClick={handleClearSelection}
          disabled={selectedServers.length === 0}
        >
          清除选择
        </Button>
      </Space>


    </div>
  )
}

export default ServerSelector