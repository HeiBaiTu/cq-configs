module("NewCdkey", package.seeall)
--[[
    游戏猫激活码功能

    个人数据：NewCdKeyData
    {
        lastTime,上次使用时间
        codeTimes = 
        {
            [id1], 礼包id1的使用次数
            [id2],
        }
    }
]]--

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

--local NewCdkeyServiceConf={ 
--    PfId = "1",
--    host = "fgtest.bigrnet.com",--这里不能带http://
--    port = "80",
--    url = "/H5CQ/develop/Service/CheckGiftCodeYXM.php", 
--}

--NewCdkeyAwards = {{type=0,id=261,count=5},{type=0,id=269,count=1},{type=7,id=7,count=20},{type=2,id=2,count=100000},}

local PfId = System.getPfId()
local SrvId = System.getServerId()

local ServiceConf = AutoCdkeyServiceConfig[PfId]
--local ServiceConf = NewCdkeyServiceConf

--配置的服务检测
function OnCheckCanPlatform()
    print("[DEBUG] OnCheckCanPlatform")
    -- 平台验证
    if not PfId then
        print("[ERR][CdKey YXM]1 load AutoCdkeyServiceConfig error! ")  
        return false
    end 
    if ServiceConf == nil then 
        print("[ERR][CdKey YXM]2 load AutoCdkeyServiceConfig error! ")  
        return false
    end
    if ServiceConf.host == nil then
        print("[ERR][CdKey YXM]3 load AutoCdkeyServiceConfig error! ")  
        return false
    end
    if ServiceConf.port == nil then
        print("[ERR][CdKey YXM]4 load AutoCdkeyServiceConfig error! ")  
        return false
    end
    if ServiceConf.url == nil then
        print("[ERR][CdKey YXM]5 load AutoCdkeyServiceConfig error! ")  
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

--[[
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
--]]
-- 检测完CDKey后的回调
local function AfterCheckCDkeyNew(paramPack, content, result) 
    print("[DEBUG][CdKey YXM]1 AfterCheckCDkeyNew -------------------------content:"..tostring(content).."result:"..tostring(result))   
    local res = CODE_SUCCESS
    local actid = 0
    if (result == 0) then --有反馈
        --for mu_id in string.gmatch(content, "(%w+),*") do
        --    print('mu_id='..mu_id);
        --end

        local resPattern = "^(.*)(return_code%s*:%s)([^,]*)(.*)$"
        strCapture1, strCapture2, res, strCapture3, strCapture4 = string.match(content, resPattern)
        print("[CdKey YXM]1  -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(res).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4)) 
        local aidPattern = "^(.*)(aid%s*:%s)([^,]*)(.*)$"
        strCapture1, strCapture2, actid, strCapture3, strCapture4 = string.match(content, aidPattern)
        print("[CdKey YXM]1  -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(actid).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4))
        local cdkPattern = "^(.*)(cdk%s*:%s*)([^,]*)(.*)$"
        strCapture1, strCapture2, cdk, strCapture3, strCapture4 = string.match(content, cdkPattern)
        print("[CdKey YXM]1  -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(cdk).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4))
      
        if (res == "0") then --新key
 
            --邮件明不需要传了
            --local mailtitlePattern = "^(.*)(mailtitle%s*:%s*)([^,]*)(.*)$"
            --strCapture1, strCapture2, mailtitle, strCapture3, strCapture4 = string.match(content, mailtitlePattern)
            --print("[CdKey YXM]1  -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(mailtitle).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4))
           
            local mailtlistPattern = "^(.*)(maillist%s*:%s*[)([^]]*)(.*)$"
            strCapture1, strCapture2, maillist, strCapture3, strCapture4 = string.match(content, mailtlistPattern)
            print("[CdKey YXM]1  -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(maillist).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4))
     
            local Awards = {}
            local mailcount = 0
            for kid, kcount, ktype in string.gmatch(maillist, "{\"id\":\"(%d+)\",\"count\":(%d+),\"type\":(%d+)}") do 
                local item = {}
                item.type = ktype
                item.id = kid
                item.count = kcount
                table.insert(Awards, item)
                print("[CdKey YXM]kid, kcount, ktype param1:"..tostring(ktype).."|param2:"..tostring(kid).."|param3:"..tostring(kcount)) 
                mailcount = mailcount + 1
            end
    
            if mailcount == 0 then 
                print("[TIP][CdKey YXM]AfterCheckCDkeyNew load mailconfig error! ---content is:"..tostring(content))   
                return
            end 
    
            -- 获取结果
            --res,actid,cdk,mailtitle = string.match(content, "(%d+),(%d+),(%a+),(%a+) ")
            print("[CdKey YXM]1 AfterCheckCDkeyNew param-------------------------res:"..tostring(res).."|actid:"..tostring(actid).."|cdk:"..tostring(cdk).."|mailtitle:"..tostring(mailtitle)..":maillist:"..tostring(maillist))   
            res = tonumber(res)
            actid = tonumber(actid)
            if res ~= nil then
                if res == CODE_SUCCESS then
                    -- 发派奖励
                    --local conf = CDKeyConf[id]
                    --SendMail(aid, mailtitle or "兑换码", conf.mailcontent or "兑换码兑换成功！", conf.awards)
                    SendMail(actid, "系统邮件", "尊敬的玩家：感谢您的支持，请查收您的礼包奖励。", Awards)-- NewCdkeyAwards)
                    -- 记录使用
                    --local data = getActorData(pActor)
                    --data.codeTimes[id] = (data.codeTimes[id] or 0) + 1
                    --data.codeTypeTimes[giftid] = (data.codeTypeTimes[giftid] or 0) + 1
                end
            else
                res = CODE_HTTP
                print("[TIP] AfterCheckCDkeyNew : res("..res.."), content: "..content)
            end 
        elseif(res == "10")  then          
            cdkPattern = "^(.*)(cdk%s*:%s*)([^}]*)(.*)$"
            strCapture1, strCapture2, cdk, strCapture3, strCapture4 = string.match(content, cdkPattern)
            print("[CdKey YXM]1  -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(cdk).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4))
            
            -- 发派奖励
            local id = getCodeId(cdk) 
            print("[TIP]1022 check old UseCDKey : id = " .. id)
            local conf = CDKeyConf[id] 
            if conf == nil then
                return
            end 
            SendMail(actid, "系统邮件", "尊敬的玩家：感谢您的支持，请查收您的礼包奖励。", conf.awards)
        elseif(res == "20")  then-- 通码 
            --print("测试111")
            cdkPattern = "^(.*)(cdk%s*:%s*)([^}]*)(.*)$"
            strCapture1, strCapture2, cdk, strCapture3, strCapture4 = string.match(content, cdkPattern)
            print("[CdKey YXM]1  -------------------------param1:"..tostring(strCapture1).."|param2:"..tostring(strCapture2).."|param3:"..tostring(cdk).."|param4:"..tostring(strCapture3).."|param5:"..tostring(strCapture4))
             
            -- 发派奖励
            local conf = CommonCDKeyConf[cdk] 
            if conf == nil then  
                return
            end  
            SendMail(actid, "系统邮件", "尊敬的玩家：感谢您的支持，请查收您的礼包奖励。", conf.awards)

        elseif(res == "7")  then 
            print("[TIP] AfterCheckCDkeyNew : cdkey已经使用超过使用范围, content: "..content) 
        elseif(res == "8")  then 
            print("[TIP] AfterCheckCDkeyNew : cdkey不存在, content: "..content)
    
        elseif(res == "9")  then 
            print("[TIP] AfterCheckCDkeyNew : cdkey数量不够, content: "..content) 

        elseif(res == "2")  then 
            print("[TIP] AfterCheckCDkeyNew : cdkey不存在, content: "..content)
        elseif(res == "1")  then 
            print("[TIP] AfterCheckCDkeyNew : cdkey已经使用, content: "..content)
        elseif(res == "11")  then 
            print("[TIP] AfterCheckCDkeyNew : 危险账号，短时间访问, content: "..content)
        else 
            print("[TIP] AfterCheckCDkeyNew : cdkey不存在, content: "..content)
        end 
    else
        res = CODE_HTTP
        print("[ERROR] AfterCheckCDkeyNew : result("..result.."), content: "..content)
    end

    -- 回复使用结果
    --local npack = DataPack.allocPacket(pActor, enMiscSystemID, sUseCdkey)
    --if npack then
    --    DataPack.writeByte(npack, res)
    --    DataPack.flush(npack)
    --end
end

--使用激活码
function UseCDKey(pActor, code)
    print("[DEBUG] UseCDKey, code="..code)

    local id = getCodeId(code) 
    if CDKeyConf[id] == nil then    
        print("[ERR][YXM] getCodeId error : code = " .. code.." name="..Actor.getName(pActor))
        return 0
    end

    local limit = CDKeyConf[id].limits or 1  --礼包码限制数量
    return limit
end

--使用通码
function UseCommonCDKey(code, actorId)
    print("[DEBUG] UseCommonCDKey, code="..code)

    local conf = CommonCDKeyConf[code]
    if conf == nil then 
        print("[ERR][YXM] UseCommonCDKey:getCodeId error : code = " .. code)
        return
    end

    local limit = 1  --礼包码限制数量 通码只能使用一次

    return limit
    --local pActor = Actor.getActorById(actorId)
    --if pActor == nil then
    --    return
    --end

    --local data = getActorData(pActor)
    --local time = System.getCurrMiniTime()
    --if data.lastTime and data.lastTime >= time then
    --    Actor.sendTipmsg(pActor,"请求过快！")
    --    return
    --end
  
    -- 使用次数超过限制
    --if data.codeTimes[code] then
    --    if data.codeTimes[code] >= 1 then
    --        local npack = DataPack.allocPacket(pActor, enMiscSystemID, sUseCdkey)
    --        if npack then
    --            DataPack.writeByte(npack, CODE_LIMIT)
    --            DataPack.flush(npack)
    --        end
    --        return
    --    end
    --end

    -- 发派奖励
    -- local conf = CommonCDKeyConf[code]
    -- local aid = Actor.getActorId(pActor)

    -- SendMail(aid, conf.mailtitle or "兑换码", conf.mailcontent or "兑换码兑换成功！", conf.awards)

    -- 记录使用次数
    -- local data = getActorData(pActor)
    -- data.codeTimes[code] = (data.codeTimes[code] or 0) + 1
end

--是否是通码
function isCommonKey(code)
    if CommonCDKeyConf and CommonCDKeyConf[code] then
        return true
    end
    return false
end

-- 老的 客户端请求使用使用激活码
function OnUseOldCDKey(code, actorId)
    print("[DEBUG][Tip]2 check old UseCDKey : code = " .. code)

    local limit = 0
    if isCommonKey(code) then 
        limit = 1  --礼包码限制数量 通码只能使用一次 
        return limit
    else 
        if checkPfid(code) == false then --检测平台号 
            print("[TIP][YXM] UseCDKey: 不是老码  code = " .. code)
            --Actor.sendTipmsg(pActor,"非本平台的礼包码！")
            return limit
        end

        local id = getCodeId(code) 
        if CDKeyConf[id] == nil then    
            print("[ERR][YXM] getCodeId error : code = " .. code.." name="..Actor.getName(pActor))
            return limit
        end
        limit = CDKeyConf[id].limits or 1  --礼包码限制数量  
        return limit
    end

    return limit
end
 
function OnCheckOldCDKey(code, actorId)  
    print("[Tip]1 check old UseCDKey : code = " .. code)
 
    if isCommonKey(code) then  
        print("[Tip]1 check old111 isCommonKey : code = " .. code)
        return 2
    else 
        print("[Tip]1 check old112 isCommonKey : code = " .. code)
        if checkPfid(code) == false then --检测平台号  
            return 0 
        end

        local id = getCodeId(code) 
        print("[Tip]1022 check old UseCDKey : id = " .. id)
        if CDKeyConf[id] == nil then     
            return 0
        end 
        return 1
    end

    return 0
end

--------------------------------------------------------------------
-- CPP回调
-------------------------------------------------------------------- 
function OnCMDBackStageCdKey(packet) 
    if OnCheckCanPlatform() == false then
        return
    end

    local SrvId = DataPack.readInt(packet) 
    local actorId = DataPack.readInt(packet) 
    local sUseCdkey = DataPack.readString(packet)
    local sMailTitle = DataPack.readString(packet)
    print("[CdKey YXM] OnCMDBackStageCdKey() -------------------------------------"..tostring(actorId).."|"..tostring(SrvId).."|"..sUseCdkey)
 
    local ServiceConf = AutoCdkeyServiceConfig[PfId]
    --local ServiceConf = NewCdkeyServiceConf

    --配置的服务检测
    if ServiceConf == nil then 
        print("[ERR][CdKey YXM]load AutoCdkeyServiceConfig error! ")   
        return
    end
    if ServiceConf.host == nil then
        print("[ERR][CdKey YXM]load AutoCdkeyServiceConfig error! ")    
        return
    end
    if ServiceConf.port == nil then
        print("[ERR][CdKey YXM]load AutoCdkeyServiceConfig error! ")    
        return
    end
    if ServiceConf.url == nil then
        print("[ERR][CdKey YXM]load AutoCdkeyServiceConfig error! ")    
        return
    end 
    local ServiceHost = ServiceConf.host
    local ServicePort = ServiceConf.port
    local ServiceUrl = ServiceConf.url

    --local pActor = Actor.getActorById(actorId) 
    --print("[CdKey YXM] OnCMDBackStageCdKey() -------------------------------------"..Actor.getName(pActor))
     
    local isOld = 0
    local limit = 0

    local keyType = OnCheckOldCDKey(sUseCdkey, actorId)
    if keyType == 2 then 
        limit = 1
        isOld = 2
    elseif keyType == 1 then 
        limit = OnUseOldCDKey(sUseCdkey, actorId)
        isOld = 1
        print("[TIP][CdKey YXM]load OldCDKey Suc! ".. limit)   
    end
 
    ---local data = getActorData(pActor)
    --local time = System.getCurrMiniTime()
    --if data.lastTime and data.lastTime >= time then
    --    print("[CdKey YXM] 请求过快！ "..tostring(actorId).."|"..tostring(SrvId).."|"..sUseCdkey)
    --    return
    --end 
 
    --local req = ServiceUrl..'?pfid='..PfId..'&cdkey='..sUseCdkey..'&aid='..actorId..'&sid='..SrvId..'&mailtitle='..sMailTitle..'&limit='..limit..'&isOld='..isOld 
    local req = ServiceUrl..'?pfid='..PfId..'&cdkey='..sUseCdkey..'&aid='..actorId..'&sid='..SrvId..'&limit='..limit..'&isOld='..isOld
    print("[CdKey YXM] GetHttpContent -------------------------ServiceHost:"..tostring(ServiceHost))
    print("[CdKey YXM] GetHttpContent -------------------------ServicePort:"..tostring(ServicePort))
    print("[CdKey YXM] GetHttpContent -------------------------req:"..tostring(req))

    --加入异步工作 
    AsyncWorkDispatcher.Add(
        {'GetHttpContent', ServiceHost, ServicePort, req},
        AfterCheckCDkeyNew,
        {SrvId, actorId}
    )

    --[[ 
	local url111 = "/H5CQ/develop/Service/CheckGiftCodeLimit.php"
    ServiceUrl = url111
    local req = ServiceUrl..'?pfid='..'wyi2'..'&cdkey='..sUseCdkey..'&aid='..actorId..'&sid='..SrvId..'&account=111'..'&limit='..2 
    print("[CdKey YXM] GetHttpContent -------------------------ServiceHost:"..tostring(ServiceHost))
    print("[CdKey YXM] GetHttpContent -------------------------ServicePort:"..tostring(ServicePort))
    print("[CdKey YXM] GetHttpContent -------------------------req:"..tostring(req))

    --加入异步工作 
    AsyncWorkDispatcher.Add(
        {'GetHttpContent', ServiceHost, ServicePort, req},
        AfterCheckCDkeyNew,
        {SrvId, actorId}
    ) 
    -- ]]
end

--NetmsgDispatcher.Reg(enMiscSystemID, cUseNewCdkey, OnUseCDKey)
