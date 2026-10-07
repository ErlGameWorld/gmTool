import axios from 'axios'

/** 统一给业务请求挂 Bearer；401 清登录态并回登录页 */
axios.interceptors.request.use((config) => {
  const token = localStorage.getItem('gm_token')
  if (token) {
    config.headers = config.headers || {}
    if (!config.headers.Authorization && !config.headers.authorization) {
      config.headers.Authorization = `Bearer ${token}`
    }
  }
  return config
})

axios.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      const url = String(err.config?.url || '')
      if (!url.includes('/auth/login')) {
        localStorage.removeItem('gm_token')
        localStorage.removeItem('gm_user')
        localStorage.removeItem('gm_token_expiry')
        if (!window.location.pathname.includes('/login')) {
          window.location.href = '/login'
        }
      }
    }
    return Promise.reject(err)
  }
)

export default axios
