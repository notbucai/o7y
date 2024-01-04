# o7y

api形式的nginx配置的crud，基于openresty + lua。轻量、无额外依赖。

虽然加了一系列的兜底判断，但是还是不建议使用在生产环境。

## 接口文档

> 为了保证配置可靠性，所有接口共用一个锁，也就是所有接口总并发为1

> 所有操作都可能存在副作用！！！

1. POST /openapi/check 检查配置
```json
{
  "name": "ccc.conf",
  "content": "{...}"
}
```

2. POST /openapi/replace 创建和修改配置
```json
{
  "name": "ccc.conf",
  "content": "{...}"
}
```

3. DELETE /openapi/delete?name=xxx.conf 删除配置

4. GET /openapi/content?name=xxx.conf 配置详情




