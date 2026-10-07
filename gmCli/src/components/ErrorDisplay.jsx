import React from 'react';
import { Button, Input, Space, Table } from 'antd';
import { SearchOutlined, CopyOutlined } from '@ant-design/icons';
import { formatErrorData } from './FunctionPanel';
import ResultContent from './ResultContent';

const { Search } = Input;

const ErrorDisplay = ({ 
  error, 
  onSearch, 
  onCopyResult, 
  onShowRequestParams, 
  filteredData, 
  serverIndex = null 
}) => {
  const isGMServer = error.sendToGMServer;
  const displayData = filteredData !== null && filteredData !== undefined ? filteredData : error.data;
  
  return (
    <div className="result-panel" style={{ marginBottom: isGMServer ? 0 : 16 }}>
      <div className="result-title" style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        backgroundColor: '#fff2f0',
        border: '1px solid #ffccc7',
        borderRadius: '6px 6px 0 0',
        padding: '12px 16px'
      }}>
        <Space>
          <span style={{
            fontWeight: 500,
            color: '#ff4d4f'
          }}>
            {isGMServer 
              ? `GM服务器 - 执行失败` 
              : `执行失败 (${error.timestamp})`
            }
          </span>
          {!isGMServer && (
            <span style={{ color: '#666', fontSize: '12px' }}>
              {error.timestamp}
            </span>
          )}
          {error.request && (
            <Button
              type="default"
              size="small"
              onClick={onShowRequestParams}
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
          )}
        </Space>
        <Space>
          {/* 搜索功能 */}
          <Search
            placeholder="搜索数据"
            size="small"
            style={{ width: 150 }}
            enterButton={<SearchOutlined />}
            onSearch={onSearch}
          />
          {/* 复制功能 */}
          <Button
            type="primary"
            size="small"
            icon={<CopyOutlined />}
            onClick={onCopyResult}
          >
            复制结果
          </Button>
        </Space>
      </div>
      <ResultContent style={{
        padding: '16px',
        border: '1px solid #e8e8e8',
        borderTop: 'none',
        borderRadius: '0 0 6px 6px',
        color: '#ff4d4f'
      }}>
        {/* 如果已搜索（包括空结果），优先显示搜索结果 */}
        {filteredData !== null && filteredData !== undefined ? (
          <div>
            {filteredData.length > 0 ? (
              <div>
                <div>搜索结果:</div>
                <pre style={{ whiteSpace: 'pre-wrap', fontSize: '12px', marginTop: 8 }}>
                  {formatErrorData(filteredData)}
                </pre>
                <div style={{ marginTop: 8, color: '#1890ff', fontSize: '12px' }}>
                  已筛选出 {filteredData.length} 条记录
                </div>
              </div>
            ) : (
              <div>
                <div>搜索结果: 未找到匹配内容</div>
                <div style={{ marginTop: 8, color: '#1890ff', fontSize: '12px' }}>
                  已筛选出 0 条记录
                </div>
              </div>
            )}
          </div>
        ) : (
          <div>
            {error.data ? (
              // 表格数据展示 - 失败时也检查数据类型
              error.data?.data?.type === 'table' ? (
                <div className="result-table-wrap">
                  <Table
                    dataSource={error.data.data.dataSource?.map((item, index) => ({
                      ...item,
                      key: item.key || item.id || `row-${index}`
                    }))}
                    columns={error.data.data.columns || []}
                    pagination={false}
                    size="small"
                    bordered
                    scroll={{
                      x: 'max-content',
                      y: (error.data.data.dataSource?.length || 0) > 8
                        ? 'max(280px, calc(100vh - 340px))'
                        : undefined
                    }}
                  />
                  {error.data.data.total && (
                    <div style={{ marginTop: 8, color: '#666', fontSize: '12px' }}>
                      共 {error.data.data.total} 条记录
                    </div>
                  )}
                </div>
              ) : (
                <pre style={{ whiteSpace: 'pre-wrap', fontSize: '12px' }}>
                  {formatErrorData(displayData)}
                </pre>
              )
            ) : (
              <div>错误信息: {error.message}</div>
            )}
          </div>
        )}
      </ResultContent>
    </div>
  );
};

export default ErrorDisplay;