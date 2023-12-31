local cjson = require 'cjson.safe';
local common = require('common');

local method = ngx.req.get_method();
local args = ngx.req.get_uri_args();
local body_data = ngx.req.get_body_data();

-- 加锁
local lock, err = common.lock();

if not lock then
    ngx.log(ngx.ERR, string.format("Failed to acquire the lock: %s", err));
    common.result(string.format("Failed to acquire the lock: %s", err), 2)
    return
end

local pcallStatus, pcallResult = pcall(function()

    local bodyData, err = common.getReqConfigData();
    if not bodyData then
        common.result(err, 3)
        return
    end

    local name = bodyData["name"];
    local content = bodyData["content"];

    -- 写入文件 
    local removeFile, err = common.writeConfig(name, content);

    if not removeFile then
        common.result(err, 4)
        return
    end

    -- check nginx
    local status, result = common.checkNginx();
    -- 输出执行结果
    ngx.log(ngx.INFO, string.format("checkNginx output %s %s", result, status))

    if not status then
        -- 删除文件
        local su, err
        removeFile()
        if not suc then
            common.result(err, 2)
            return
        end
        common.result(string.format("check nginx failed: %s", result), 6)
        return
    end
    -- 重启服务
    local reloadStatus, reloadResult = common.reloadNginx();

    if not reloadStatus then
        -- 删除文件
        local suc, err = removeFile();
        if not suc then
            common.result(err, 2)
            return
        end
        common.result(string.format("reload nginx failed: %s", reloadResult), 7)
        return
    end

    common.result('success', 0, reloadResult);
end)

ngx.log(ngx.INFO, string.format('pcall result %s, status %s', pcallResult, pcallStatus))

-- 解锁，这步估计没啥用，因为上面已经exit了
local unlockOk, unlockErr = lock:unlock()

ngx.log(ngx.INFO, string.format('unlock result %s, status %s', unlockErr, unlockOk))
