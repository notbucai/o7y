# o7y

api形式的nginx配置的crud，基于openresty + lua。轻量、无额外依赖。

## 接口文档

1. POST /openapi/replace 创建和修改配置
```json
{
  "name": "ccc.conf",
  "content": "{...}"
}
```

2. DELETE /openapi/delete 删除配置
```json
{
  "name": "ccc.conf"
}
```

3. GET /openapi/content?name=xxx.conf 配置详情




