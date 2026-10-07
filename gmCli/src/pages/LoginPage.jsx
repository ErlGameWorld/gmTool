import React, { useState } from 'react';
import { Form, Input, Button, message, Card, Space } from 'antd';
import { UserOutlined, LockOutlined } from '@ant-design/icons';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import './LoginPage.css';

const LoginPage = () => {
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { login } = useAuth();

  const onFinish = async (values) => {
    setLoading(true);
    try {
      // 表单验证
      if (!values.username || !values.password) {
        message.error('请输入用户名和密码');
        return;
      }
      
      if (values.username.length < 2) {
        message.error('用户名至少2个字符');
        return;
      }
      
      if (values.password.length < 5) {
        message.error('密码至少5个字符');
        return;
      }

      const result = await login(values.username, values.password);
      
      if (result.success) {
        message.success('登录成功');
        // 跳转到根路径，ProtectedRoute会自动处理重定向
        navigate('/', { replace: true });
      } else {
        message.error(result.message || '登录失败，请检查用户名和密码');
      }
    } catch (error) {
      message.error('网络错误，请检查网络连接后重试');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <Card className="login-card" title="GM工具">
        <Form
          name="login"
          className="login-form"
          initialValues={{ remember: true }}
          onFinish={onFinish}
          size="large"
        >
          <Form.Item
            name="username"
            rules={[{ required: true, message: '请输入用户名!' }]}
          >
            <Input 
              prefix={<UserOutlined />} 
              placeholder="用户名" 
            />
          </Form.Item>
          
          <Form.Item
            name="password"
            rules={[{ required: true, message: '请输入密码!' }]}
          >
            <Input.Password
              prefix={<LockOutlined />}
              placeholder="密码"
            />
          </Form.Item>

          <Form.Item>
            <Button 
              type="primary" 
              htmlType="submit" 
              className="login-form-button"
              loading={loading}
              block
            >
              登录
            </Button>
          </Form.Item>
        </Form>
        
        <Space direction="vertical" style={{ width: '100%' }}>
          <div className="demo-accounts">
            <h4>演示账户：</h4>
            <p>管理员: admin / admin123</p>
            <p>GM用户: gm / gm123</p>
            <p>操作员: operator / op123</p>
          </div>
        </Space>
      </Card>
    </div>
  );
};

export default LoginPage;