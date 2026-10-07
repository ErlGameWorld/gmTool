import React, { useState, useCallback, useMemo, useRef, useEffect } from 'react'
import { 
  Form, 
  Input, 
  InputNumber, 
  Select, 
  Radio, 
  Checkbox, 
  Button, 
  message, 
  Space,
  Divider,
  Spin,
  Table,
  DatePicker,
  Slider,
  ColorPicker,
  Switch,
  Rate,
  Modal,
  AutoComplete
} from 'antd'
import { PlayCircleOutlined, SearchOutlined, CopyOutlined, QuestionCircleOutlined, CloseOutlined } from '@ant-design/icons'
import dayjs from 'dayjs'
import axios from '../apiClient'
import IconPreview from './IconPreview'
import ErrorDisplay from './ErrorDisplay'
import ResultRenderer from './ResultRenderer'
import ResultContent from './ResultContent'

const { RangePicker } = DatePicker;

const { TextArea } = Input

const FIELD_HISTORY_LIMIT = 8

function fieldHistoryKey(menuId, fieldName) {
  return `gmTool.fieldHistory:${menuId || '_'}:${fieldName}`
}

function readFieldHistory(menuId, fieldName) {
  try {
    const raw = localStorage.getItem(fieldHistoryKey(menuId, fieldName))
    const arr = raw ? JSON.parse(raw) : []
    return Array.isArray(arr) ? arr.filter((v) => typeof v === 'string' && v.trim()) : []
  } catch {
    return []
  }
}

function pushFieldHistory(menuId, fieldName, value) {
  const v = String(value ?? '').trim()
  if (!v) return
  const next = [v, ...readFieldHistory(menuId, fieldName).filter((x) => x !== v)].slice(0, FIELD_HISTORY_LIMIT)
  try {
    localStorage.setItem(fieldHistoryKey(menuId, fieldName), JSON.stringify(next))
  } catch {
    /* ignore quota */
  }
}

/** 文本参数：关闭浏览器乱填，仅提示本菜单该字段的历史输入 */
const FieldHistoryInput = ({ menuId, fieldName, placeholder, value, onChange, onBlur, ...rest }) => {
  const [options, setOptions] = useState(() =>
    readFieldHistory(menuId, fieldName).map((v) => ({ value: v }))
  )

  const refreshOptions = () => {
    setOptions(readFieldHistory(menuId, fieldName).map((v) => ({ value: v })))
  }

  return (
    <AutoComplete
      value={value}
      options={options}
      onFocus={refreshOptions}
      onSearch={refreshOptions}
      onChange={onChange}
      onBlur={(e) => {
        pushFieldHistory(menuId, fieldName, value)
        refreshOptions()
        onBlur?.(e)
      }}
      placeholder={placeholder}
      allowClear
      filterOption={(input, option) =>
        String(option?.value || '').toLowerCase().includes(String(input || '').toLowerCase())
      }
    >
      <Input
        autoComplete="off"
        name={`gm_${menuId || 'x'}_${fieldName}`}
        {...rest}
      />
    </AutoComplete>
  )
}

const FunctionPanel = ({ menu, onBack, selectedServers = [], serversReady = true, onOpenMenu, onMenusReloaded }) => {
  const hasParams = menu.params && menu.params.length > 0
  const [form] = Form.useForm()
  const [result, setResult] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const [showIconPreview, setShowIconPreview] = useState(false)
  const [searchText, setSearchText] = useState('')
  // 搜索结果数据 - 为每个服务器创建独立的状态
  const [filteredDataSource, setFilteredDataSource] = useState(null)
  const [serverFilteredData, setServerFilteredData] = useState({})
  const [showRequestParams, setShowRequestParams] = useState(false)
  const isExecutingRef = useRef(false) // 同步防重入（避免连点双请求）
  const [paramDescriptionVisible, setParamDescriptionVisible] = useState(false)
  const [currentParamDescription, setCurrentParamDescription] = useState('')
  const [paramsCollapsed, setParamsCollapsed] = useState(false)
  const PARAM_DESC_POS_KEY = 'gmTool.paramDescPos'
  const [paramDescPos, setParamDescPos] = useState(() => {
    try {
      const raw = localStorage.getItem(PARAM_DESC_POS_KEY)
      if (raw) {
        const parsed = JSON.parse(raw)
        if (typeof parsed?.x === 'number' && typeof parsed?.y === 'number') {
          return parsed
        }
      }
    } catch (_) { /* ignore */ }
    // 默认靠右上，避开参数表单
    return {
      x: Math.max(24, (typeof window !== 'undefined' ? window.innerWidth : 1200) - 444),
      y: 80
    }
  })
  const paramDescDraggingRef = useRef(false)
  const paramDescDragOffsetRef = useRef({ x: 0, y: 0 })

  // 显示参数说明浮层
  const showParamDescription = (description) => {
    setCurrentParamDescription(description)
    setParamDescriptionVisible(true)
  }

  const clampParamDescPos = (x, y) => {
    const panelW = 420
    const panelH = 200
    const maxX = Math.max(8, window.innerWidth - panelW - 8)
    const maxY = Math.max(8, window.innerHeight - panelH - 8)
    return {
      x: Math.min(Math.max(8, x), maxX),
      y: Math.min(Math.max(8, y), maxY)
    }
  }

  const onParamDescDragStart = (e) => {
    // 点关闭按钮时不拖
    if (e.target.closest('.param-desc-panel-close')) return
    paramDescDraggingRef.current = true
    paramDescDragOffsetRef.current = {
      x: e.clientX - paramDescPos.x,
      y: e.clientY - paramDescPos.y
    }
    e.preventDefault()
  }

  useEffect(() => {
    const onMove = (e) => {
      if (!paramDescDraggingRef.current) return
      const next = clampParamDescPos(
        e.clientX - paramDescDragOffsetRef.current.x,
        e.clientY - paramDescDragOffsetRef.current.y
      )
      setParamDescPos(next)
    }
    const onUp = () => {
      if (!paramDescDraggingRef.current) return
      paramDescDraggingRef.current = false
      setParamDescPos((prev) => {
        const clamped = clampParamDescPos(prev.x, prev.y)
        try {
          localStorage.setItem(PARAM_DESC_POS_KEY, JSON.stringify(clamped))
        } catch (_) { /* ignore */ }
        return clamped
      })
    }
    window.addEventListener('mousemove', onMove)
    window.addEventListener('mouseup', onUp)
    return () => {
      window.removeEventListener('mousemove', onMove)
      window.removeEventListener('mouseup', onUp)
    }
  }, [])

  const executeFunctionRef = useRef(null)

  // 生成带问号按钮的标签
  const renderLabelWithHelp = (label, description) => {
    if (!description) return label
    
    return (
      <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
        {label}
        <QuestionCircleOutlined 
          style={{ 
            color: '#8c8c8c', 
            cursor: 'pointer',
            fontSize: '12px',
            opacity: 0.7
          }}
          onClick={() => showParamDescription(description)}
        />
      </span>
    )
  }

  // 根据参数类型渲染对应的表单控件
  const renderParamField = (param, index) => {
    const { name, label, type, required, placeholder, options, defaultValue, validation, description, ...rest } = param
    
    const rules = [
      { required, message: `${label}是必填项` }
    ]

    // 添加验证规则 - 优先使用options中的验证规则，其次使用validation字段
    if (options?.min !== undefined || validation?.min !== undefined) {
      const minValue = options?.min !== undefined ? options.min : validation?.min
      rules.push({ 
        type: 'number', 
        min: minValue, 
        message: `${label}不能小于${minValue}` 
      })
    }
    if (options?.max !== undefined || validation?.max !== undefined) {
      const maxValue = options?.max !== undefined ? options.max : validation?.max
      rules.push({ 
        type: 'number', 
        max: maxValue, 
        message: `${label}不能大于${maxValue}` 
      })
    }

    // 添加特定类型的验证规则
    if (type === 'email') {
      rules.push({ type: 'email', message: '请输入有效的邮箱地址' })
    }
    if (type === 'url') {
      rules.push({ type: 'url', message: '请输入有效的URL地址' })
    }

    switch (type) {
      case 'text':
        return (
          <Form.Item
            key={name}
            name={name}
            label={renderLabelWithHelp(label, description)}
            rules={rules}
          >
            <FieldHistoryInput
              menuId={menu.id}
              fieldName={name}
              placeholder={placeholder}
              {...rest}
            />
          </Form.Item>
        )
      
      case 'textarea':
        return (
          <Form.Item
            key={name}
            name={name}
            label={renderLabelWithHelp(label, description)}
            rules={rules}
          >
            <TextArea 
              placeholder={placeholder} 
              rows={options?.rows || rest.rows || 3}
              maxLength={options?.maxLength || rest.maxLength}
              showCount
              {...rest} 
            />
          </Form.Item>
        )
      
      case 'number':
        return (
          <Form.Item
            key={name}
            name={name}
            label={renderLabelWithHelp(label, description)}
            rules={rules}
          >
            <InputNumber 
              placeholder={placeholder}
              style={{ width: '100%' }}
              min={options?.min || validation?.min}
              max={options?.max || validation?.max}
            />
          </Form.Item>
        )
      
      case 'select':
        return (
          <Form.Item
            key={name}
            name={name}
            label={renderLabelWithHelp(label, description)}
            rules={rules}
          >
            <Select placeholder={placeholder} {...rest}>
              {options?.selectOptions?.map(option => (
                <Select.Option key={option.value} value={option.value}>
                  {option.label}
                </Select.Option>
              )) || options?.map(option => (
                <Select.Option key={option.value} value={option.value}>
                  {option.label}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>
        )
      
      case 'radio':
        return (
          <Form.Item
            key={name}
            name={name}
            label={renderLabelWithHelp(label, description)}
            rules={rules}
          >
            <Radio.Group {...rest}>
              <Space wrap>
                {options?.selectOptions?.map(option => (
                  <Radio key={option.value} value={option.value}>
                    {option.label}
                  </Radio>
                )) || options?.map(option => (
                  <Radio key={option.value} value={option.value}>
                    {option.label}
                  </Radio>
                ))}
              </Space>
            </Radio.Group>
          </Form.Item>
        )
      
      case 'checkbox':
        return (
          <Form.Item
            key={name}
            name={name}
            label={renderLabelWithHelp(label, description)}
            rules={rules}
          >
            <Checkbox.Group {...rest}>
              <Space wrap>
                {options?.selectOptions?.map(option => (
                  <Checkbox key={option.value} value={option.value}>
                    {option.label}
                  </Checkbox>
                )) || options?.map(option => (
                  <Checkbox key={option.value} value={option.value}>
                    {option.label}
                  </Checkbox>
                ))}
              </Space>
            </Checkbox.Group>
          </Form.Item>
        )
      
      case 'date':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <DatePicker 
              placeholder={placeholder || `请选择${label}`}
              style={{ width: '100%' }}
            />
          </Form.Item>
        )
      
      case 'datetime':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <DatePicker 
              showTime
              placeholder={placeholder || `请选择${label}`}
              style={{ width: '100%' }}
            />
          </Form.Item>
        )
      
      case 'time':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <DatePicker 
              picker="time"
              placeholder={placeholder || `请选择${label}`}
              style={{ width: '100%' }}
            />
          </Form.Item>
        )
      
      case 'date-range':
        // 日期范围选择组件 - 使用RangePicker
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <RangePicker 
              placeholder={[placeholder || `开始${label}`, placeholder || `结束${label}`]}
              style={{ width: '100%' }}
            />
          </Form.Item>
        )
      
      case 'datetime-range':
        // 日期时间范围选择组件 - 使用RangePicker带时分秒
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <RangePicker 
              showTime={{ format: 'HH:mm:ss' }}
              format="YYYY-MM-DD HH:mm:ss"
              placeholder={[placeholder || `开始${label}`, placeholder || `结束${label}`]}
              style={{ width: '100%' }}
            />
          </Form.Item>
        )
      
      case 'slider':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <Slider 
              min={options?.min || validation?.min || 0}
              max={options?.max || validation?.max || 100}
              marks={options?.selectOptions?.reduce((acc, option) => {
                acc[option.value] = option.label
                return acc
              }, {})}
            />
          </Form.Item>
        )
      
      case 'color':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <ColorPicker 
              showText
              style={{ width: '100%' }}
            />
          </Form.Item>
        )
      
      case 'email':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <Input 
              type="email"
              placeholder={placeholder || `请输入${label}`}
              autoComplete="new-email"
            />
          </Form.Item>
        )
      
      case 'url':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <Input 
              type="url"
              placeholder={placeholder || `请输入${label}`}
            />
          </Form.Item>
        )
      
      case 'password':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <Input.Password 
              placeholder={placeholder || `请输入${label}`}
              autoComplete="new-password"
            />
          </Form.Item>
        )
      
      case 'switch':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules} valuePropName="checked">
            <Switch 
              checkedChildren="开启" 
              unCheckedChildren="关闭"
            />
          </Form.Item>
        )
      
      case 'rate':
        return (
          <Form.Item key={name} name={name} label={renderLabelWithHelp(label, description)} rules={rules}>
            <Rate 
              count={options?.max || rest.max || 5}
            />
          </Form.Item>
        )
      
      case 'number-range':
        // 自定义数字范围组件 - 使用完全独立的Form.Item，水平布局
        // 添加自定义验证规则：最小值不能大于最大值
        const numberRangeMinRules = [
          ...rules,
          {
            validator: (_, value) => {
              const maxValue = form?.getFieldValue(`${name}_max`)
              if (value !== undefined && maxValue !== undefined && value > maxValue) {
                return Promise.reject(new Error('最小值不能大于最大值'))
              }
              return Promise.resolve()
            }
          }
        ]
        
        const numberRangeMaxRules = [
          ...rules,
          {
            validator: (_, value) => {
              const minValue = form?.getFieldValue(`${name}_min`)
              if (minValue !== undefined && value !== undefined && minValue > value) {
                return Promise.reject(new Error('最大值不能小于最小值'))
              }
              return Promise.resolve()
            }
          }
        ]
        
        return (
          <Form.Item key={name} label={renderLabelWithHelp(label, description)}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Form.Item 
                key={`${name}_min`}
                name={`${name}_min`} 
                noStyle
                style={{ flex: 1, marginBottom: 0 }}
                rules={numberRangeMinRules}
              >
                <InputNumber
                  placeholder="最小值"
                  min={options?.min || validation?.min}
                  max={options?.max || validation?.max}
                  style={{ width: '100%' }}
                />
              </Form.Item>
              <span>~</span>
              <Form.Item 
                key={`${name}_max`}
                name={`${name}_max`} 
                noStyle
                style={{ flex: 1, marginBottom: 0 }}
                rules={numberRangeMaxRules}
              >
                <InputNumber
                  placeholder="最大值"
                  min={options?.min || validation?.min}
                  max={options?.max || validation?.max}
                  style={{ width: '100%' }}
                />
              </Form.Item>
            </div>
          </Form.Item>
        )
      
      default:
        return (
          <Form.Item
            key={name}
            name={name}
            label={renderLabelWithHelp(label, description)}
            rules={rules}
          >
            <Input placeholder={placeholder} {...rest} />
          </Form.Item>
        )
    }
  }

  // 格式化日期值（antd DatePicker 用 dayjs）
  const formatDateValue = (value, type) => {
    if (!value) return value

    const fmt = (d) => {
      if (type === 'date') return d.format('YYYY-MM-DD')
      if (type === 'time') return d.format('HH:mm:ss')
      return d.format('YYYY-MM-DD HH:mm:ss')
    }

    if (value && typeof value === 'object' && typeof value.format === 'function') {
      return fmt(value)
    }

    if (typeof value === 'string') {
      const d = dayjs(value)
      return d.isValid() ? fmt(d) : value
    }

    return value
  }

  /** 菜单默认值 → Form 控件可接受的值（DatePicker 必须是 dayjs，否则整页白屏） */
  const toFormDefaultValue = (param, value) => {
    if (value === undefined || value === null) return value
    const type = param?.type
    if (type === 'date' || type === 'datetime' || type === 'time') {
      const d = dayjs(value)
      return d.isValid() ? d : undefined
    }
    if ((type === 'date-range' || type === 'datetime-range') && Array.isArray(value)) {
      return value.map((v) => {
        const d = dayjs(v)
        return d.isValid() ? d : undefined
      })
    }
    if (type === 'color' && typeof value === 'string') {
      return value
    }
    return value
  }

  /** 把 params 的 defaultValue 展开成 setFieldsValue 用的对象 */
  const buildFormDefaults = (params, prefill) => {
    const defaults = {}
    params?.forEach((param) => {
      let value = param.options?.defaultValue
      if (value === undefined) value = param.defaultValue
      if (value === undefined) return

      if (param.type === 'number-range' && Array.isArray(value) && value.length >= 2) {
        defaults[`${param.name}_min`] = value[0]
        defaults[`${param.name}_max`] = value[1]
        return
      }
      if (param.type === 'number-range' && value && typeof value === 'object' && !Array.isArray(value)) {
        if (value.min !== undefined) defaults[`${param.name}_min`] = value.min
        if (value.max !== undefined) defaults[`${param.name}_max`] = value.max
        return
      }
      defaults[param.name] = toFormDefaultValue(param, value)
    })
    if (prefill) {
      Object.keys(prefill).forEach((key) => {
        const param = params?.find((p) => p.name === key)
        defaults[key] = param ? toFormDefaultValue(param, prefill[key]) : prefill[key]
      })
    }
    return defaults
  }

  // 执行GM功能
  const executeFunction = useCallback(async (values) => {
    // 防止重复执行（用 ref，避免连点时 state 未刷新）
    if (isExecutingRef.current) {
      return
    }
    isExecutingRef.current = true

    // 记下本菜单文本参数的输入历史（仅本字段，不混浏览器跨站联想）
    Object.entries(values || {}).forEach(([key, val]) => {
      if (typeof val === 'string') pushFieldHistory(menu.id, key, val)
    })
    
    // 如果是查看图标功能，直接显示图标预览
    if (menu.id === 'menu_icon_viewer' || menu.id === 'icon_viewer') {
      isExecutingRef.current = false
      setShowIconPreview(true)
      return
    }
    
    // 默认打 GM 本机；仅 apiConfig.sendToGMSrv === false 时直连选中区服
    const sendToGMServer = menu.apiConfig?.sendToGMSrv !== false;
    
    // 检查是否有选中的服务器
    const hasSelectedServers = selectedServers && selectedServers.length > 0
      && selectedServers.some((s) => s && s.serverAddress && s.port);
    
    // 直连区服时必须先选服
    if (!sendToGMServer && !hasSelectedServers) {
      isExecutingRef.current = false
      message.error('请先选择目标服务器')
      return
    }
    
    // 开发模式下使用/api前缀，生产模式下直接使用后端路径
    const apiBase = import.meta.env.PROD ? '' : '/api';
    
    try {
      setLoading(true)
      setError(null)
      // 不在请求前清空 result：大表（如 412 行总览）先闪空白再铺满会「闪两下」；
      // 保留旧结果，用 loading 蒙层过渡，新数据到达后再一次性替换。
      setServerFilteredData({}) // 清除所有服务器的搜索状态
      setFilteredDataSource(null)
      setSearchText('')

      const { method, path } = menu.apiConfig
      let url = path
      
      // 处理路径参数（如 {player_id}）
      const processedUrl = url.replace(/\{([^}]+)\}/g, (match, paramName) => {
        return values[paramName] || match
      })

      // 优化请求参数格式
      const optimizedValues = { ...values }
      
      // 处理range类型参数：处理数组格式的range参数
      Object.keys(optimizedValues).forEach(key => {
        const value = optimizedValues[key]
        const paramType = menu.params?.find(p => p.name === key)?.type
        
        // 处理date-range和datetime-range类型的数组格式参数
        if ((paramType === 'date-range' || paramType === 'datetime-range') && Array.isArray(value)) {
          if (value.length === 2) {
            // 数组格式：[start, end] -> 转换为对象格式 {min: start, max: end}
            if (paramType === 'date-range') {
              optimizedValues[key] = {
                min: formatDateValue(value[0], 'date'),
                max: formatDateValue(value[1], 'date')
              }
            } else if (paramType === 'datetime-range') {
              optimizedValues[key] = {
                min: formatDateValue(value[0], 'datetime'),
                max: formatDateValue(value[1], 'datetime')
              }
            }
          }
        }
        
        // 处理number-range类型的_min和_max参数合并
        if (key.endsWith('_min')) {
          const baseName = key.replace('_min', '')
          const maxKey = `${baseName}_max`
          const baseParamType = menu.params?.find(p => p.name === baseName)?.type
          
          if (optimizedValues[maxKey] !== undefined && baseParamType === 'number-range') {
            // number-range类型：保持对象格式
            optimizedValues[baseName] = {
              min: optimizedValues[key],
              max: optimizedValues[maxKey]
            }
            // 删除单独的min和max参数
            delete optimizedValues[key]
            delete optimizedValues[maxKey]
          }
        }
      })

      // 日期 / 颜色等控件值 → 可 JSON 序列化的普通值
      Object.keys(optimizedValues).forEach(key => {
        const value = optimizedValues[key]
        const paramType = menu.params?.find(p => p.name === key)?.type
        
        if (paramType === 'date' || paramType === 'datetime' || paramType === 'time') {
          optimizedValues[key] = formatDateValue(value, paramType)
        } else if (paramType === 'color' && value != null) {
          if (typeof value === 'string') {
            // already hex/rgb
          } else if (typeof value.toHexString === 'function') {
            optimizedValues[key] = value.toHexString()
          } else if (typeof value.toRgbString === 'function') {
            optimizedValues[key] = value.toRgbString()
          } else {
            optimizedValues[key] = String(value)
          }
        }
      })

      // 构建请求配置
      let targetUrl = `${apiBase}${processedUrl}`;

      // 工具面板类菜单始终只打本机一次，不随顶栏选服裂变
      const isLocalOnlyTool =
        menu.id === 'menu_reload_menus'
        || menu.id === 'menu_icon_viewer'
        || menu.id === 'icon_viewer'
        || menu.id === 'menu_param_type_tester'
        || processedUrl === '/menus/reload'
        || processedUrl === '/menus'
        || processedUrl === '/icons'
        || processedUrl.startsWith('/utils/')

      // 顶栏选了区服时：按服逐个执行并展示多个结果框
      // - sendToGMSrv=false：浏览器直连各区服 address:port
      // - sendToGMSrv=true：对本机 GM 按选中服各请求一次（结果框按服展示；示例区服若同指本机可看到多框）
      const useMultiServer = hasSelectedServers && !isLocalOnlyTool

      if (useMultiServer) {
        const results = [];
        const targets = selectedServers.filter((s) => s && s.serverAddress && s.port)

        for (const targetServer of targets) {
          const serverTargetUrl = sendToGMServer
            ? `${apiBase}${processedUrl}`
            : `http://${targetServer.serverAddress}:${targetServer.port}${processedUrl}`

          const config = {
            method: method.toLowerCase(),
            url: serverTargetUrl,
            timeout: 10000
          }

          if (method === 'GET') {
            config.params = optimizedValues
          } else {
            config.data = optimizedValues
          }

          try {
            const response = await axios(config)
            const bizFail = response.data && response.data.success === false
            results.push({
              server: targetServer,
              status: response.status,
              data: response.data,
              success: !bizFail,
              error: bizFail ? (response.data.error || '业务失败') : undefined,
              timestamp: new Date().toLocaleString()
            })
          } catch (error) {
            results.push({
              server: targetServer,
              status: error.response?.status,
              data: error.response?.data,
              success: false,
              error: error.message,
              timestamp: new Date().toLocaleString()
            })
          }
        }

        setResult({
          multiServer: true,
          results: results,
          timestamp: new Date().toLocaleString(),
          request: {
            method: method,
            url: `${apiBase}${processedUrl}`,
            data: optimizedValues
          },
          servers: targets.map(server => ({
            name: server.name,
            serverAddress: server.serverAddress,
            port: server.port,
            group: typeof server.group === 'string' ? server.group : server.group?.name || '未分组'
          }))
        })

        const successCount = results.filter(r => r.success).length;
        const totalCount = results.length;

        if (totalCount === 0) {
          message.error('没有可执行的目标服务器（缺少地址或端口）')
        } else if (successCount === totalCount) {
          // 全部成功：结果面板已有绿条，跳过 toast
        } else if (successCount > 0) {
          message.warning(`部分成功：${successCount}/${totalCount} 个服务器执行成功`)
        } else {
          message.error(`所有 ${totalCount} 个服务器执行失败`)
        }
      } else {
        // 发送到GM服务器本身
        const config = {
          method: method.toLowerCase(),
          url: targetUrl,
          timeout: 8000 // 8秒超时
        }

        // 根据请求方法处理数据
        let requestData = null
        if (method === 'GET') {
          config.params = optimizedValues
          requestData = optimizedValues
        } else {
          config.data = optimizedValues
          requestData = optimizedValues
        }

        const response = await axios(config)
        
        // 检查响应数据中的success字段
        // 注意：服务器列表API返回的数据结构是 {success: true, data: {type: "table", ...}}
        // 所以需要检查 response.data.success 而不是 response.data.data.success
        if (response.data && response.data.success === false) {
          throw new Error(response.data.error || 'API执行失败')
        }
        
        setResult({
          status: response.status,
          data: response.data,
          success: true, // 添加success字段，标记执行成功
          timestamp: new Date().toLocaleString(),
          request: {
            method: method,
            url: `${apiBase}${processedUrl}`,
            data: requestData
          },
          // 标记为发送到GM服务器的请求
          sendToGMServer: true
        })
        
        // 工具面板「刷新菜单」：后端重建缓存后，前端再拉一次侧栏
        if (
          (processedUrl === '/menus/reload' || menu.id === 'menu_reload_menus')
          && typeof onMenusReloaded === 'function'
        ) {
          onMenusReloaded()
        }
      }
    } catch (error) {

      
      // 在catch块中重新获取请求信息
      const { method, path } = menu.apiConfig
      let url = path
      const processedUrl = url.replace(/\{([^}]+)\}/g, (match, paramName) => {
        return values[paramName] || match
      })
      
      // 在catch块中也优化参数格式
      const optimizedValues = { ...values }
      
      // 处理range类型参数：处理数组格式的range参数
      Object.keys(optimizedValues).forEach(key => {
        const value = optimizedValues[key]
        const paramType = menu.params?.find(p => p.name === key)?.type
        
        // 处理date-range和datetime-range类型的数组格式参数
        if ((paramType === 'date-range' || paramType === 'datetime-range') && Array.isArray(value)) {
          if (value.length === 2) {
            // 数组格式：[start, end] -> 转换为对象格式 {min: start, max: end}
            if (paramType === 'date-range') {
              optimizedValues[key] = {
                min: formatDateValue(value[0], 'date'),
                max: formatDateValue(value[1], 'date')
              }
            } else if (paramType === 'datetime-range') {
              optimizedValues[key] = {
                min: formatDateValue(value[0], 'datetime'),
                max: formatDateValue(value[1], 'datetime')
              }
            }
          }
        }
        
        // 处理number-range类型的_min和_max参数合并
        if (key.endsWith('_min')) {
          const baseName = key.replace('_min', '')
          const maxKey = `${baseName}_max`
          const baseParamType = menu.params?.find(p => p.name === baseName)?.type
          
          if (optimizedValues[maxKey] !== undefined && baseParamType === 'number-range') {
            // number-range类型：保持对象格式
            optimizedValues[baseName] = {
              min: optimizedValues[key],
              max: optimizedValues[maxKey]
            }
            // 删除单独的min和max参数
            delete optimizedValues[key]
            delete optimizedValues[maxKey]
          }
        }
      })

      // 日期 / 颜色等控件值 → 可 JSON 序列化的普通值
      Object.keys(optimizedValues).forEach(key => {
        const value = optimizedValues[key]
        const paramType = menu.params?.find(p => p.name === key)?.type
        
        if (paramType === 'date' || paramType === 'datetime' || paramType === 'time') {
          optimizedValues[key] = formatDateValue(value, paramType)
        } else if (paramType === 'color' && value != null) {
          if (typeof value === 'string') {
            // already hex/rgb
          } else if (typeof value.toHexString === 'function') {
            optimizedValues[key] = value.toHexString()
          } else if (typeof value.toRgbString === 'function') {
            optimizedValues[key] = value.toRgbString()
          } else {
            optimizedValues[key] = String(value)
          }
        }
      })
      
      setError({
        message: error.response?.data?.error || error.message || '网络请求失败',
        status: error.response?.status,
        data: error.response?.data, // 保存完整的错误响应数据
        timestamp: new Date().toLocaleString(),
        request: {
          method: method,
          url: `${apiBase}${processedUrl}`,
          data: optimizedValues
        },
        // 标记为发送到GM服务器的请求
        sendToGMServer: true
      })
      // 失败时清掉旧成功结果，避免「错误条 + 旧表」并存误导
      setResult(null)
      
      // 根据错误类型提供不同的提示
      if (error.code === 'ECONNABORTED') {
        message.error('请求超时，请检查网络连接')
      } else if (error.response?.status === 404) {
        message.error('接口不存在，请检查接口路径')
      } else {
        message.error(error.response?.data?.error || error.message || '执行失败')
      }
    } finally {
      setLoading(false)
      isExecutingRef.current = false
    }
  }, [menu, selectedServers, setLoading, setError, setResult, setServerFilteredData, setShowIconPreview, formatDateValue, message, axios, onMenusReloaded])

  executeFunctionRef.current = executeFunction

  const renderPayload = useCallback((payload, overrideRows, paginationBase) => (
    <ResultRenderer
      payload={payload}
      dataSourceOverride={overrideRows}
      menu={menu}
      onOpenMenu={onOpenMenu}
      onRefresh={() => {
        const vals = { ...form.getFieldsValue(true), ...(paginationBase || {}) }
        executeFunction(vals)
      }}
      paginationRequest={(pageOpts) => {
        const params = { ...form.getFieldsValue(true), ...(paginationBase || {}), ...pageOpts }
        // select 的 pageSize option 是字符串；antd Table 回调是数字 → 统一成字符串以免下拉变空白
        if (params.pageSize != null) {
          params.pageSize = String(params.pageSize)
        }
        if (params.page != null) {
          params.page = Number(params.page) || 1
        }
        form.setFieldsValue(params)
        executeFunction(params)
      }}
    />
  ), [menu, onOpenMenu, form, executeFunction])

  // 重置表单
  const resetForm = useCallback(() => {
    if (form) {
      form.resetFields()
    }
    setResult(null)
    setError(null)
    setSearchText('')
    setFilteredDataSource(null)
  }, [form])

  // 复制结果数据
  const copyResultData = useCallback(() => {
    try {
      // 优先从result中获取数据，如果没有则从error中获取
      let dataToCopy = ''
      if (result?.data) {
        dataToCopy = JSON.stringify(result.data, null, 2)
      } else if (error?.data) {
        dataToCopy = JSON.stringify(error.data, null, 2)
      }
      
      if (dataToCopy) {
        navigator.clipboard.writeText(dataToCopy)
        message.success('结果数据已复制到剪贴板')
      } else {
        message.warning('没有可复制的数据')
      }
    } catch (error) {
      message.error('复制失败')
    }
  }, [result, error])

  // 复制请求参数
  const copyRequestParams = useCallback(() => {
    try {
      // 优先从result中获取请求参数，如果没有则从error中获取
      let requestData = ''
      if (result?.request) {
        requestData = JSON.stringify(result.request, null, 2)
      } else if (error?.request) {
        requestData = JSON.stringify(error.request, null, 2)
      }
      
      if (requestData) {
        navigator.clipboard.writeText(requestData)
        message.success('请求参数已复制到剪贴板')
      } else {
        message.warning('没有可复制的请求参数')
      }
    } catch (error) {
      message.error('复制失败')
    }
  }, [result, error])

  // 通用搜索函数，处理各种数据结构（使用普通函数避免useCallback递归依赖问题）
  const searchInData = (data, searchValue) => {
    if (!data) return null
    if (!searchValue || typeof searchValue !== 'string') return null

    const searchLower = searchValue.toLowerCase()

    // 如果是字符串，先尝试解析为JSON
    if (typeof data === 'string') {
      try {
        const parsed = JSON.parse(data)
        // 递归处理解析后的数据
        return searchInData(parsed, searchValue)
      } catch (e) {
        // 不是JSON格式，直接搜索字符串内容
        return data.toLowerCase().includes(searchLower) ? [data] : []
      }
    }

    // 处理表格数据
    if (data?.data?.type === 'table' && data.data.dataSource) {
      return data.data.dataSource.filter(item => {
        return Object.values(item || {}).some(val =>
          String(val || '').toLowerCase().includes(searchLower)
        )
      })
    }
    // 处理服务器列表数据格式（包含success字段的响应）
    else if (data?.success && data.data) {
      // 处理服务器列表API返回的标准格式：{success: true, data: [...]}
      if (Array.isArray(data.data)) {
        return data.data.filter(item => {
          return Object.values(item || {}).some(val =>
            String(val || '').toLowerCase().includes(searchLower)
          )
        })
      }
      // 处理表格格式的服务器列表数据
      else if (data.data?.type === 'table' && data.data.dataSource) {
        return data.data.dataSource.filter(item => {
          return Object.values(item || {}).some(val =>
            String(val || '').toLowerCase().includes(searchLower)
          )
        })
      }
    }
    // 处理数组数据
    else if (Array.isArray(data)) {
      return data.filter(item => {
        return Object.values(item || {}).some(val =>
          String(val || '').toLowerCase().includes(searchLower)
        )
      })
    }
    // 处理对象数据
    else if (typeof data === 'object' && data !== null) {
      // 深度搜索对象的所有值
      const searchInObject = (obj) => {
        return Object.values(obj || {}).some(val => {
          if (typeof val === 'object' && val !== null) {
            return searchInObject(val)
          }
          return String(val || '').toLowerCase().includes(searchLower)
        })
      }

      return searchInObject(data) ? [data] : []
    }

    return null
  }

  // 搜索数据
  const handleSearch = useCallback((value) => {
    setSearchText(value)
    if (!value.trim()) {
      setFilteredDataSource(null)
      return
    }

    // 优先搜索result中的数据
    let filteredData = searchInData(result?.data, value)
    
    // 如果没有找到结果，搜索error中的数据
    if (!filteredData || filteredData.length === 0) {
      filteredData = searchInData(error?.data, value)
    }
    
    // 如果还没有找到结果，搜索result本身
    if (!filteredData || filteredData.length === 0) {
      filteredData = searchInData(result, value)
    }
    
    // 如果还没有找到结果，搜索error本身
    if (!filteredData || filteredData.length === 0) {
      filteredData = searchInData(error, value)
    }
    
    setFilteredDataSource(filteredData)
  }, [result, error, searchInData])

  // 多服务器搜索功能
  const handleServerSearch = useCallback((value, serverIndex) => {
    if (!value.trim()) {
      // 清除搜索状态
      setServerFilteredData(prev => ({
        ...prev,
        [serverIndex]: null
      }))
      return
    }

    // 获取对应服务器的结果数据
    const serverResult = result?.results?.[serverIndex]
    if (!serverResult) return

    // 使用通用搜索函数搜索数据
    const filteredData = searchInData(serverResult?.data || serverResult, value)
    
    // 设置过滤后的数据（仅针对当前服务器）
    setServerFilteredData(prev => ({
      ...prev,
      [serverIndex]: filteredData
    }))
  }, [result, searchInData])

  // 复制单个服务器结果数据
  const copyServerResultData = useCallback((serverResult) => {
    try {
      let dataToCopy = ''
      if (serverResult?.data) {
        dataToCopy = JSON.stringify(serverResult.data, null, 2)
      }
      
      if (dataToCopy) {
        navigator.clipboard.writeText(dataToCopy)
        message.success('服务器结果数据已复制到剪贴板')
      } else {
        message.warning('没有可复制的服务器数据')
      }
    } catch (error) {
      message.error('复制失败')
    }
  }, [])

  // GM服务器搜索功能
  const handleGMServerSearch = useCallback((value) => {
    if (!value || typeof value !== 'string' || !value.trim()) {
      // 清除搜索状态
      setServerFilteredData(prev => ({
        ...prev,
        [0]: null // GM服务器使用索引0
      }))
      return
    }

    // 使用通用搜索函数搜索GM服务器数据，优先处理result.data，失败时处理result本身
    let filteredData = searchInData(result?.data || result, value)
    
    // 如果result中没有找到数据，尝试搜索error中的数据
    if (!filteredData || filteredData.length === 0) {
      filteredData = searchInData(error?.data || error, value)
    }
    
    // 如果还没有找到数据，尝试搜索result和error本身（包含错误信息）
    if (!filteredData || filteredData.length === 0) {
      filteredData = searchInData(result, value)
    }
    
    if (!filteredData || filteredData.length === 0) {
      filteredData = searchInData(error, value)
    }
    
    // 确保filteredData是一个数组（即使为空数组）
    if (!filteredData) {
      filteredData = []
    }
    
    // 设置过滤后的数据（针对GM服务器，索引为0）
    setServerFilteredData(prev => ({
      ...prev,
      [0]: filteredData
    }))
  }, [result, error, searchInData])

  // 复制GM服务器结果数据
  const copyGMServerResultData = useCallback((gmResult) => {
    try {
      // 优先复制data字段，如果没有data字段，则复制整个结果对象
      let dataToCopy = ''
      if (gmResult?.data) {
        dataToCopy = JSON.stringify(gmResult.data, null, 2)
      } else if (gmResult) {
        // 失败情况下，复制整个错误对象，包含错误信息
        dataToCopy = JSON.stringify(gmResult, null, 2)
      }
      
      if (dataToCopy) {
        navigator.clipboard.writeText(dataToCopy)
        message.success('GM服务器结果数据已复制到剪贴板')
      } else {
        message.warning('没有可复制的数据')
      }
    } catch (error) {
      message.error('复制失败')
    }
  }, [])

  // 防抖函数
  const debounce = (func, delay) => {
    let timeoutId;
    return (...args) => {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => func.apply(null, args), delay);
    };
  };

  // 防抖延迟时间常量
  const DEBOUNCE_DELAY = 300;

  // GM服务器索引常量
  const GM_SERVER_INDEX = 0;

  // 创建防抖版本的搜索函数
  const debouncedHandleSearch = useMemo(() => 
    debounce((value) => handleSearch(value), DEBOUNCE_DELAY),
    [handleSearch, DEBOUNCE_DELAY]
  );

  const debouncedHandleServerSearch = useMemo(() => 
    debounce((value, serverIndex) => handleServerSearch(value, serverIndex), DEBOUNCE_DELAY),
    [handleServerSearch, DEBOUNCE_DELAY]
  );

  const debouncedHandleGMServerSearch = useMemo(() => 
    debounce((value) => handleGMServerSearch(value), DEBOUNCE_DELAY),
    [handleGMServerSearch, DEBOUNCE_DELAY]
  );

  // 打开菜单：填默认值 / 预填参数；autoRun 或跳转预填时仅自动执行一次
  // 标签已打开再点菜单只是切换，组件不卸载，不会再次 autoRun
  // 选服会影响结果框数量：等顶栏 servers 拉取完成后再 autoRun，避免先跑成「GM服务器×1」
  // 注意：不把 selectedServers 放进依赖，避免改选服反复清结果；手点「执行」用最新选服
  const formInitedRef = useRef(false)
  const autoRunDoneRef = useRef(false)

  React.useEffect(() => {
    if (!form || !menu) return

    // 每个标签面板生命周期内只初始化一次（切换标签不卸载，保留缓存）
    if (!formInitedRef.current) {
      formInitedRef.current = true
      setResult(null)
      setError(null)
      setShowIconPreview(false)
      setSearchText('')
      setFilteredDataSource(null)
      setServerFilteredData({})

      form.resetFields()
      const defaults = buildFormDefaults(menu.params, menu.__prefill)
      if (Object.keys(defaults).length > 0) {
        form.setFieldsValue(defaults)
      }
    }

    // 已执行过 autoRun 则不再跑（含：标签已打开后再次点侧栏）
    if (autoRunDoneRef.current) return

    const shouldAutoRun = menu.autoRun === true || !!menu.__prefill
    if (!shouldAutoRun) return

    // 工具面板可不等选服；其余菜单等选服栏 ready（允许选 0 台后再手点执行）
    const isLocalOnlyTool =
      menu.id === 'menu_reload_menus'
      || menu.id === 'menu_icon_viewer'
      || menu.id === 'icon_viewer'
    if (!isLocalOnlyTool && !serversReady) return

    autoRunDoneRef.current = true
    const t = setTimeout(() => {
      if (!hasParams) {
        executeFunctionRef.current?.({})
        return
      }
      form.validateFields()
        .then((vals) => executeFunctionRef.current?.(vals))
        .catch(() => {})
    }, 50)
    return () => clearTimeout(t)
  }, [menu, form, hasParams, serversReady])

  // 如果显示图标预览，则渲染IconPreview组件
  if (showIconPreview) {
    return <IconPreview onBack={() => setShowIconPreview(false)} />
  }

  return (
    <div>
      {/* 功能标题和描述 */}
      <div style={{ marginBottom: 12, width: '100%' }}>
        {menu.description && (
          <p style={{ color: '#666', marginBottom: 0, fontSize: '16px', lineHeight: '1.4' }}>{menu.description}</p>
        )}
      </div>

      {/* 参数表单（可收起，表单保持挂载以免丢输入） */}
      {hasParams ? (
        <div className={`param-form-wrap${paramsCollapsed ? ' is-collapsed' : ''}`}>
          <Form
            form={form}
            layout="horizontal"
            onFinish={executeFunction}
            className="param-form"
            labelCol={{ span: 5 }}
            wrapperCol={{ span: 20 }}
            labelAlign="left"
            colon={false}
            autoComplete="off"
            style={paramsCollapsed ? { display: 'none' } : undefined}
          >
            {menu.params.map((param, index) => (
              <div
                key={`param-${param.name || 'unnamed'}-${index}`}
                className={`param-field-row${param.type === 'textarea' ? ' param-field-row--textarea' : ''}`}
              >
                {renderParamField(param, index)}
              </div>
            ))}

            <Form.Item>
              <Space>
                <Button
                  type="primary"
                  htmlType="submit"
                  icon={<PlayCircleOutlined />}
                  loading={loading}
                >
                  执行
                </Button>
                <Button onClick={resetForm}>
                  重置
                </Button>
              </Space>
            </Form.Item>
          </Form>
          {paramsCollapsed && (
            <div className="param-form param-form--collapsed">
              <Space>
                <Button
                  type="primary"
                  icon={<PlayCircleOutlined />}
                  loading={loading}
                  onClick={() => form.submit()}
                >
                  执行
                </Button>
                <span className="param-form-collapsed-hint">参数已收起</span>
              </Space>
            </div>
          )}
          <button
            type="button"
            className="param-form-toggle"
            title={paramsCollapsed ? '展开参数' : '收起参数'}
            aria-label={paramsCollapsed ? '展开参数' : '收起参数'}
            aria-expanded={!paramsCollapsed}
            onClick={() => setParamsCollapsed((v) => !v)}
          >
            {paramsCollapsed ? '▼' : '▲'}
          </button>
        </div>
      ) : (
        <div style={{ padding: '4px 0 12px' }}>
          <Space>
            <Button
              type="primary"
              icon={<PlayCircleOutlined />}
              loading={loading}
              onClick={() => executeFunction({})}
            >
              执行
            </Button>
          </Space>
        </div>
      )}

      {/* 加载状态 */}
      {loading && !result && (
        <div style={{ textAlign: 'center', padding: '20px' }}>
          <Spin size="large" />
          <div style={{ marginTop: 8, color: '#666' }}>执行中...</div>
        </div>
      )}

      {/* 错误信息 */}
      {error && (
        <ErrorDisplay 
          error={error} 
          onSearch={error.sendToGMServer ? debouncedHandleGMServerSearch : debouncedHandleSearch} 
          onCopyResult={error.sendToGMServer ? () => copyGMServerResultData(error) : copyResultData} 
          onShowRequestParams={() => setShowRequestParams(true)} 
          filteredData={error.sendToGMServer ? serverFilteredData[0] : filteredDataSource} 
          serverIndex={error.sendToGMServer ? 0 : null} 
        />
      )}

      {/* 执行结果：loading 时保留旧表 + 半透明蒙层，避免「清空→再铺」二次闪烁 */}
      {result && (
        <div style={{ position: 'relative' }}>
          {loading && (
            <div style={{
              position: 'absolute',
              inset: 0,
              zIndex: 5,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              background: 'rgba(0,0,0,0.18)',
              borderRadius: 6,
              pointerEvents: 'none'
            }}>
              <div style={{ textAlign: 'center', background: 'rgba(255,255,255,0.92)', padding: '12px 20px', borderRadius: 8 }}>
                <Spin />
                <div style={{ marginTop: 6, color: '#666', fontSize: 13 }}>更新中…</div>
              </div>
            </div>
          )}
          <div style={{ opacity: loading ? 0.72 : 1, transition: 'opacity 0.15s ease' }}>
          {/* 多服务器请求结果展示 */}
          {result.multiServer ? (
            <div>
              {/* 执行结果统计信息 */}
              <div style={{ 
                marginBottom: 0, 
                padding: '12px 16px', 
                backgroundColor: '#f5f5f5', 
                borderRadius: '6px',
                border: '1px solid #e8e8e8'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Space>
                    <span style={{ fontWeight: 500 }}>
                      执行结果统计 ({result.timestamp})
                    </span>
                    {/* 请求参数按钮 */}
                    <Button 
                      type="default" 
                      size="small"
                      onClick={() => setShowRequestParams(true)}
                      style={{
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        border: 'none',
                        color: 'white',
                        fontWeight: 500,
                        boxShadow: '0 2px 8px rgba(102, 126, 234, 0.3)',
                        transition: 'all 0.3s ease'
                      }}
                      onMouseEnter={(e) => {
                        e.target.style.background = 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)';
                        e.target.style.transform = 'translateY(-1px)';
                        e.target.style.boxShadow = '0 4px 12px rgba(102, 126, 234, 0.4)';
                      }}
                      onMouseLeave={(e) => {
                        e.target.style.background = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
                        e.target.style.transform = 'translateY(0)';
                        e.target.style.boxShadow = '0 2px 8px rgba(102, 126, 234, 0.3)';
                      }}
                    >
                      请求参数
                    </Button>
                  </Space>
                  <div style={{ color: '#666', fontSize: '14px' }}>
                    总服务器数: {result.results.length} 
                    <span style={{ color: '#52c41a', marginLeft: 8 }}>成功: {result.results.filter(r => r.success).length}</span>
                    <span style={{ color: '#ff4d4f', marginLeft: 8 }}>失败: {result.results.filter(r => !r.success).length}</span>
                  </div>
                </div>
              </div>
              
              {/* 每个服务器的结果展示框 */}
              {result.results.map((serverResult, index) => (
                <div key={`server-result-${serverResult.server?.id || serverResult.server?.serverAddress || index}`} className="result-panel" style={{ marginBottom: 0 }}>
                  <div className="result-title" style={{ 
                    display: 'flex', 
                    justifyContent: 'space-between', 
                    alignItems: 'center',
                    backgroundColor: serverResult.success ? '#f6ffed' : '#fff2f0',
                    border: serverResult.success ? '1px solid #b7eb8f' : '1px solid #ffccc7',
                    borderRadius: '6px 6px 0 0',
                    padding: '12px 16px'
                  }}>
                    <Space>
                      <span style={{ 
                        fontWeight: 500, 
                        color: serverResult.success ? '#52c41a' : '#ff4d4f'
                      }}>
                        {serverResult.server.name} ({serverResult.server.serverAddress}:{serverResult.server.port})
                        {serverResult.success ? ' - 执行成功' : ' - 执行失败'}
                      </span>
                      <span style={{ color: '#666', fontSize: '12px' }}>
                        {serverResult.timestamp}
                      </span>
                    </Space>
                    <Space>
                      {/* 搜索功能 */}
                      <Input.Search
                        placeholder="搜索数据"
                        size="small"
                        style={{ width: 150 }}
                        enterButton={<SearchOutlined />}
                        onSearch={(value) => debouncedHandleServerSearch(value, index)}
                      />
                      {/* 复制功能 */}
                      <Button 
                        type="primary" 
                        size="small"
                        icon={<CopyOutlined />}
                        onClick={() => copyServerResultData(serverResult)}
                      >
                        复制结果
                      </Button>
                    </Space>
                  </div>
                  <ResultContent style={{ 
                    padding: '16px',
                    border: '1px solid #e8e8e8',
                    borderTop: 'none',
                    borderRadius: '0 0 6px 6px'
                  }}>
                    {serverResult.success ? (
                      renderPayload(serverResult.data, serverFilteredData[index], result?.request?.data)
                    ) : (
                      <div style={{ color: '#ff4d4f' }}>
                        <div>错误信息: {serverResult.error}</div>
                        {serverResult.data && (
                          <pre style={{ whiteSpace: 'pre-wrap', fontSize: '12px', marginTop: 8 }}>
                            {formatErrorData(serverFilteredData[index] || serverResult.data)}
                          </pre>
                        )}
                        {serverFilteredData[index] && (
                          <div style={{ marginTop: 8, color: '#1890ff', fontSize: '12px' }}>
                            已筛选出 {serverFilteredData[index]?.length || 0} 条记录
                          </div>
                        )}
                      </div>
                    )}
                  </ResultContent>
                </div>
              ))}
            </div>
          ) : (
            /* GM服务器请求结果展示 - 使用多服务器排版格式 */
            <div>
              {/* 执行结果统计信息 */}
              <div style={{ 
                marginBottom: 0, 
                padding: '12px 16px', 
                backgroundColor: '#f5f5f5', 
                borderRadius: '6px',
                border: '1px solid #e8e8e8'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <Space>
                    <span style={{ fontWeight: 500 }}>执行结果统计 ({result.timestamp})</span>
                    {/* 请求参数按钮 */}
                    <Button 
                      type="default" 
                      size="small"
                      icon={<CopyOutlined />}
                      onClick={() => setShowRequestParams(true)}
                      style={{
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        border: 'none',
                        color: 'white',
                        fontWeight: 500,
                        boxShadow: '0 2px 8px rgba(102, 126, 234, 0.3)',
                        transition: 'all 0.3s ease'
                      }}
                      onMouseEnter={(e) => {
                        e.target.style.background = 'linear-gradient(135deg, #5a6fd8 0%, #6a4190 100%)';
                        e.target.style.transform = 'translateY(-1px)';
                        e.target.style.boxShadow = '0 4px 12px rgba(102, 126, 234, 0.4)';
                      }}
                      onMouseLeave={(e) => {
                        e.target.style.background = 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)';
                        e.target.style.transform = 'translateY(0)';
                        e.target.style.boxShadow = '0 2px 8px rgba(102, 126, 234, 0.3)';
                      }}
                    >
                      请求参数
                    </Button>
                  </Space>
                  <div style={{ color: '#666', fontSize: '14px' }}>
                    总服务器数: 1 
                    <span style={{ color: '#52c41a', marginLeft: 8 }}>成功: {result.success ? 1 : 0}</span>
                    <span style={{ color: '#ff4d4f', marginLeft: 8 }}>失败: {result.success ? 0 : 1}</span>
                  </div>
                </div>
              </div>
              
              {/* GM服务器结果展示框 */}
              <div className="result-panel" style={{ marginBottom: 0 }}>
                <div className="result-title" style={{ 
                  display: 'flex', 
                  justifyContent: 'space-between', 
                  alignItems: 'center',
                  backgroundColor: result.success ? '#f6ffed' : '#fff2f0',
                  border: result.success ? '1px solid #b7eb8f' : '1px solid #ffccc7',
                  borderRadius: '6px 6px 0 0',
                  padding: '12px 16px'
                }}>
                  <Space>
                    <span style={{ 
                      fontWeight: 500, 
                      color: result.success ? '#52c41a' : '#ff4d4f'
                    }}>
                      GM服务器
                      {result.success ? ' - 执行成功' : ' - 执行失败'}
                    </span>
                    <span style={{ color: '#666', fontSize: '12px' }}>
                      {result.timestamp}
                    </span>
                  </Space>
                  <Space>
                    {/* 搜索功能 */}
                    <Input.Search
                      placeholder="搜索数据"
                      size="small"
                      style={{ width: 150 }}
                      enterButton={<SearchOutlined />}
                      onSearch={(value) => debouncedHandleGMServerSearch(value)}
                    />
                    {/* 复制功能 */}
                    <Button 
                      type="primary" 
                      size="small"
                      icon={<CopyOutlined />}
                      onClick={() => copyGMServerResultData(result)}
                    >
                      复制结果
                    </Button>
                  </Space>
                </div>
                <ResultContent style={{ 
                  padding: '16px',
                  border: '1px solid #e8e8e8',
                  borderTop: 'none',
                  borderRadius: '0 0 6px 6px'
                }}>
                  {result.success ? (
                    renderPayload(result.data, serverFilteredData[0], result?.request?.data)
                  ) : (
                    <div style={{ color: '#ff4d4f' }}>
                      <div>
                        错误信息: {result.error || '执行失败'}
                      </div>
                      
                      {serverFilteredData[0] !== null && serverFilteredData[0] !== undefined && serverFilteredData[0].length > 0 ? (
                        <div style={{ marginTop: 8 }}>
                          <pre style={{ whiteSpace: 'pre-wrap', fontSize: '12px' }}>
                            {formatErrorData(serverFilteredData[0])}
                          </pre>
                          <div style={{ marginTop: 8, color: '#1890ff', fontSize: '12px' }}>
                            已筛选出 {serverFilteredData[0]?.length || 0} 条记录
                          </div>
                        </div>
                      ) : result.data ? (
                        <div style={{ marginTop: 8 }}>
                          {renderPayload(result.data, serverFilteredData[0], result?.request?.data)}
                        </div>
                      ) : null}
                    </div>
                  )}
                </ResultContent>
              </div>
            </div>
          )}
            </div>
        </div>
      )}

      {/* 请求参数弹窗 */}
      <Modal
        title="请求参数"
        open={showRequestParams}
        onCancel={() => setShowRequestParams(false)}
        footer={[
          <Button key="copy" type="primary" icon={<CopyOutlined />} onClick={copyRequestParams}>
            复制参数
          </Button>,
          <Button key="close" onClick={() => setShowRequestParams(false)}>
            关闭
          </Button>
        ]}
        width={800}
      >
        <div>
          {/* 服务器列表信息 */}
          {result?.servers && result.servers.length > 0 && (
            <div style={{ marginBottom: 16 }}>
              <div style={{ marginBottom: 8, fontWeight: 500 }}>目标服务器列表:</div>
              <div style={{ 
                backgroundColor: '#f5f5f5', 
                padding: '12px', 
                borderRadius: '4px',
                maxHeight: '200px',
                overflow: 'auto',
                fontFamily: 'monospace',
                fontSize: '13px'
              }}>
                {result.servers.map((server, index) => (
                  <div key={`server-${index}-${server.id || server.serverAddress}`} style={{ 
                    marginBottom: 4,
                    padding: '4px 8px',
                    backgroundColor: 'white',
                    borderRadius: '2px',
                    border: '1px solid #e8e8e8',
                    lineHeight: '1.4'
                  }}>
                    {server.name} {server.serverAddress}:{server.port} {server.group}
                  </div>
                ))}
              </div>
            </div>
          )}
          
          {/* GM服务器请求标记 */}
          {(result?.sendToGMServer || error?.sendToGMServer) && (
            <div style={{ marginBottom: 16 }}>
              <div style={{ marginBottom: 8, fontWeight: 500 }}>目标服务器:</div>
              <div style={{ 
                backgroundColor: '#f0f9ff', 
                padding: '12px', 
                borderRadius: '4px',
                border: '1px solid #91d5ff',
                fontFamily: 'monospace',
                fontSize: '13px',
                color: '#096dd9'
              }}>
                <div style={{ 
                  display: 'flex', 
                  alignItems: 'center',
                  padding: '4px 8px',
                  backgroundColor: 'white',
                  borderRadius: '2px',
                  border: '1px solid #e8e8e8',
                  lineHeight: '1.4'
                }}>
                  <span style={{ 
                    display: 'inline-block',
                    width: '8px',
                    height: '8px',
                    borderRadius: '50%',
                    backgroundColor: '#1890ff',
                    marginRight: '8px'
                  }}></span>
                  向GM服务器发送请求
                </div>
              </div>
            </div>
          )}
          
          {/* 执行结果信息 */}
          {result?.multiServer && result.results && (
            <div style={{ marginBottom: 16 }}>
              <div style={{ marginBottom: 8, fontWeight: 500 }}>执行结果统计:</div>
              <div style={{ 
                backgroundColor: '#f5f5f5', 
                padding: '12px', 
                borderRadius: '4px',
                fontFamily: 'monospace',
                fontSize: '13px'
              }}>
                <div>
                  总服务器数: {result.results.length} 成功: {result.results.filter(r => r.success).length} 失败: {result.results.filter(r => !r.success).length}
                </div>
                
                {/* 失败服务器详情 */}
                {result.results.filter(r => !r.success).length > 0 && (
                  <div style={{ marginTop: 8 }}>
                    <div style={{ fontWeight: 500, color: '#ff4d4f' }}>失败服务器:</div>
                    {result.results.filter(r => !r.success).map((failedResult, index) => (
                      <div key={`failed-server-${index}-${failedResult.server?.id || failedResult.server?.serverAddress}`} style={{ 
                        marginTop: 4, 
                        padding: '4px 8px', 
                        backgroundColor: '#fff2f0', 
                        borderRadius: '2px',
                        border: '1px solid #ffccc7',
                        fontFamily: 'monospace',
                        fontSize: '12px'
                      }}>
                        {failedResult.server.name} ({failedResult.server.serverAddress}:{failedResult.server.port}) - 错误: {failedResult.error || '未知错误'}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
          
          {/* 请求信息 */}
          <div style={{ marginBottom: 8, fontWeight: 500 }}>请求信息:</div>
          <pre style={{ 
            whiteSpace: 'pre-wrap', 
            fontSize: '12px', 
            backgroundColor: '#f5f5f5', 
            padding: '12px', 
            borderRadius: '4px',
            maxHeight: '400px',
            overflow: 'auto'
          }}>
            {result?.request ? (
              <>
                {result.request.method} {result.request.url}
                {result.request.data && Object.keys(result.request.data).length > 0 && (
                  `\n请求数据:\n${JSON.stringify(result.request.data, null, 2)}`
                )}
              </>
            ) : error?.request ? (
              <>
                {error.request.method} {error.request.url}
                {error.request.data && error.request.data !== null && Object.keys(error.request.data).length > 0 && (
                  `\n请求数据:\n${JSON.stringify(error.request.data, null, 2)}`
                )}
              </>
            ) : '暂无请求参数信息'}
          </pre>
        </div>
      </Modal>

      {/* 参数说明：可拖动浮层，记住位置；不挡表单输入/粘贴 */}
      {paramDescriptionVisible && (
        <div
          className="param-desc-panel"
          style={{ left: paramDescPos.x, top: paramDescPos.y }}
        >
          <div
            className="param-desc-panel-header"
            onMouseDown={onParamDescDragStart}
          >
            <span>参数说明（可拖动）</span>
            <button
              type="button"
              className="param-desc-panel-close"
              aria-label="关闭"
              onClick={() => setParamDescriptionVisible(false)}
              style={{
                border: 'none',
                background: 'transparent',
                cursor: 'pointer',
                color: 'inherit',
                fontSize: 14,
                lineHeight: 1,
                padding: 4
              }}
            >
              <CloseOutlined />
            </button>
          </div>
          <div className="param-desc-panel-body">
            {currentParamDescription || '暂无参数说明'}
          </div>
          <div className="param-desc-panel-footer">
            <Button
              type="primary"
              size="small"
              icon={<CopyOutlined />}
              onClick={() => {
                const text = currentParamDescription || ''
                if (!text) {
                  message.warning('暂无参数说明可复制')
                  return
                }
                navigator.clipboard.writeText(text)
                  .then(() => message.success('参数说明已复制'))
                  .catch(() => message.error('复制失败'))
              }}
            >
              复制全部
            </Button>
            <Button size="small" onClick={() => setParamDescriptionVisible(false)}>
              关闭
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}

  // 导出formatErrorData函数供其他组件使用
export const formatErrorData = (data) => {
  if (!data) return null

  // 如果是字符串，尝试解析为JSON
  if (typeof data === 'string') {
    try {
      const parsed = JSON.parse(data)
      // 格式化后不转义换行符
      const formatted = JSON.stringify(parsed, null, 2)
      // 完善转义字符处理，支持更多常见转义字符
      return formatted
        .replace(/\\n/g, '\n')  // 换行符服
        .replace(/\\t/g, '\t')  // 制表符
        .replace(/\\r/g, '\r')  // 回车符
        .replace(/\\"/g, '"')   // 双引号
        .replace(/\\'/g, "'")   // 单引号
        .replace(/\\\\/g, '\\') // 反斜杠
        .replace(/\\b/g, '\b')  // 退格符
        .replace(/\\f/g, '\f')  // 换页符
    } catch (e) {
      // 如果解析失败，直接返回字符串
      return data
    }
  }

  // 如果是对象，直接格式化
  const formatted = JSON.stringify(data, null, 2)
  // 完善转义字符处理，支持更多常见转义字符
  return formatted
    .replace(/\\n/g, '\n')  // 换行符
    .replace(/\\t/g, '\t')  // 制表符
    .replace(/\\r/g, '\r')  // 回车符
    .replace(/\\"/g, '"')   // 双引号
    .replace(/\\'/g, "'")   // 单引号
    .replace(/\\\\/g, '\\') // 反斜杠
    .replace(/\\b/g, '\b')  // 退格符
    .replace(/\\f/g, '\f')  // 换页符
}

export default FunctionPanel