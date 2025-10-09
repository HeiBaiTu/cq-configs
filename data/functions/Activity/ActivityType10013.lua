module("ActivityType10013", package.seeall)

--[[
    个人活动（玩法），超玩会员
    
    个人数据：SupperVIPeople
    {
        isVip = true/false 是否是会员
       lastTime = 0 上一次初始化的时间戳
       v1_v3Gift  = 00000000 32位 是否领取第n个v1-v3礼包
       dailyGift = 00000000 32位 是否领取第n个每日礼包
    }
]]--

--活动类型
ActivityType = 10013
--对应的活动配置
ActivityConfig = GameVIPConfig
if ActivityConfig == nil then
    assert(false)
end

local HttpStatus =
{
    Success = "200", -- 成功
    ArgError = "302", -- 参数错误
    SignError = "304", -- 签名错误
    LinkLost = "305", -- 链接失效
    IpLimit = "306", -- IP受限
    AccountNotExits = "600", -- 账号不存在
    UnKnownedError = "299", -- 未知错误
}

-- 服务接口
Host = ActivityConfig.host or "proxy.udblogin.game.yy.com"
Port = ActivityConfig.port or "80"
Api = ActivityConfig.api or "/query/cwVipInfo.do"

function getData(pActor)
    local var = Actor.getStaticVar(pActor)
    if var.SupperVIPeople== nil then
        var.SupperVIPeople = {}
    end
    return var.SupperVIPeople
end

function SendData(pActor)
    local npack = DataPack.allocPacket(pActor, enActivityID, sSupperVipData)
    if npack then
        local data = getData(pActor)
        DataPack.writeUInt(npack, (data.v1_v3Gift or 0))
--print("v1-v3 giftbit : "..(data.v1_v3Gift or 0 ) )
        DataPack.writeUInt(npack, (data.dailyGift or 0))
--print("daily giftbit : "..(data.dailyGift or 0))
        DataPack.flush(npack)
    end
end

function AfterCheckSupperLogin(paramPack,content,result)
    local aid = paramPack[1]
    local pActor = Actor.getActorById(aid)
    if not pActor then
        --print("[AfterCheckSupperLogin][" .. aid .. "] 已离线")
        return
    end
    --print("[AfterCheckSupperLogin][" .. Actor.getName(pActor) .. "] content:"..content)
    --print("[AfterCheckSupperLogin]result:"..result)

    if Actor.getEntityType(pActor) ~= enActor then 
        return 
    end 

    --先清buff
    for i = 1 , #ActivityConfig.GameVIPbuff do
        Actor.delBuffById(pActor, (ActivityConfig.GameVIPbuff[i].buffid or 0))
    end 

    local data = getData(pActor)

    if result == 0 then
        local status = string.match(content,"\"status\":(%d+)")
        if status == HttpStatus.Success then
            local vipLevel = string.match(content,"\"vipLevel\":(%d+)")
            vipLevel = tonumber(vipLevel)
            Actor.setUIntProperty(pActor,PROP_ACTOR_SUPPER_PLAY_LVL,vipLevel)
            Actor.updateActorEntityProp(pActor)
            --local grade = string.match(content,"\"grade\":(%d+)")
            --local endTime = string.match(content,"\"endTime\":(%a+)")
            data.isVip = 1

            --加超玩特权buff 
            if(vipLevel >= 9) then
                Actor.addBuffById(pActor, (ActivityConfig.GameVIPbuff[3].buffid or 0))
            elseif (vipLevel >= 6) then
                Actor.addBuffById(pActor, (ActivityConfig.GameVIPbuff[2].buffid or 0))
            elseif (vipLevel >= 2) then
                Actor.addBuffById(pActor, (ActivityConfig.GameVIPbuff[1].buffid or 0))
            end 

        else 
            data.isVip = 0
            Actor.setUIntProperty(pActor,PROP_ACTOR_SUPPER_PLAY_LVL,0)
            Actor.updateActorEntityProp(pActor)
        end
        
    end
    SendData(pActor)
end

--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

function OnSupperLogin(pActor)
    local account = Actor.getAccount(pActor)
    local aid = Actor.getActorId(pActor)
    local now_milli = os.time()*1000
    local gameflag = System.getGameFlag() or "DDCQ"
    local key = System.getYYKey()
    local sign = System.MD5(gameflag,account,now_milli,key)
    local req = Api..'?game='..gameflag..'&account='..account..'&ts='..now_milli.."&sign="..string.upper(sign)
    --print("Require OnSupperLogin[" .. Actor.getName(pActor) .. "] : ".. req)
    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        AfterCheckSupperLogin,
        {aid}
    )
    
    -- 当天初始化
    local currMiniTime = System.getCurrMiniTime()
    local data = getData(pActor)
    if data.lastTime == nil then
        data.lastTime = currMiniTime
        --print("第一天")
    else
        if not System.isSameDay(data.lastTime, currMiniTime) then
            data.lastTime = currMiniTime
        end
    end
end

--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------

--v1-v3等级礼包
function OnReqSuperVipV1_V3(pActor, packet)
    local idx = DataPack.readByte(packet)
    if idx > #ActivityConfig.vipGift or idx <= 0  then
        return
    end
    local conf = ActivityConfig.vipGift[idx]
    local myLevel = Actor.getIntProperty(pActor, PROP_ACTOR_SUPPER_PLAY_LVL)

    --一级玩家增加领取范围
    if myLevel ==1 then 
        myLevel = 2
    end 

    local data = getData(pActor)

    if data.isVip == 0 then 
        return 
    end 
    if conf and data.lastTime then
        -- 领取检查
        if not data.v1_v3Gift then
            data.v1_v3Gift = 0
        end
        local flag = System.getIntBit(data.v1_v3Gift, idx-1)
        if flag == 1 then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
            return
        end
        -- 等级检查
        if myLevel < idx then
            return
        end

        --消耗
        --CommonFunc.Consumes.Remove(pActor, consumes, GameLog.Log_Activity10013, "super Player v1-v3")

        --记录日志
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,1) 

        --获取
        local aid = Actor.getActorId(pActor)
        local awards = conf
        SendMail(aid, ActivityConfig.VIPTitle, ActivityConfig.VIPContent, awards)

        --记录日志
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,2) 
        -- 设置标志
        data.v1_v3Gift = System.setIntBit(data.v1_v3Gift, idx-1, true)
        SendData(pActor)
    end

end 


-- 每日礼包，初中高级
function OnReqSuperVipDaily(pActor, packet)
    local idx = DataPack.readByte(packet)
    if idx > #ActivityConfig.dailyGift or idx <= 0 then
        return
    end
    local conf = ActivityConfig.dailyGift[idx]

    local myLevel = Actor.getIntProperty(pActor, PROP_ACTOR_SUPPER_PLAY_LVL)
    
    local data = getData(pActor)

    if data.isVip == 0 then 
        return 
    end 

    if conf and data.lastTime then
        -- 领取检查
        if not data.dailyGift then
            data.dailyGift = 0
        end
        local flag = System.getIntBit(data.dailyGift, idx-1)
        if flag == 1 then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
            return
        end

        -- 等级检查
        if myLevel < ActivityConfig.vipMap[idx] then
            return
        end

        --记录日志
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,1) 

        --获取
        local aid = Actor.getActorId(pActor)
        local awards = conf
        SendMail(aid, ActivityConfig.VIPDailyTitle, ActivityConfig.VIPDailyContent, awards)

        --记录日志
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,2) 

        -- 设置标志
        data.dailyGift = System.setIntBit(data.dailyGift, idx-1, true)
        
        SendData(pActor)
    end

end 

NetmsgDispatcher.Reg(enActivityID, cReqSuperVipV1_V3, OnReqSuperVipV1_V3)
NetmsgDispatcher.Reg(enActivityID, cReqSuperVipDaily, OnReqSuperVipDaily)

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    local currMiniTime = System.getCurrMiniTime()
    local data = getData(pActor)
    if data.lastTime then
        if not System.isSameDay(data.lastTime, currMiniTime) then
            --print("跨一天")
            data.lastTime = currMiniTime
            data.dailyGift = 0
        end
        SendData(pActor)
    end
end

function OnUserLogout(pActor,actorId)
    --local pActor = Actor.getActorById(actorId)

    --离线就删除buff
    --没有对会员时间处理，上线是超玩就加buff，离线就删buff
    for i = 1 , #ActivityConfig.GameVIPbuff do
        Actor.delBuffById(pActor, (ActivityConfig.GameVIPbuff[i].buffid or 0))
    end 

end 




ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10013.lua")
ActorEventDispatcher.Reg(aeUserLogout, OnUserLogout, "ActivityType10013.lua")

