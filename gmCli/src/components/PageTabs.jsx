import React, { useRef, useLayoutEffect, useCallback } from 'react'
import { CloseOutlined } from '@ant-design/icons'

/**
 * 紧凑多标签栏：切换不清缓存，点 x 关闭。
 * 宽度自适应：超出容器总宽时回调 onTrimLeft，由父级关掉最左边若干个。
 */
const PageTabs = ({ tabs, activeId, onChange, onClose, onTrimLeft }) => {
  const scrollRef = useRef(null)
  const onTrimLeftRef = useRef(onTrimLeft)
  onTrimLeftRef.current = onTrimLeft

  const measureAndTrim = useCallback(() => {
    const el = scrollRef.current
    const trim = onTrimLeftRef.current
    if (!el || !trim || !tabs || tabs.length <= 1) return
    if (el.scrollWidth <= el.clientWidth + 1) return

    const children = Array.from(el.children)
    if (children.length <= 1) return

    const gap = 4
    const maxWidth = el.clientWidth

    // 从右边往左尽量多留，左边放不下的全部关掉
    let used = 0
    let keepFrom = 0
    for (let i = children.length - 1; i >= 0; i -= 1) {
      const extraGap = used > 0 ? gap : 0
      const nextUsed = used + children[i].offsetWidth + extraGap
      if (nextUsed > maxWidth) {
        keepFrom = i + 1
        break
      }
      used = nextUsed
      keepFrom = i
    }

    // 至少保留最右边 1 个
    const removeCount = Math.min(keepFrom, children.length - 1)
    if (removeCount > 0) {
      trim(removeCount)
    }
  }, [tabs])

  useLayoutEffect(() => {
    measureAndTrim()
  }, [measureAndTrim, tabs])

  useLayoutEffect(() => {
    const el = scrollRef.current
    if (!el || typeof ResizeObserver === 'undefined') return

    const ro = new ResizeObserver(() => {
      measureAndTrim()
    })
    ro.observe(el)
    return () => ro.disconnect()
  }, [measureAndTrim])

  if (!tabs || tabs.length === 0) return null

  return (
    <div className="page-tabs" role="tablist">
      <div className="page-tabs-scroll" ref={scrollRef}>
        {tabs.map((tab) => {
          const active = tab.id === activeId
          return (
            <div
              key={tab.id}
              role="tab"
              aria-selected={active}
              className={`page-tab${active ? ' active' : ''}`}
              onClick={() => onChange(tab.id)}
              title={tab.title}
            >
              <span className="page-tab-title">{tab.title}</span>
              <button
                type="button"
                className="page-tab-close"
                aria-label={`关闭 ${tab.title}`}
                onClick={(e) => {
                  e.stopPropagation()
                  onClose(tab.id)
                }}
              >
                <CloseOutlined />
              </button>
            </div>
          )
        })}
      </div>
    </div>
  )
}

export default PageTabs
