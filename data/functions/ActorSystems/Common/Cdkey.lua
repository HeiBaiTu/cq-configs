--[[
    激活码功能

    个人数据：CdKeyData
    {
        lastTime,上次使用时间
        codeTimes = 
        {
            [id1], 礼包id1的使用次数
            [id2],
        }
    }

    
[60] = {
	Id = 60,
	awards = {{type=0,id=1270,count=1},{type=0,id=1271,count=1}},
	limits = 1,
	mailtitle = "VIP进游礼包",
	mailcontent = "礼包兑换成功，这是为您准备的礼包，请收好",
	switch = 1,
},
[61] = {
	Id = 61,
	awards = {{type=0,id=1242,count=33},{type=0,id=388,count=1},{type=0,id=1248,count=10}},
	limits = 1,
	mailtitle = "特权资源礼包",
	mailcontent = "礼包兑换成功，这是为您准备的礼包，请收好",
	switch = 1,
},

]]

local CODE_SUCCESS = 0	    -- 成功
local CODE_INVALID = 1      -- 已被使用
local CODE_NOTEXIST = 2     -- 不存在
local CODE_USED = 3 	    -- 已使用过同类型
local CODE_ERR = 4		    -- SQL查询错误
local CODE_TIME = 5		    -- 未到使用时间
local CODE_TIMEEXPIRE = 6   -- 礼包码过期了
local CODE_HTTP = 11        -- HTTP接口错误
local CODE_PF = 12          -- 非本平台礼包码
local CODE_LIMIT = 13       -- 使用次数超过限制

local PfId = System.getPfId()
local SrvId = System.getServerId()
local ServiceConf = CdkeyServiceConf[PfId]

--配置的服务检测
function OnCheckCanPlatform()
    -- 平台验证
    if not PfId then
        print("[ERR][CdKey old]0 load CdkeyServiceConfig error! ")
        return false
    end 
    if ServiceConf == nil then 
        print("[ERR][CdKey old]1 load CdkeyServiceConfig error! ")
        return false
    end
    if ServiceConf.host == nil then
        print("[ERR][CdKey old]2 load CdkeyServiceConfig error! ")
        return false
    end
    if ServiceConf.port == nil then
        print("[ERR][CdKey old]3 load CdkeyServiceConfig error! ")
        return false
    end
    if ServiceConf.url == nil then
        print("[ERR][CdKey old]4 load CdkeyServiceConfig error! ")
        return false
    end  
    return true
end
-- 根据 CDKey 获取礼包码id
local function getCodeId(code)
    local len = string.byte(string.sub(code, -1)) - 97
    local pos = string.byte(string.sub(code, -2,-2)) - 97
	local str = string.sub(code, pos + 1, pos + len)

	--print("gift code len :"..tostring(len))
    ---print("gift code pos :"..tostring(pos))
	--print("gift code str :"..tostring(str))

    local id = 0
    for i=1, string.len(str) do
        id = id * 10 + (math.abs(string.byte(string.sub(str, i, i)) - 97))
    end
    return id
end

-- 检测平台号
local function checkPfid(code)
    local pos = string.byte(string.sub(code, -2,-2)) - 97
    local str = string.sub(code, 1, pos)
    return str == PfId
end

-- 获取玩家的 CDKey 数据
local function getActorData(pActor)
    if Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.CdKeyData == nil then
        var.CdKeyData = {}
    end

    if not var.CdKeyData.codeTimes then
        var.CdKeyData.codeTimes = {}
    end

    return var.CdKeyData
end


-- 获取玩家的 CDKey 数据
function getActorCdkData(pActor)
    if Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.CdKeyData == nil then
        var.CdKeyData = {}
    end

    if not var.CdKeyData.codeTimes then
        var.CdKeyData.codeTimes = {}
    end
    if not var.CdKeyData.codeTypeTimes then
        var.CdKeyData.codeTypeTimes = {}
    end

    return var.CdKeyData
end

-- 检测完CDKey后的回调
local function AfterCheckCDkey(paramPack,content,result)
    print("[TIP] AfterCheckCDkey : content("..content.."), result: "..result)
    local aid = paramPack[1]
    local id = paramPack[2]
    local pActor = Actor.getActorById(aid)
    local res = CODE_SUCCESS
    local giftid = id
    if pActor and (result == 0) then
        -- 获取结果
        res,giftid = string.match(content, "(%d+),(%d+)")
        res = tonumber(res)
        giftid = tonumber(giftid)
        if res ~= nil then
            if res == CODE_SUCCESS then
                -- 发派奖励
                local conf = CDKeyConf[id]
                SendMail(aid, conf.mailtitle or "兑换码", conf.mailcontent or "兑换码兑换成功！", conf.awards)
                -- 记录使用
                local data = getActorData(pActor)
                data.codeTimes[id] = (data.codeTimes[id] or 0) + 1
                
                if not data.codeTypeTimes then
                    data.codeTypeTimes = {}
                end 
                data.codeTypeTimes[giftid] = (data.codeTypeTimes[giftid] or 0) + 1
            end
        else
            res = CODE_HTTP
            print("[ERROR] AfterCheckCDkey : res("..res.."), content: "..content)
        end
    else
        res = CODE_HTTP
        print("[ERROR] AfterCheckCDkey : result("..result.."), content: "..content)
    end

    -- 回复使用结果
    local npack = DataPack.allocPacket(pActor, enMiscSystemID, sUseCdkey)
    if npack then
        DataPack.writeByte(npack, res)
        DataPack.flush(npack)
    end
end

--使用激活码
function UseCDKey(pActor, code)
    print("[DEBUG] UseCDKey, code="..code)

    local ServiceHost = ServiceConf.host
    local ServicePort = ServiceConf.port
    local ServiceUrl = ServiceConf.url

    if checkPfid(code) == false then
        --Actor.sendTipmsg(pActor,"非本平台的礼包码！")
        -- 回复使用结果
        local npack = DataPack.allocPacket(pActor, enMiscSystemID, sUseCdkey)
        if npack then
            DataPack.writeByte(npack, CODE_PF)
            DataPack.flush(npack)
        end
        return
    end

    local data = getActorData(pActor)
    local time = System.getCurrMiniTime()
    if data.lastTime and data.lastTime >= time then
        Actor.sendTipmsg(pActor,"请求过快！")
        return
    end

    local id = getCodeId(code)
    
    if CDKeyConf[id] == nil then   
        Actor.sendTipmsg(pActor, "礼包码错误02！") 
        print("[ERROR] getCodeId error : code = " .. code.."id = " .. id.." name="..Actor.getName(pActor))
        return
    end
    local limit = CDKeyConf[id].limits or 1  --礼包码限制数量
    if data.codeTimes[id] then
        if data.codeTimes[id] >= limit then
            --Actor.sendTipmsg(pActor,"使用次数超过限制！")
            -- 回复使用结果
            local npack = DataPack.allocPacket(pActor, enMiscSystemID, sUseCdkey)
            if npack then
                DataPack.writeByte(npack, CODE_LIMIT)
                DataPack.flush(npack)
            end
            return
        end
    end

    --加入异步工作
    local account = Actor.getAccount(pActor)
    local aid = Actor.getActorId(pActor)

    local req = ServiceUrl..'?pfid='..PfId..'&cdkey='..code..'&aid='..aid..'&sid='..SrvId..'&account='..account..'&limit='..limit
    print("[TIP] [CdKey] GetHttpContent -------------------------ServiceHost:"..tostring(ServiceHost))
    print("[TIP] [CdKey] GetHttpContent -------------------------ServicePort:"..tostring(ServicePort))
    print("[TIP] [CdKey] GetHttpContent -------------------------req:"..tostring(req)) 

    print("[TIP] getCodeId error : code = " .. code.."id = " .. id.." name="..Actor.getName(pActor))
    AsyncWorkDispatcher.Add(
        {'GetHttpContent', ServiceHost, ServicePort, req},
        AfterCheckCDkey,
        {aid,id}
    )
end

--使用通码
function UseCommonCDKey(pActor, code)
    print("[DEBUG] UseCommonCDKey, code="..code)

    local data = getActorData(pActor)
    local time = System.getCurrMiniTime()
    if data.lastTime and data.lastTime >= time then
        Actor.sendTipmsg(pActor,"请求过快！")
        return
    end

    if CommonCDKeyConf[code].switch == 0 then
        local npack = DataPack.allocPacket(pActor, enMiscSystemID, sUseCdkey)
        if npack then
            DataPack.writeByte(npack, CODE_TIMEEXPIRE)
            DataPack.flush(npack)
        end
        return
    end

    -- 使用次数超过限制
    if data.codeTimes[code] then
        if data.codeTimes[code] >= 1 then
            local npack = DataPack.allocPacket(pActor, enMiscSystemID, sUseCdkey)
            if npack then
                DataPack.writeByte(npack, CODE_LIMIT)
                DataPack.flush(npack)
            end
            return
        end
    end

    -- 发派奖励
    local conf = CommonCDKeyConf[code]
    local aid = Actor.getActorId(pActor)
    SendMail(aid, conf.mailtitle or "兑换码", conf.mailcontent or "兑换码兑换成功！", conf.awards)

    -- 记录使用
    local data = getActorData(pActor)
    data.codeTimes[code] = (data.codeTimes[code] or 0) + 1

    -- 回复使用结果
    local npack = DataPack.allocPacket(pActor, enMiscSystemID, sUseCdkey)
    if npack then
        DataPack.writeByte(npack, CODE_SUCCESS)
        DataPack.flush(npack)
    end
end

--是否是通码
function isCommonKey(code)
    if CommonCDKeyConf and CommonCDKeyConf[code] then
        return true
    end
    return false
end

-- 客户端请求使用激活码
function OnUseCDKey(pActor, packet)
    print("[DEBUG] OnUseCDKey, PfId="..PfId)

    if OnCheckCanPlatform() == false then
        print("[DEBUG] OnUseCDKey, OnCheckCanPlatform() == false")
        return
    end

    local code = DataPack.readString(packet)
    print("[DEBUG][Tip] OnUseCDKey: code = " .. code)

    if isCommonKey(code) then
        UseCommonCDKey(pActor, code)
    else
        UseCDKey(pActor,code)
    end
end

NetmsgDispatcher.Reg(enMiscSystemID, cUseCdkey, OnUseCDKey)
