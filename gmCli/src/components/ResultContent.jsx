import React from 'react'

/**
 * 结果展示框容器。
 * 表格由 .result-table-wrap + ant Table scroll 在自身框内做上下/左右滚动。
 */
const ResultContent = ({ children, className = '', style, ...rest }) => (
  <div
    className={`result-content ${className}`.trim()}
    style={style}
    {...rest}
  >
    {children}
  </div>
)

export default ResultContent
