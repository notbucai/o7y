local cjson = require "cjson.safe"
local lock = require "resty.lock"

local common = {
    configPath = '/etc/nginx/conf.d/';
    lockRef = nil
};

function common.checkNginx()

    local checkPath = '/tmp/eheck' -- 创建一个临时文件
    local checkCommand = '/usr/local/openresty/bin/openresty -t 2> ' .. checkPath

    ngx.log(ngx.INFO, string.format("checkCommand: %s", checkCommand));

    local eStatus, eTxt, eCode = os.execute(checkCommand)

    ngx.log(ngx.INFO, string.format("eStatus: %s, eTxt: %s, eCode: %s", eStatus, eTxt, eCode));

    -- 读取临时文件内容
    local checkFile = io.open(checkPath, 'r')
    local checkFileResult = checkFile:read('*a')
    checkFile:close()

    ngx.log(ngx.INFO, string.format("checkFileResult: %s", checkFileResult));

    return eStatus, checkFileResult;

end

function common.result(msg, code, data)
    local result = {
        code = code or 0,
        msg = msg,
        data = data
    }
    -- unlock
    common.unlook();
    ngx.say(cjson.encode(result));
    ngx.exit(ngx.HTTP_OK);
    return
end

function common.unlook()
    -- unlock
    if common.lockRef then
        common.lockRef:unlock()
    end
end

function common.lock()
    -- 加锁
    local lock = lock:new("cu_lock", {
        timeout = 0
    })

    if not lock then
        return nil, err
    end

    local elapsed, err = lock:lock("req_lock")

    -- 如果有锁，就报错
    if not elapsed then
        return nil, err
    end

    common.lockRef = lock;

    return lock, nil

end

function common.getReqConfigData()

    local method = ngx.req.get_method();
    local args = ngx.req.get_uri_args();
    local body_data = ngx.req.get_body_data();

    -- post check
    if method ~= "POST" then
        return nil, string.format("method(%s) not allowed", method)
    end

    if not body_data then
        return nil, "body is empty"
    end

    ngx.log(ngx.INFO, string.format("body data %s", body_data));

    local body_json, err = cjson.decode(body_data);

    -- if
    if not body_json then
        ngx.log(ngx.ERR, string.format("Failed to parse body json data: %s, err: %s", body_data, err));
        -- common.result(string.format("Failed to parse body json data: %s", err), 3)
        return nil, string.format("Failed to parse body json data: %s", err)
    end

    local name = body_json["name"];
    local content = body_json["content"];

    -- check args
    if not name then
        return nil, 'name is empty'
    end

    -- 空字符串
    if name == '' then
        return nil, 'name is empty'
    end

    if name == 'o7y.conf' then
        return nil, 'name is not allowed'
    end

    -- check content
    if not content then
        return nil, 'content is empty'
    end

    -- 空字符串
    if content == '' then
        return nil, 'content is empty'
    end

    return body_json, nil

end

function common.writeConfig(filename, content)
    local configPath = common.configPath .. filename;
    local yyyyMMddHHmmss = os.date("%Y%m%d%H%M%S", os.time());
    local backupPath = configPath .. '.' .. yyyyMMddHHmmss;
    local backupFileExist = false;
    ngx.log(ngx.INFO, string.format("configPath: %s", configPath));
    -- write file
    local file = io.open(configPath, 'r');

    -- 判断文件是否存在
    if file then
        backupFileExist = true;
        -- rename
        file.close();
        os.rename(configPath, backupPath);
    end
    
    file = io.open(configPath, 'w');

    file:write(content);

    file:close();

    return function()
        -- 如果备份文件存在，就恢复
        if backupFileExist then
            return os.rename(backupPath, configPath);
        end
        return os.remove(configPath)
    end, nil
end

-- reloadNginx
function common.reloadNginx()

    local reloadLogPath = '/tmp/reload' -- 创建一个临时文件
    local reloadCommand = string.format('/usr/local/openresty/bin/openresty -s reload 2> %s', reloadLogPath)
    local eStatus, eTxt, eCode = os.execute(reloadCommand)

    ngx.log(ngx.INFO, string.format("eStatus: %s, eTxt: %s, eCode: %s", eStatus, eTxt, eCode));
    
    -- 读取临时文件内容
    local reloadFile = io.open(reloadLogPath, 'r')
    local reloadFileResult = reloadFile:read('*a')
    reloadFile:close()

    return eStatus, reloadFileResult;
end

-- delete file
function common.deleteConf(filename)

    -- 其实就是重命名
    -- 检查文件是否存在
    local configPath = common.configPath .. filename;
    local yyyyMMddHHmmss = os.date("%Y%m%d%H%M%S", os.time());
    local backupPath = configPath .. '.' .. yyyyMMddHHmmss;

    local file = io.open(configPath, 'r');

    if not file then
        return nil, string.format("file(%s) not exist", configPath)
    end

    -- rename
    file.close();
    local renameSuc, renameErr  = os.rename(configPath, backupPath);

    if not renameSuc then
        return nil, string.format("renameErr (%s)", renameErr)
    end

    return function ()
        -- 还原
        return os.rename(backupPath, configPath)
    end, nil
end


return common;
