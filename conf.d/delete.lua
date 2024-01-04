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

local pcallStatus, pcallResult = pcall(function()

    local name = args["name"];

    -- check args
    if not name then
        common.result('name is empty', 4)
        return
    end

    -- 空字符串
    if name == '' then
        common.result('name is empty', 4)
        return
    end

    -- 删除文件
    local rollback, err = common.deleteConf(name);

    if not rollback then
        common.result(err, 2)
        return
    end

    -- 重启服务
    local reloadStatus, reloadResult = common.reloadNginx();

    if not reloadStatus then
        -- 删除文件
        local suc, err = rollback();
        if not suc then
            common.result(err, 2)
            return
        end
        common.result(string.format("reload nginx failed: %s", reloadResult), 7)
        return
    end

    common.result("success", 0, result)

end)

ngx.log(ngx.INFO, string.format('pcall result %s, status %s', pcallResult, pcallStatus))

-- 解锁
local unlockOk, unlockErr = lock:unlock()

ngx.log(ngx.INFO, string.format('unlock result %s, status %s', unlockErr, unlockOk))
