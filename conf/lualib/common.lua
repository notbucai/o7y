local cjson = require "cjson.safe"

local common = {};

function common.checkNginx()

    local checkPath = '/tmp/exec' -- 创建一个临时文件
    local checkCommand = '/usr/local/openresty/bin/openresty -t 2> ' .. checkPath

    ngx.log(ngx.INFO, string.format("checkCommand: %s", checkCommand));

    local eStatus, eTxt, eCode = os.execute(checkCommand)

    ngx.log(ngx.INFO, string.format("eStatus: %s, eTxt: %s, eCode: %s", eStatus, eTxt, eCode));

    -- 读取临时文件内容
    local checkFile = io.open(checkPath, 'r')
    local checkFileResult = checkFile:read('*a')
    checkFile:close()

    return eStatus, checkFileResult;

end

function common.result(msg, code, data)
    local result = {
        code = code or 0,
        msg = msg,
        data = data
    }
    ngx.say(cjson.encode(result));
    ngx.exit(ngx.HTTP_OK);
    return
end

return common;
