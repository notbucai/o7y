local cjson = require 'cjson.safe';
local common = require('common');

local method = ngx.req.get_method();
local args = ngx.req.get_uri_args();
local body_data = ngx.req.get_body_data();

-- 加锁
local lock, err = common.lock();

if not lock then
    common.result(string.format("Failed to acquire the lock: %s", err), 1);
end

local bodyData, err = common.getReqConfigData();
if not bodyData then
    common.result(err, 3)
    return
end

local name = bodyData["name"];
local content = bodyData["content"];

local removeFile, err = common.writeConfig(name, content);

if not removeFile then
    common.result(err, 4)
    return
end

local status, result = common.checkNginx();

ngx.log(ngx.INFO, string.format("status: %s, result: %s", status, result));

-- 删除文件
local suc, err = removeFile();

if not suc then
    common.result(err, 2)
    return
end

if not status then
    common.result(result, 5)
    return
end

common.result("success", 0, result)
