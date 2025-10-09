module("ActivityType10012", package.seeall)

--[[
    个人活动（玩法），YY会员
    
    个人数据：YYVIPeople
    {
       isVip = true/false, 是否为YY会员
       grade = 0, vip等级
       endTime = 0, vip过期时间戳
       lastTime = 0 上一次初始化的时间戳
       newServerGift = 00000000 32位 是否领取第n个新服豪礼
       dailyGift = 00000000 32位 是否领取第n个每日礼包 
       weeklyGift = 00000000 32位 是否领取第n个每周礼包 
    }
]]--

--活动类型
ActivityType = 10012
--对应的活动配置
ActivityConfig = YYVIPConfig
PlatformConfig = YYVIPConfig
local PfId = System.getPfId()


if ActivityConfig == nil then
    assert(false)
end

local HttpStatus = {
    Success = "200", -- 成功
    ArgError = "302", -- 参数错误
    SignError = "304", -- 签名错误
    LinkLost = "305", -- 链接失效
    IpLimit = "306", -- IP受限
    AccountNotExits = "600", -- 账号不存在
    UnKnownedError = "299" -- 未知错误
}

-- 服务接口
Host = ActivityConfig.host or "proxy.udblogin.game.yy.com"
Port = ActivityConfig.port or "80"
Api = ActivityConfig.api or "/query/yyVipInfo.do"

function getData(pActor)
    local var = Actor.getStaticVar(pActor)
    if var.YYVIPeople== nil then
        var.YYVIPeople = {}
    end
    return var.YYVIPeople
end

function SendData(pActor) 
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [YYVIP] SendData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [YYVIP] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local npack = DataPack.allocPacket(pActor, enActivityID, sYYVipData)
    if npack then
        local data = getData(pActor)
        DataPack.writeByte(npack, (data.isVip or 0))        -- 是否为VIP 0否1是
        DataPack.writeByte(npack, (data.grade or 1))        -- vip等级
        DataPack.writeInt64(npack, (data.endTime or 0))     -- 过期时间戳
        DataPack.writeUInt(npack, (data.newServerGift or 0))-- 32位 是否领取第n个新服豪礼
        DataPack.writeUInt(npack, (data.dailyGift or 0))   -- 32位 是否领取第n个每日礼包
        DataPack.writeUInt(npack, (data.weeklyGift or 0))   -- 32位 是否领取第n个每周礼包
        DataPack.flush(npack)
    end
end

function AfterCheckYYLogin(paramPack,content,result)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [YYVIP] SendData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [YYVIP] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local aid = paramPack[1]
    local pActor = Actor.getActorById(aid)
    if not pActor then
        print("[AfterCheckYYLogin][" .. aid .. "] 已离线")
        return
    end
    print("[AfterCheckYYLogin][" .. Actor.getName(pActor) .. "] content:"..content)
    print("[AfterCheckYYLogin]result:"..result)

    if result == 0 then
        local status = string.match(content,"\"status\":(%d+)")
        if (status == HttpStatus.Success) then
            local isvip = string.match(content,"\"isVip\":(%a+)")
            local grade = string.match(content,"\"grade\":(%d+)")
            local endTime = string.match(content,"\"endTime\":(%a+)")
            if isvip == "true" then
                isvip = 1
            else
                isvip = 0
            end
            grade = tonumber(grade)
            if endTime ~= "null" then
                endTime = tonumber(endTime)
            else
                endTime = 0
            end
            local data = getData(pActor)
            data.isVip = isvip
            data.grade = grade
            data.endTime = endTime
            SendData(pActor)
        end
    end
end

--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

function OnYYLogin(pActor)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [YYVIP] SendData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [YYVIP] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local account = Actor.getAccount(pActor)
    local aid = Actor.getActorId(pActor)
    local now = os.time()
    local gameflag = System.getGameFlag() or "DDCQ"
    local key = System.getYYKey()
    local sign = System.MD5(gameflag,account,now,key)
    local req = Api..'?game='..gameflag..'&account='..account..'&ts='..now.."&sign="..string.upper(sign)
    print("Require OnYYLogin[" .. Actor.getName(pActor) .. "] : ".. req)
    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        AfterCheckYYLogin,
        {aid}
    )
    
    -- 当天初始化
    local currMiniTime = System.getCurrMiniTime()
    local data = getData(pActor)
    if data.lastTime == nil then
        data.lastTime = currMiniTime
        data.newServerGift = 0
        data.dailyGift = 0
        data.weeklyGift = 0
        --print("第一天")
    else
        if not System.isSameDay(data.lastTime, currMiniTime) then
            --print("跨一天")
            if System.isSameWeek(data.lastTime, currMiniTime) then
                --print("跨一周")
                data.weeklyGift = 0
            end
            data.lastTime = currMiniTime
            data.dailyGift = 0
        end
    end
end

--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------

function OnReqYYVIPNewSrvGift(pActor, packet)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [YYVIP] SendData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [YYVIP] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local idx = DataPack.readByte(packet)
    if idx > (2 * #ActivityConfig.newServerGift) then
        return
    end
    local confid = math.ceil(idx/2)
    local conf = ActivityConfig.newServerGift[confid]

    local istitle = (idx%2 == 1)

    idx = idx - 1
    local data = getData(pActor)

    if conf and data.lastTime then

        -- 领取检查
        if not data.newServerGift then
            data.newServerGift = 0
        end
        local flag = System.getIntBit(data.newServerGift, idx)
        print("newServerGift="..data.newServerGift.." flag="..flag)
        if flag == 1 then
            return
        end

        -- 等级检查
        if data.grade < conf.viplvl then
            return
        end

        --检测格子
        if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) ~= true then
            return
        end

        -- 设置标志
        data.newServerGift = System.setIntBit(data.newServerGift, idx, true)
        SendData(pActor)

        Actor.SendActivityLog(pActor,ActivityType,ActivityType,1)
        if istitle then
            local awards = {conf.title}
            CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity10012, "YYVIP NewSrvGift")
        else
            --获取
            local aid = Actor.getActorId(pActor)
            local awards = {conf.gift}
            SendMail(aid, ActivityConfig.nsTitle, ActivityConfig.nsContent, awards)
        end
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,2)
    end
end

function OnReqYYVIPDailyGift(pActor, packet)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [YYVIP] SendData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [YYVIP] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local idx = DataPack.readByte(packet)
    if idx > #ActivityConfig.dailyGift then
        return
    end
    local conf = ActivityConfig.dailyGift[idx]
    idx = idx - 1
    local data = getData(pActor)
    if conf and data.lastTime then
        -- 领取检查
        if not data.dailyGift then
            data.dailyGift = 0
        end
        local flag = System.getIntBit(data.dailyGift, idx)
        --print("dailyGift="..data.dailyGift.." flag="..flag)
        if flag == 1 then
            return
        end

        -- 等级检查
        if data.grade < conf.viplvl then
            return
        end
        
        -- 元宝检查
        local consumes = {{type=4,id=4,count=conf.yb}}
        if CommonFunc.Consumes.CheckActorSources(pActor, consumes, tstUI) ~= true then
            return
        end

        --消耗
        CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity10012, "YYVIP dailyGift | " .. ActivityType)

        -- 设置标志
        data.dailyGift = System.setIntBit(data.dailyGift, idx, true)
        SendData(pActor)
        
        --获取
        local aid = Actor.getActorId(pActor)
        local awards = {conf.item}
        SendMail(aid, ActivityConfig.dgTitle, ActivityConfig.dgContent, awards)
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,1)
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,2)
    end
end

function OnReqYYVIPWeeklyGift(pActor, packet)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [YYVIP] SendData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [YYVIP] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local idx = DataPack.readByte(packet)
    if idx > #ActivityConfig.weeklyGift then
        return
    end
    local conf = ActivityConfig.weeklyGift[idx]
    idx = idx - 1
    local data = getData(pActor)
    if conf and data.lastTime then
        -- 领取检查
        if not data.weeklyGift then
            data.weeklyGift = 0
        end
        local flag = System.getIntBit(data.weeklyGift, idx)
        --print("weeklyGift="..data.weeklyGift.." flag="..flag)
        if flag == 1 then
            return
        end

        -- 等级检查
        if data.grade < conf.viplvl then
            return
        end

        --检测格子
        if CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) ~= true then
            return
        end
        
        -- 元宝检查
        local consumes = {{type=4,id=4,count=conf.yb}}
        if CommonFunc.Consumes.CheckActorSources(pActor, consumes, tstUI) ~= true then
            return
        end

        --消耗
        CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity10012, "YYVIP WeeklyGift | " .. ActivityType)

        -- 设置标志
        data.weeklyGift = System.setIntBit(data.weeklyGift, idx, true)
        SendData(pActor)
        
        --获取
        CommonFunc.Awards.Give(pActor, awards, GameLog.Log_Activity10012, "YYVIP WeeklyGift | " .. ActivityType)

        --获取
        local aid = Actor.getActorId(pActor)
        local awards = {conf.gift}
        SendMail(aid, ActivityConfig.wgTitle, ActivityConfig.wgContent, awards)
        
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,1)
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,2)
    end
end

NetmsgDispatcher.Reg(enActivityID, cReqYYVIPNewSrvGift, OnReqYYVIPNewSrvGift)
NetmsgDispatcher.Reg(enActivityID, cReqYYVIPDailyGift, OnReqYYVIPDailyGift)
NetmsgDispatcher.Reg(enActivityID, cReqYYVIPWeeklyGift, OnReqYYVIPWeeklyGift)

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    if PfId ~= nil and PlatformConfig.SPID  ~= nil then  
        --print("[Tip] [YYVIP] SendData ---------------------PfId:"..PfId.."--- SPID:"..PlatformConfig.SPID)   
        if tostring(PfId) ~= tostring(PlatformConfig.SPID) then
            
            print("[Tip]  [YYVIP] [非本平台活动]")  
            return --非本平台活动
        end
    end
    local currMiniTime = System.getCurrMiniTime()
    local data = getData(pActor)
    if data.lastTime then
        if not System.isSameDay(data.lastTime, currMiniTime) then
            --print("跨一天")
            if not System.isSameWeek(data.lastTime, currMiniTime) then
                --print("跨一周")
                data.weeklyGift = 0
            end
            data.lastTime = currMiniTime
            data.dailyGift = 0
        end
        SendData(pActor)
    end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10012.lua")
