local limit_req = require "resty.limit.req"
--require 'resty.core.regex'

---------------- declare functions start ----------------------------------------------------
--string_split funciton return a table of strings
function string_split(delimiter, s)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function have_legal_identity()
    if ngx.var.cookie__identity == nil then
        return false
    end
    local identityData = string_split(",", ngx.var.cookie__identity)
    if table.getn(identityData) ~= 2 then
        return false
    end
    local secretyKey = "";
    if ngx.var.limit_identity_secret_key ~= nil then
        secretyKey = ngx.var.limit_identity_secret_key
    end
    if ngx.md5(identityData[1]..secretyKey) == identityData[2] then
        return true
    end
    return false
end

-- limit_request function check and limit rate of request
local function limit_request(rule, key)
    local conf = string_split(",", rule)
    if table.getn(conf) ~= 2 then
        ngx.log(ngx.ERR, "incorrect config: "..rule)
        return ngx.exit(500)
    end

    local lim, err = limit_req.new(ngx.var.limit_shared_dict_name, tonumber(conf[1]), tonumber(conf[2]))
    if not lim then
        ngx.log(ngx.ERR, "failed to instantiate a resty.limit.req object: ", err)
        return ngx.exit(500)
    end

    local delay, err = lim:incoming(key, true)
    if not delay then
        if err == "rejected" then
            return ngx.exit(503)
        end
        ngx.log(ngx.ERR, "failed to limit req:  ", err)
        return ngx.exit(500)
    end

    if delay > 0 then
        ngx.sleep(delay)
    end
end

---------------- declare functions end ----------------------------------------------------
if ngx.var.limit_shared_dict_name == nil then -- 没有配置limit_shared_dict_name
    return nil;
end

-- 是否在白名单
local matche_result, match_err;
if ngx.var.limit_white_ip ~= nil then
    matche_result, match_err = ngx.re.match(ngx.var.remote_addr, ngx.var.limit_white_ip, "jo")
    if matche_result then
        return
    end
end
if ngx.var.limit_white_uri ~= nil then
    matche_result, match_err = ngx.re.match(ngx.var.uri, ngx.var.limit_white_uri, "jo")
    if matche_result then
        return
    end
end

-- 检查频率
if ngx.var.limit_global ~= nil then
    limit_request(ngx.var.limit_global, 'global')
end

local legal_identity = have_legal_identity();
if legal_identity then
    limit_request(ngx.var.limit_itentity, ngx.var.cookie__identity)
end

if ngx.var.limit_ip ~= nil then
    local isIpLimitative = true;
    if legal_identity and ngx.var.limit_member_ip_relation ~= nil and ngx.var.limit_member_ip_relation == "or" then
        isIpLimitative = false;
    end
    if isIpLimitative then
        limit_request(ngx.var.limit_ip, ngx.var.remote_addr)
    end
end
