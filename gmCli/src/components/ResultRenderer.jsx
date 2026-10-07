import React, { useMemo, useEffect, useState, useRef } from 'react'
import { Table, Button, Space, Descriptions, Card, Form, Input, InputNumber, Select, Switch, message, Modal, Typography, Tag, Alert } from 'antd'
import axios from '../apiClient'

const { Text, Paragraph } = Typography

/** 同一来源→目标跳转会话内只执行一次，防止多标签保活后 redirect 来回打接口 */
const redirectedOnce = new Set()

/**
 * 统一渲染后端约定的 data.type:
 *   table | kv | cards | form | redirect | msg | json
 */
const ResultRenderer = ({
  payload,
  dataSourceOverride,
  menu,
  onOpenMenu,
  onRefresh,
  paginationRequest
}) => {
  const root = payload || {}
  const data = root.data
  const type = data?.type

  if (type === 'redirect') {
    return (
      <RedirectView
        data={data}
        messageText={root.message}
        onOpenMenu={onOpenMenu}
        currentMenuId={menu?.id}
      />
    )
  }
  if (type === 'msg') {
    return <MsgView text={data.text || root.message} />
  }
  if (type === 'kv') {
    return <KvView data={data} />
  }
  if (type === 'cards') {
    return <CardsView data={data} />
  }
  if (type === 'form') {
    return <FormView data={data} onRefresh={onRefresh} />
  }
  if (type === 'table') {
    return (
      <TableView
        data={data}
        dataSourceOverride={dataSourceOverride}
        menu={menu}
        onOpenMenu={onOpenMenu}
        onRefresh={onRefresh}
        paginationRequest={paginationRequest}
        pageInfo={root.pageInfo}
      />
    )
  }
  if (type === 'json') {
    return <JsonView value={data.value !== undefined ? data.value : data} message={root.message} />
  }
  if (root.message && (data === undefined || data === null)) {
    return <MsgView text={root.message} />
  }
  return <JsonView value={data !== undefined ? data : root} />
}

const MsgView = ({ text }) => (
  <div style={{ padding: '12px 0' }}>
    <Tag color="success">成功</Tag>
    <Text style={{ marginLeft: 8 }}>{text}</Text>
  </div>
)

/** 表结构 / 行详情：显式 view，或字段结构足够强时才结构化展示 */
function isSchemaOrRowPayload(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return false
  const view = value.view || value.type
  if (view === 'schema' || view === 'row' || view === 'row_detail') return true
  if (value.key_slots && Array.isArray(value.key_slots.rows)) return true
  if (value.fields && Array.isArray(value.fields.rows)) return true
  if (Array.isArray(value.fields) && value.fields.length > 0 && value.fields[0]?.field != null) return true
  if (Array.isArray(value.summary) && (value.raw_term || value.kv_term || value.fields)) return true
  return false
}

const JsonView = ({ value, message: msg }) => {
  if (isSchemaOrRowPayload(value)) {
    return <SchemaOrRowView value={value} message={msg} />
  }
  return (
    <pre style={{ whiteSpace: 'pre-wrap', fontSize: '12px', margin: 0 }}>
      {typeof value === 'string' ? value : JSON.stringify(value, null, 2)}
    </pre>
  )
}

const SchemaOrRowView = ({ value, message: msg }) => {
  const summary = value.summary
  const keySlots = value.key_slots
  const fields = value.fields
  const jsonText = value.json
  const rawTerm = value.raw_term
  const kvTerm = value.kv_term

  const copyText = async (text, tip) => {
    try {
      await navigator.clipboard.writeText(text)
      message.success(tip || '已复制')
    } catch {
      message.error('复制失败')
    }
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {msg && <div style={{ fontWeight: 500 }}>{msg}</div>}
      {(value.table || value.key_text) && (
        <Space wrap>
          {value.table && <Tag color="blue">表 {value.table}</Tag>}
          {value.display && <Tag>{value.display}</Tag>}
          {value.record && value.record !== '-' && <Tag color="purple">record {String(value.record)}</Tag>}
          {value.key_text && <Tag color="geekblue">Key {value.key_text}</Tag>}
          {value.table_comment && <Text type="secondary">{value.table_comment}</Text>}
        </Space>
      )}
      {Array.isArray(summary) && summary.length > 0 && (
        <Descriptions bordered size="small" column={1} title="概要">
          {summary.map((it, i) => (
            <Descriptions.Item key={i} label={it.label}>{formatCell(it.value)}</Descriptions.Item>
          ))}
        </Descriptions>
      )}
      {keySlots?.rows && (
        <div>
          <div style={{ fontWeight: 500, marginBottom: 8 }}>Key 槽位</div>
          <Table
            size="small"
            bordered
            pagination={false}
            rowKey={(_, i) => `ks-${i}`}
            dataSource={keySlots.rows}
            columns={(keySlots.columns || []).map((c) => ({
              title: c.title || c.key,
              dataIndex: c.key || c.dataIndex,
              key: c.key || c.dataIndex,
              ellipsis: true
            }))}
          />
        </div>
      )}
      {fields?.rows && (
        <div>
          <div style={{ fontWeight: 500, marginBottom: 8 }}>字段清单</div>
          <Table
            size="small"
            bordered
            pagination={{ pageSize: 50, showSizeChanger: true }}
            rowKey={(_, i) => `f-${i}`}
            dataSource={fields.rows}
            columns={(fields.columns || []).map((c) => ({
              title: c.title || c.key,
              dataIndex: c.key || c.dataIndex,
              key: c.key || c.dataIndex,
              ellipsis: true
            }))}
            scroll={{ y: 420 }}
          />
        </div>
      )}
      {Array.isArray(fields) && !fields.rows && (
        <div>
          <div style={{ fontWeight: 500, marginBottom: 8 }}>字段明细</div>
          <Table
            size="small"
            bordered
            pagination={false}
            rowKey={(_, i) => `fd-${i}`}
            dataSource={fields}
            columns={[
              { title: '字段', dataIndex: 'field', key: 'field', width: 160, ellipsis: true },
              { title: '说明', dataIndex: 'comment', key: 'comment', width: 180, ellipsis: true },
              {
                title: '值',
                dataIndex: 'value',
                key: 'value',
                render: (v) => <ExpandableCell text={formatCell(v)} />
              }
            ]}
            scroll={{ y: 420 }}
          />
        </div>
      )}
      {rawTerm && (
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <span style={{ fontWeight: 500 }}>原始 Value（Erlang term）</span>
            <Text type="secondary" style={{ fontSize: 12 }}>
              ~0p 元组形态，可粘贴进 erl / 行编辑；列表里的 #rec{'{}'} 仅展示用
            </Text>
            <Button size="small" type="link" onClick={() => copyText(String(rawTerm), '已复制 Value term')}>复制</Button>
          </div>
          <pre style={{
            whiteSpace: 'pre-wrap', wordBreak: 'break-all', fontSize: 12, margin: 0,
            maxHeight: 280, overflow: 'auto', background: '#1e1e1e', color: '#d4d4d4',
            padding: 12, borderRadius: 6, fontFamily: 'ui-monospace, Consolas, monospace'
          }}>
            {String(rawTerm)}
          </pre>
        </div>
      )}
      {kvTerm && (
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <span style={{ fontWeight: 500 }}>{'{Key, Value}'} 一对</span>
            <Text type="secondary" style={{ fontSize: 12 }}>整段复制方便 update/store</Text>
            <Button size="small" type="link" onClick={() => copyText(String(kvTerm), '已复制 {Key, Value}')}>复制</Button>
          </div>
          <pre style={{
            whiteSpace: 'pre-wrap', wordBreak: 'break-all', fontSize: 12, margin: 0,
            maxHeight: 200, overflow: 'auto', background: '#1e1e1e', color: '#d4d4d4',
            padding: 12, borderRadius: 6, fontFamily: 'ui-monospace, Consolas, monospace'
          }}>
            {String(kvTerm)}
          </pre>
        </div>
      )}
      {jsonText && (
        <div>
          <div style={{ fontWeight: 500, marginBottom: 8 }}>完整 JSON</div>
          <pre style={{ whiteSpace: 'pre-wrap', fontSize: 12, margin: 0, maxHeight: 360, overflow: 'auto', background: '#fafafa', padding: 12 }}>
            {typeof jsonText === 'string' ? jsonText : JSON.stringify(jsonText, null, 2)}
          </pre>
        </div>
      )}
      {!summary && !keySlots && !fields && !jsonText && !rawTerm && (
        <pre style={{ whiteSpace: 'pre-wrap', fontSize: 12 }}>{JSON.stringify(value, null, 2)}</pre>
      )}
    </div>
  )
}

/** 点击长文本放大；Modal 仅在打开时挂载，避免宽表每格一个实例 */
const ExpandableCell = ({ text }) => {
  const [open, setOpen] = useState(false)
  const s = text == null ? '-' : String(text)
  const long = s.length > 48
  return (
    <>
      <span
        title={long ? '点击查看全文' : undefined}
        style={long ? { cursor: 'pointer', color: '#1677ff' } : undefined}
        onClick={() => long && setOpen(true)}
      >
        {long ? `${s.slice(0, 48)}…` : s}
      </span>
      {open && (
        <Modal
          title="单元格内容"
          open
          onCancel={() => setOpen(false)}
          footer={[
            <Button
              key="copy"
              onClick={() => {
                navigator.clipboard.writeText(s)
                message.success('已复制')
              }}
            >
              复制
            </Button>,
            <Button key="ok" type="primary" onClick={() => setOpen(false)}>关闭</Button>
          ]}
          width={720}
        >
          <pre style={{ whiteSpace: 'pre-wrap', wordBreak: 'break-all', maxHeight: '60vh', overflow: 'auto', margin: 0 }}>{s}</pre>
        </Modal>
      )}
    </>
  )
}

const KvView = ({ data }) => {
  const items = data.items || []
  return (
    <div>
      {data.title && <div style={{ fontWeight: 500, marginBottom: 8 }}>{data.title}</div>}
      <Descriptions bordered size="small" column={1}>
        {items.map((it, i) => (
          <Descriptions.Item key={i} label={it.label}>
            {formatCell(it.value)}
          </Descriptions.Item>
        ))}
      </Descriptions>
    </div>
  )
}

const CardsView = ({ data }) => (
  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: 12 }}>
    {(data.items || []).map((card, i) => (
      <Card key={i} size="small" title={card.title || `卡片 ${i + 1}`}>
        {card.description && <Paragraph type="secondary">{card.description}</Paragraph>}
        {card.content !== undefined && (
          typeof card.content === 'object'
            ? <pre style={{ fontSize: 12, margin: 0 }}>{JSON.stringify(card.content, null, 2)}</pre>
            : <Text>{String(card.content)}</Text>
        )}
        {(card.footer !== undefined || card.extra !== undefined) && (
          <div style={{ marginTop: 8, color: '#888', fontSize: 12 }}>
            {formatCell(card.footer !== undefined ? card.footer : card.extra)}
          </div>
        )}
      </Card>
    ))}
  </div>
)

const RedirectView = ({ data, messageText, onOpenMenu, currentMenuId }) => {
  useEffect(() => {
    if (!data?.menu || !onOpenMenu) return
    if (currentMenuId && data.menu === currentMenuId) return

    const sig = `${currentMenuId || ''}->${data.menu}:${JSON.stringify(data.params || {})}`
    if (redirectedOnce.has(sig)) return
    redirectedOnce.add(sig)

    const t = setTimeout(() => {
      onOpenMenu(data.menu, resolveParamMap(data.params || {}, {}))
    }, 400)
    return () => clearTimeout(t)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data?.menu, data?.params, currentMenuId])

  return (
    <div>
      <Tag color="processing">跳转</Tag>
      <Text style={{ marginLeft: 8 }}>{messageText || data.message || `跳转到菜单 ${data.menu}`}</Text>
    </div>
  )
}

const FormView = ({ data, onRefresh }) => {
  const [form] = Form.useForm()
  const [loading, setLoading] = useState(false)
  const params = data.params || []
  const submit = data.submit || {}

  const onFinish = async (values) => {
    const method = (submit.method || 'POST').toUpperCase()
    let path = submit.path || '/'
    Object.keys(values).forEach((k) => {
      path = path.replace(`{${k}}`, encodeURIComponent(values[k] ?? ''))
    })
    setLoading(true)
    try {
      const apiBase = import.meta.env.PROD ? '' : '/api'
      await axios({ method, url: `${apiBase}${path}`, data: values })
      message.success('提交成功')
      onRefresh && onRefresh()
    } catch (e) {
      message.error(e.response?.data?.error || e.message || '提交失败')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Form form={form} layout="vertical" onFinish={onFinish} style={{ maxWidth: 960, width: '100%' }}>
      {data.title && <div style={{ fontWeight: 500, marginBottom: 12 }}>{data.title}</div>}
      {params.map((p) => (
        <Form.Item
          key={p.name}
          name={p.name}
          label={p.label || p.name}
          extra={p.description}
          rules={[{ required: !!p.required, message: '必填' }]}
          initialValue={p.options?.defaultValue ?? p.defaultValue}
          valuePropName={p.type === 'switch' ? 'checked' : 'value'}
        >
          {p.type === 'number' ? (
            <InputNumber style={{ width: '100%' }} placeholder={p.placeholder} />
          ) : p.type === 'select' ? (
            <Select
              options={(p.options?.selectOptions || []).map((o) => ({ value: o.value, label: o.label }))}
              placeholder={p.placeholder}
            />
          ) : p.type === 'textarea' ? (
            <Input.TextArea
              rows={p.options?.rows || 3}
              placeholder={p.placeholder}
              maxLength={p.options?.maxLength}
              style={{ fontFamily: 'ui-monospace, Consolas, monospace', fontSize: 13 }}
            />
          ) : p.type === 'switch' ? (
            <Switch />
          ) : (
            <Input placeholder={p.placeholder} />
          )}
        </Form.Item>
      ))}
      <Button type="primary" htmlType="submit" loading={loading}>提交</Button>
    </Form>
  )
}

const TableView = ({
  data,
  dataSourceOverride,
  menu,
  onOpenMenu,
  onRefresh,
  paginationRequest,
  pageInfo
}) => {
  const rawRows = dataSourceOverride || data.dataSource || []
  const rows = useMemo(
    () => rawRows.map((item, index) => ({
      ...item,
      key: item.key || item.id || `row-${index}`
    })),
    [rawRows]
  )

  const [widthOverrides, setWidthOverrides] = useState({})
  const columnsSig = useMemo(
    () => (data.columns || []).map((c) => c.key || c.dataIndex).join('\0'),
    [data.columns]
  )
  useEffect(() => {
    setWidthOverrides({})
  }, [columnsSig])

  const baseColumns = useMemo(() => {
    const cols = (data.columns || []).map((col) => buildColumn(col, onOpenMenu, rows))
    const actions = data.actions || []
    if (actions.length > 0) {
      cols.push({
        title: '操作',
        key: '__actions',
        fixed: 'right',
        width: Math.max(88, actions.length * 56),
        render: (_, record) => (
          <Space size="small">
            {actions.map((act) => (
              <ActionButton
                key={act.key || act.label}
                action={act}
                record={record}
                onOpenMenu={onOpenMenu}
                onRefresh={onRefresh}
              />
            ))}
          </Space>
        )
      })
    }
    return cols
  }, [data.columns, data.actions, onOpenMenu, onRefresh, rows])

  const columns = useMemo(() => {
    return baseColumns.map((col) => {
      const key = String(col.key || col.dataIndex || '')
      const width = widthOverrides[key] ?? col.width
      return {
        ...col,
        width,
        onHeaderCell: () => ({
          width,
          onResize: (nextWidth) => {
            setWidthOverrides((prev) => ({ ...prev, [key]: nextWidth }))
          }
        })
      }
    })
  }, [baseColumns, widthOverrides])

  const tableSortable = data.sortable !== false
  const truncatedCols = Number(data.truncatedCols || 0)
  const totalCols = Number(data.totalCols || 0)

  const pagination = data.pagination
    ? {
        current: Number(data.page || pageInfo?.page || 1),
        pageSize: Number(data.pageSize || pageInfo?.pageSize || 20),
        total: data.total || 0,
        showSizeChanger: true,
        showQuickJumper: true,
        showTotal: (total, range) => `第 ${range[0]}-${range[1]} 条，共 ${total} 条`,
        pageSizeOptions: menu?.params?.find((p) => p.name === 'pageSize')?.options?.selectOptions?.map((o) => String(o.value)) || ['5', '10', '20', '50', '100', '200', '500']
      }
    : false

  // 翻页才请求接口；列头排序只做当前结果本地排序（gmTool 框架能力，不约定服务端 sort）
  const onTableChange = (pag) => {
    if (!paginationRequest || !data.pagination || !pag) return
    const curPage = Number(data.page || pageInfo?.page || 1)
    const curSize = Number(data.pageSize || pageInfo?.pageSize || 20)
    const page = Number(pag.current) || curPage
    const pageSize = Number(pag.pageSize) || curSize
    if (page === curPage && pageSize === curSize) return
    paginationRequest({ page, pageSize: String(pageSize) })
  }

  const scrollX = useMemo(() => {
    const sum = columns.reduce((s, col) => s + (Number(col.width) || COL_WIDTH_DEFAULT), 0)
    return Math.max(sum, 800)
  }, [columns])

  // 首屏就用正确视口高度，避免先 360 再改高导致表格「闪第二下」
  const [scrollY, setScrollY] = useState(() =>
    typeof window !== 'undefined' ? Math.max(240, Math.floor(window.innerHeight - 340)) : 360
  )
  useEffect(() => {
    const calc = () => {
      const h = Math.max(240, Math.floor(window.innerHeight - 340))
      setScrollY((prev) => (prev === h ? prev : h))
    }
    calc()
    window.addEventListener('resize', calc)
    return () => window.removeEventListener('resize', calc)
  }, [])

  // 无服务端分页且行数多：虚拟滚动，避免 400+ 行一次性铺 DOM 造成「先半截再铺满」
  const useVirtual = !data.pagination && rows.length >= 80

  return (
    <div className="result-table-wrap">
      {truncatedCols > 0 && (
        <Alert
          type="warning"
          showIcon
          style={{ marginBottom: 8 }}
          message={
            totalCols > 0
              ? `列过多：共 ${totalCols} 列字段，当前只显示 ${Math.max(0, totalCols - truncatedCols)} 列（另有 ${truncatedCols} 列未展示）。可用「精确 Key」+「行详情」查看完整字段。`
              : `列过多：另有 ${truncatedCols} 列未展示。可用「精确 Key」+「行详情」查看完整字段。`
          }
        />
      )}
      <Table
        dataSource={rows}
        columns={columns}
        // 虚拟滚动与自定义 header（列宽拖拽）不兼容，大表优先流畅渲染
        components={useVirtual ? undefined : RESIZABLE_TABLE_COMPONENTS}
        pagination={pagination}
        onChange={onTableChange}
        size="small"
        bordered
        tableLayout="fixed"
        virtual={useVirtual}
        scroll={{ x: scrollX, y: scrollY }}
        showSorterTooltip={{ title: tableSortable ? '点击对当前表内数据本地排序' : undefined }}
      />
      {data.total != null && (
        <div style={{ marginTop: 8, color: '#666', fontSize: 12 }}>
          共 {data.total} 条记录
          {dataSourceOverride && (
            <span style={{ marginLeft: 8, color: '#1890ff' }}>
              (筛选出 {dataSourceOverride.length} 条)
            </span>
          )}
        </div>
      )}
    </div>
  )
}

const COL_WIDTH_MIN = 64
const COL_WIDTH_MAX = 200
const COL_WIDTH_DEFAULT = 100
const COL_RESIZE_MAX = 560
const COL_WIDTH_TITLE_SOFT = 112
const COL_SAMPLE_ROWS = 40
const COL_CELL_PAD = 28

function ResizableHeaderCell({ onResize, width, children, ...rest }) {
  const startRef = useRef(null)

  const onMouseDown = (e) => {
    if (!onResize || width == null) return
    e.preventDefault()
    e.stopPropagation()
    startRef.current = { x: e.clientX, w: Number(width) || COL_WIDTH_DEFAULT }
    const handle = e.currentTarget
    handle.classList.add('is-active')
    const prevSelect = document.body.style.userSelect
    document.body.style.userSelect = 'none'

    const onMove = (ev) => {
      if (!startRef.current) return
      const next = Math.min(
        COL_RESIZE_MAX,
        Math.max(COL_WIDTH_MIN, startRef.current.w + (ev.clientX - startRef.current.x))
      )
      onResize(Math.round(next))
    }
    const onUp = () => {
      startRef.current = null
      handle.classList.remove('is-active')
      document.body.style.userSelect = prevSelect
      document.removeEventListener('mousemove', onMove)
      document.removeEventListener('mouseup', onUp)
      const swallowClick = (ev) => {
        ev.stopPropagation()
        ev.preventDefault()
        document.removeEventListener('click', swallowClick, true)
      }
      document.addEventListener('click', swallowClick, true)
      window.setTimeout(() => {
        document.removeEventListener('click', swallowClick, true)
      }, 0)
    }
    document.addEventListener('mousemove', onMove)
    document.addEventListener('mouseup', onUp)
  }

  if (width == null || !onResize) {
    return <th {...rest}>{children}</th>
  }

  return (
    <th {...rest} style={{ ...(rest.style || {}), position: 'relative' }}>
      {children}
      <span
        className="result-table-col-resize"
        onClick={(e) => {
          e.preventDefault()
          e.stopPropagation()
        }}
        onMouseDown={onMouseDown}
        title="拖拽调整列宽"
      />
    </th>
  )
}

const RESIZABLE_TABLE_COMPONENTS = {
  header: { cell: ResizableHeaderCell }
}

function estimateTextPx(text) {
  const s = String(text ?? '')
  let w = 0
  for (let i = 0; i < s.length; i++) {
    w += s.charCodeAt(i) > 255 ? 13 : 7.5
  }
  return w
}

function resolveColWidth(col, rows) {
  if (col.width != null && col.width !== '') {
    const n = Number(col.width)
    if (Number.isFinite(n) && n > 0) {
      return Math.min(COL_WIDTH_MAX, Math.max(COL_WIDTH_MIN, n))
    }
  }

  const dataIndex = col.dataIndex || col.key
  const title = String(col.title || col.key || dataIndex || '')
  const titleW = Math.min(estimateTextPx(title) + COL_CELL_PAD, COL_WIDTH_TITLE_SOFT)

  let contentW = 0
  const sample = Array.isArray(rows) ? rows : []
  const n = Math.min(sample.length, COL_SAMPLE_ROWS)
  for (let i = 0; i < n; i++) {
    const cell = formatCell(sample[i]?.[dataIndex])
    if (cell === '-' || cell === '') continue
    contentW = Math.max(contentW, estimateTextPx(cell) + COL_CELL_PAD)
  }

  const raw = Math.max(titleW, contentW || titleW, COL_WIDTH_MIN)
  return Math.min(COL_WIDTH_MAX, Math.max(COL_WIDTH_MIN, Math.ceil(raw)))
}

function buildColumn(col, onOpenMenu, rows) {
  const dataIndex = col.dataIndex || col.key
  const sortable = col.sortable !== false
  const width = resolveColWidth(col, rows)
  const useEllipsis = col.ellipsis !== false
  const base = {
    title: col.title,
    dataIndex,
    key: col.key || dataIndex,
    width,
    ellipsis: useEllipsis ? { showTitle: true } : false,
    // 列头排序：仅对当前表格里的数据本地排序，不请求接口
    sorter: sortable
      ? (a, b) => compareValues(a?.[dataIndex], b?.[dataIndex])
      : false,
    sortDirections: ['ascend', 'descend']
  }

  if (col.link && onOpenMenu) {
    base.render = (text, record) => {
      const label = formatCell(text)
      return (
        <a
          className="result-table-link"
          href="#"
          title="单击跳转；可选中复制"
          onClick={(e) => {
            e.preventDefault()
            const sel = typeof window !== 'undefined' ? window.getSelection()?.toString() : ''
            if (sel) return
            const params = resolveParamMap(col.link.params || {}, record)
            onOpenMenu(col.link.menu, params)
          }}
        >
          {label}
        </a>
      )
    }
  } else {
    base.render = (text) => <ExpandableCell text={formatCell(text)} />
  }
  return base
}

function ActionButton({ action, record, onOpenMenu, onRefresh }) {
  const label = action.label || action.key || '操作'
  const run = async () => {
    if (action.menu && onOpenMenu) {
      onOpenMenu(action.menu, resolveParamMap(action.params || {}, record))
      return
    }
    if (action.api) {
      const method = (action.api.method || 'POST').toUpperCase()
      let path = action.api.path || '/'
      path = interpolatePath(path, record)
      const apiBase = import.meta.env.PROD ? '' : '/api'
      try {
        await axios({
          method,
          url: `${apiBase}${path}`,
          data: resolveParamMap(action.api.body || action.params || {}, record)
        })
        message.success(`${label}成功`)
        if (action.api.refresh !== false && onRefresh) onRefresh()
      } catch (e) {
        message.error(e.response?.data?.error || e.message || `${label}失败`)
      }
    }
  }

  const onClick = () => {
    if (action.confirm) {
      Modal.confirm({
        title: action.confirm,
        onOk: run
      })
    } else {
      run()
    }
  }

  const danger = action.danger || action.key === 'delete' || /删/.test(label)
  return (
    <Button type="link" size="small" danger={danger} onClick={onClick}>
      {label}
    </Button>
  )
}

function resolveParamMap(spec, record) {
  const out = {}
  Object.entries(spec || {}).forEach(([k, v]) => {
    if (typeof v === 'string' && record && (v in record || record[v] !== undefined)) {
      out[k] = record[v] !== undefined ? record[v] : v
    } else if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') {
      out[k] = record && record[v] !== undefined ? record[v] : v
    } else {
      out[k] = v
    }
  })
  return out
}

function interpolatePath(path, record) {
  return String(path).replace(/\{(\w+)\}/g, (_, key) => {
    const val = record?.[key]
    return encodeURIComponent(val ?? '')
  })
}

function compareValues(a, b) {
  if (a == null && b == null) return 0
  if (a == null) return -1
  if (b == null) return 1
  if (typeof a === 'number' && typeof b === 'number') return a - b
  return String(a).localeCompare(String(b), 'zh')
}

function formatCell(v) {
  if (v == null) return '-'
  if (v === '') return '-'
  if (typeof v === 'object') return JSON.stringify(v)
  return String(v)
}

export default ResultRenderer
