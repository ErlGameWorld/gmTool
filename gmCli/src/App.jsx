import React, { useState, useEffect, useCallback, useRef } from 'react'
import { Layout, Spin, message, Dropdown, Space, Avatar } from 'antd'
import { 
  MenuFoldOutlined, 
  MenuUnfoldOutlined, 
  DashboardOutlined,
  UserOutlined,
  LogoutOutlined,
  UserSwitchOutlined,
  SettingFilled,
  BulbOutlined,
  ShrinkOutlined,
  ArrowsAltOutlined
} from '@ant-design/icons'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import axios from './apiClient'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import { ThemeProvider, useTheme } from './contexts/ThemeContext'
import ProtectedRoute from './components/ProtectedRoute'
import LoginPage from './pages/LoginPage'
import IconPreview from './components/IconPreview'
import FunctionPanel from './components/FunctionPanel'
import SystemSettings from './components/SystemSettings'
import ServerSelector from './components/ServerSelector'
import PageTabs from './components/PageTabs'
import { getGroupIcon, getMenuIcon } from './utils/iconUtils'
import './index.css'

const { Header, Sider, Content } = Layout

const MainApp = () => {
  const { user, logout } = useAuth()
  const { currentTheme } = useTheme()
  const [collapsed, setCollapsed] = useState(false)
  /** @type {[{ id: string, title: string, menu: object, openKey: number }]} */
  const [openTabs, setOpenTabs] = useState([])
  const [activeTabId, setActiveTabId] = useState(null)
  const [menuGroups, setMenuGroups] = useState([])
  const [expandedGroups, setExpandedGroups] = useState(new Set())
  const [loading, setLoading] = useState(true)
  const [showIconPreview, setShowIconPreview] = useState(false)
  const [showSystemSettings, setShowSystemSettings] = useState(false)
  const [selectedServers, setSelectedServers] = useState([])
  const [serversReady, setServersReady] = useState(false)
  const [currentUser, setCurrentUser] = useState({
    name: user?.username || '管理员',
    role: user?.role || '超级管理员',
    avatar: null
  })
  const [isFetchingMenu, setIsFetchingMenu] = useState(false) // 防止重复请求菜单

  // 在组件挂载时获取菜单配置，但只在menuGroups为空时请求
  useEffect(() => {
    if (menuGroups.length === 0) {
      fetchMenuConfig()
    }
  }, [menuGroups.length])

  // 获取菜单配置（force=true 时绕过缓存，用于「刷新菜单」后重拉侧栏）
  const fetchMenuConfig = async (opts = {}) => {
    const force = !!opts.force
    // 防止重复请求
    if (isFetchingMenu) {
      return
    }
    
    try {
      setIsFetchingMenu(true)
      if (!force) {
        setLoading(true)
      }
      
      // 优先从后端获取菜单配置
      // 开发模式下使用/api前缀，生产模式下直接使用后端路径
      const apiBase = import.meta.env.PROD ? '' : '/api';
      const response = await axios.get(`${apiBase}/menus`, {
        timeout: 5000, // 5秒超时
        headers: force
          ? { 'Cache-Control': 'no-cache', Pragma: 'no-cache' }
          : { 'Cache-Control': 'max-age=300' },
        params: force ? { _t: Date.now() } : undefined
      })
      
      const groups = response.data.menuGroups || []
      setMenuGroups(groups)
      
      if (force) {
        // 刷新后只同步标签标题，不替换 menu 引用，避免已打开页缓存被清掉
        setOpenTabs((prev) =>
          prev.map((tab) => {
            for (const group of groups) {
              const found = (group.menus || []).find((m) => m.id === tab.id)
              if (found && found.name !== tab.title) {
                return { ...tab, title: found.name }
              }
            }
            return tab
          })
        )
        message.success('侧栏菜单已重新加载')
      } else {
        // 默认展开第一个分组，并打开第一个菜单为标签
        if (groups.length > 0) {
          setExpandedGroups(new Set([groups[0].id]))
          if (groups[0].menus && groups[0].menus.length > 0) {
            const first = groups[0].menus[0]
            const openKey = Date.now()
            setOpenTabs([{
              id: first.id,
              title: first.name,
              menu: { ...first, __openKey: openKey },
              openKey
            }])
            setActiveTabId(first.id)
          }
        }
      }
    } catch (error) {
      console.warn('获取后端菜单配置失败:', error)
      
      // 后端获取失败，显示空菜单
      setMenuGroups([])
      
      // 根据错误类型提供不同的提示
      if (error.code === 'ECONNABORTED') {
        message.error('后端请求超时，请检查网络连接')
      } else if (error.response?.status === 404) {
        message.error('后端服务未启动，请联系管理员')
      } else {
        message.error('获取菜单配置失败，请刷新页面重试')
      }
      

      
    } finally {
      setLoading(false)
      setIsFetchingMenu(false)
    }
  }

  const toggleGroup = (groupId) => {
    const newExpanded = new Set(expandedGroups)
    if (newExpanded.has(groupId)) {
      newExpanded.delete(groupId)
    } else {
      newExpanded.add(groupId)
    }
    setExpandedGroups(newExpanded)
  }

  const collapseAllGroups = () => {
    setExpandedGroups(new Set())
  }

  const expandAllGroups = () => {
    setExpandedGroups(new Set(menuGroups.map((g) => g.id)))
  }

  /**
   * 打开或激活菜单标签。
   * - 已打开：直接切换（保留缓存，不再 autoRun）
   * - 未打开：右侧新增；宽度不够时由 PageTabs 回调关掉最左边
   * - forceRefresh / prefill：更新该标签并 remount FunctionPanel（用于跨菜单跳转预填）
   */
  const openOrActivateTab = (menu, options = {}) => {
    if (!menu?.id) return
    const { forceRefresh = false, prefill } = options

    if (menu.id === 'menu_icon_viewer' || menu.id === 'icon_viewer') {
      setShowIconPreview(true)
      return
    }

    setShowIconPreview(false)

    setOpenTabs((prev) => {
      const existingIndex = prev.findIndex((t) => t.id === menu.id)
      const needRemount = forceRefresh || prefill != null

      // 已打开：只切换，不改 openKey / 不 remount → 不会再次 autoRun
      if (existingIndex >= 0 && !needRemount) {
        return prev
      }

      const openKey = Date.now()
      const tabMenu = {
        ...menu,
        __openKey: openKey,
        ...(prefill != null ? { __prefill: prefill } : {})
      }
      const nextTab = {
        id: menu.id,
        title: menu.name,
        menu: tabMenu,
        openKey
      }

      if (existingIndex >= 0) {
        const next = [...prev]
        next[existingIndex] = nextTab
        return next
      }

      // 先追加；若超出标题栏总宽，PageTabs 会 onTrimLeft 关掉最左边
      return [...prev, nextTab]
    })
    setActiveTabId(menu.id)
  }

  const handleMenuSelect = (menu) => {
    openOrActivateTab(menu)
  }

  const handleTabChange = (tabId) => {
    setShowIconPreview(false)
    setActiveTabId(tabId)
  }

  const handleTabClose = (tabId) => {
    setOpenTabs((prev) => {
      const index = prev.findIndex((t) => t.id === tabId)
      if (index < 0) return prev
      const next = prev.filter((t) => t.id !== tabId)

      setActiveTabId((current) => {
        if (tabId !== current) return current
        if (next.length === 0) return null
        return next[Math.min(index, next.length - 1)].id
      })
      return next
    })
  }

  /** 标题栏宽度不够时，从左边关掉若干标签 */
  const handleTrimLeft = useCallback((count) => {
    if (!count || count <= 0) return
    setOpenTabs((prev) => {
      if (prev.length <= 1) return prev
      const removeCount = Math.min(count, prev.length - 1)
      const next = prev.slice(removeCount)
      setActiveTabId((current) => {
        if (next.some((t) => t.id === current)) return current
        return next[next.length - 1]?.id ?? null
      })
      return next
    })
  }, [])

  const menuGroupsRef = useRef(menuGroups)
  menuGroupsRef.current = menuGroups
  const openOrActivateTabRef = useRef(openOrActivateTab)
  openOrActivateTabRef.current = openOrActivateTab

  /** 跨菜单跳转（表格链接 / redirect）；回调引用保持稳定，避免 RedirectView 反复触发 */
  const handleOpenMenu = useCallback((menuId, params) => {
    for (const group of menuGroupsRef.current) {
      const found = (group.menus || []).find((m) => m.id === menuId)
      if (found) {
        openOrActivateTabRef.current(found, {
          forceRefresh: true,
          prefill: params || {}
        })
        return
      }
    }
    message.warning(`未找到菜单: ${menuId}`)
  }, [])

  // 用户操作函数
  const handleLogout = () => {
    logout()
    message.success('已安全退出')
  }

  // 处理系统设置
  const handleUserSettings = () => {
    setShowSystemSettings(true)
  }

  // 用户下拉菜单
  const userMenuItems = [
    {
      key: 'profile',
      icon: <UserSwitchOutlined />,
      label: '个人信息',
      onClick: () => message.info('查看个人信息')
    },
    {
      key: 'settings',
      icon: <SettingFilled />,
      label: '系统设置',
      onClick: handleUserSettings
    },
    {
      type: 'divider',
    },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: '退出登录',
      onClick: handleLogout
    }
  ]

  if (loading) {
    return (
      <div className="loading-spinner">
        <Spin size="large" />
        <div style={{ marginTop: 16 }}>加载中...</div>
      </div>
    )
  }

  return (
    <>
      <Layout className="app-layout">
        <Header className="app-header">
          <div className="app-title">
        🎮
        GM工具
      </div>
          
          <div className="server-selector-container">
            <ServerSelector 
              onServerChange={setSelectedServers}
              selectedServers={selectedServers}
              onReady={() => setServersReady(true)}
            />
          </div>
          
          <div className="user-info">
            <Dropdown menu={{ items: userMenuItems }} placement="bottomRight">
              <Space style={{ cursor: 'pointer', padding: '4px 8px', borderRadius: '4px' }}>
              <span style={{ fontSize: '20px' }}>🪂</span>
              <span style={{ color: '#fff' }}>{currentUser.name}</span>
            </Space>
            </Dropdown>
          </div>
        </Header>
        
        <Layout>
          <Sider 
            trigger={null} 
            collapsible 
            collapsed={collapsed}
            className="menu-sidebar"
            width={280}
          >
            <div className="menu-sidebar-toolbar">
              <div className="menu-sidebar-toolbar-center">
                {React.createElement(collapsed ? MenuUnfoldOutlined : MenuFoldOutlined, {
                  className: 'trigger',
                  onClick: () => setCollapsed(!collapsed),
                })}
              </div>
              {!collapsed && (
                <div className="menu-sidebar-toolbar-right">
                  {expandedGroups.size > 0 ? (
                    <button
                      type="button"
                      className="menu-group-batch-btn"
                      title="收起全部已展开的分组"
                      onClick={collapseAllGroups}
                    >
                      <ShrinkOutlined />
                      <span>收起全部</span>
                    </button>
                  ) : (
                    <button
                      type="button"
                      className="menu-group-batch-btn"
                      title="展开全部菜单分组"
                      onClick={expandAllGroups}
                      disabled={menuGroups.length === 0}
                    >
                      <ArrowsAltOutlined />
                      <span>展开全部</span>
                    </button>
                  )}
                </div>
              )}
            </div>
            
            <div style={{ overflowY: 'auto', height: 'calc(100vh - 112px)', overflowX: 'hidden', position: 'relative' }}>
              {menuGroups.map(group => (
                <div key={group.id} className="menu-group">
                  <div 
                    className="menu-group-header"
                    onClick={() => toggleGroup(group.id)}
                  >
                    <span>
                      {getGroupIcon(group.icon)}
                      {!collapsed && group.name}
                    </span>
                    <span>
                      {expandedGroups.has(group.id) ? '▼' : '▶'}
                    </span>
                  </div>
                  
                  {expandedGroups.has(group.id) && group.menus && (
                    <div>
                      {group.menus.map(menu => (
                        <div
                          key={menu.id}
                          className={`menu-item ${activeTabId === menu.id ? 'active' : ''}`}
                          onClick={() => handleMenuSelect(menu)}
                        >
                          {getMenuIcon(menu.icon)}
                          {!collapsed && menu.name}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </Sider>
          
          <Content className="app-content">
            {!showIconPreview && (
              <PageTabs
                tabs={openTabs}
                activeId={activeTabId}
                onChange={handleTabChange}
                onClose={handleTabClose}
                onTrimLeft={handleTrimLeft}
              />
            )}
            {showIconPreview ? (
              <IconPreview onBack={() => {
                setShowIconPreview(false)
              }} />
            ) : openTabs.length > 0 ? (
              <div className="page-tabs-panels">
                {openTabs.map((tab) => (
                  <div
                    key={tab.id}
                    className="page-tab-panel"
                    style={{ display: tab.id === activeTabId ? 'block' : 'none' }}
                    aria-hidden={tab.id !== activeTabId}
                  >
                    <FunctionPanel
                      key={`${tab.id}-${tab.openKey}`}
                      menu={tab.menu}
                      selectedServers={selectedServers}
                      serversReady={serversReady}
                      onMenusReloaded={() => fetchMenuConfig({ force: true })}
                      onOpenMenu={handleOpenMenu}
                    />
                  </div>
                ))}
              </div>
            ) : (
              <div style={{ 
                display: 'flex', 
                justifyContent: 'center', 
                alignItems: 'center', 
                height: '100%',
                color: '#999',
                fontSize: '16px'
              }}>
                请选择功能菜单
              </div>
            )}
          </Content>
        </Layout>
      </Layout>

      {/* 系统设置模态框 */}
      <SystemSettings 
        open={showSystemSettings} 
        onClose={() => setShowSystemSettings(false)}
        currentUser={currentUser}
      />
    </>
  )
}

const App = () => {
  return (
    <ThemeProvider>
      <AuthProvider>
        <Router>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route 
              path="/*" 
              element={
                <ProtectedRoute>
                  <MainApp />
                </ProtectedRoute>
              } 
            />
          </Routes>
        </Router>
      </AuthProvider>
    </ThemeProvider>
  )
}

export default App