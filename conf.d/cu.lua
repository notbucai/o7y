local cjson = require 'cjson.safe';
local lock = require "resty.lock"
local common = require('common');

local method = ngx.req.get_method();
local args = ngx.req.get_uri_args();
local body_data = ngx.req.get_body_data();

-- 加锁
local lock = lock:new("cu_lock", {
    timeout = 0
})

if not lock then
    ngx.say("failed to create lock:", err)
    return
end

local elapsed, err = lock:lock("req_lock")

-- 如果有锁，就报错
if not elapsed then
    ngx.say("lock already acquired by other worker. ", err)
    return
end

local pcallStatus, pcallResult = pcall(function()
    -- post check
    if method ~= "POST" then
        -- ngx.say(cjson.encode({
        --     code = 1,
        --     msg = string.format("method(%s) not allowed", method)
        -- }));
        -- ngx.exit(ngx.HTTP_OK);
        common.result(string.format("method(%s) not allowed", method), 1)
        return
    end

    if not body_data then
        common.result('body data is empty', 2)
        return
    end

    ngx.log(ngx.INFO, string.format("body data %s", body_data));

    local body_json, err = cjson.decode(body_data);

    -- if
    if not body_json then
        ngx.log(ngx.ERR, string.format("Failed to parse body json data: %s, err: %s", body_data, err));

        -- ngx.say(cjson.encode({
        --     code = 3,
        --     msg = string.format("Failed to parse body json data: %s", err)
        -- }));
        -- ngx.exit(ngx.HTTP_OK);
        common.result(string.format("Failed to parse body json data: %s", err), 3)
        return
    end

    local name = body_json["name"];
    local content = body_json["content"];

    -- check args
    if not name then
        -- ngx.say(cjson.encode({
        --     code = 4,
        --     msg = string.format("name is empty")
        -- }));
        -- ngx.exit(ngx.HTTP_OK);
        common.result('name is empty', 4)
        return
    end

    -- check content
    if not content then
        -- ngx.say(cjson.encode({
        --     code = 5,
        --     msg = string.format("content is empty")
        -- }));
        -- ngx.exit(ngx.HTTP_OK);
        common.result('content is empty', 5)
        return
    end

    -- todo 写入文件 

    -- check nginx
    local status, result = common.checkNginx();
    -- 输出执行结果
    ngx.log(ngx.INFO, string.format("checkNginx output %s %s", result, status))

    if not status then
        -- todo 删除文件
        common.result(string.format("check nginx failed: %s", result), 6)
        return
    end
    -- todo 重启服务

    common.result('success');
end)

ngx.log(ngx.INFO, string.format('pcall result %s, status %s', pcallResult, pcallStatus))

-- 解锁，这步估计没啥用，因为上面已经exit了
local unlockOk, unlockErr = lock:unlock()


ngx.log(ngx.INFO, string.format('unlock result %s, status %s', unlockErr, unlockOk))
