module("ActivityType10011", package.seeall)

--[[
    个人活动（玩法），YY大厅特权
    
    个人数据：YYHallAtv
    {
        yydata = 0 YY大厅身份 1平民2贵族3王室
       freshmanGift = 0/1 是否领取YY大厅新手礼包（0否，1是）
       lastLoginTime = 0 上一次通过YY大厅登录的时间戳
       loginDay = 1 通过YY大厅登录的累计天数
       loginGift = 00000000 32位 是否领取某天的登录礼包 
       levelGift = 00000000 32位 是否领取第n个等级礼包
       nobleGift = 00000000 32位 是否领取贵族礼包 1平民 2贵族 3王室
    }
]]--

--活动类型
ActivityType = 10011
--对应的活动配置
ActivityConfig = YYMemberConfig
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
Api = ActivityConfig.api or "/yy/lobbygift/query/queryInfo.do"

function getData(pActor)
    local var = Actor.getStaticVar(pActor)
    if var.YYHallAtv== nil then
        var.YYHallAtv = {}
    end
    return var.YYHallAtv
end

function SendData(pActor,lvldata)

    --对于lvldata不是 1 2 3 这三个指定数值的直接返回
    -- if not (lvldata and (lvldata ==1 or lvldata == 2  or lvldata == 3 )) then 
    --     return  
    -- end 

    local npack = DataPack.allocPacket(pActor, enActivityID, sYYHallData)
    if npack then
        local data = getData(pActor)
        data.yydata = lvldata
        DataPack.writeByte(npack, lvldata)  --YY身份 1平民 2贵族 3王室
        DataPack.writeByte(npack, (data.freshmanGift or 0)) --是否已领取YY大厅新手礼包 0否1是
        DataPack.writeShort(npack, (data.loginDay or 1))--通过YY大厅登录的天数
        DataPack.writeUInt(npack, (data.loginGift or 0))--登录礼包的领取标记 32 位
        DataPack.writeUInt(npack, (data.levelGift or 0))--等级礼包的领取标记 32 位
        DataPack.writeUInt(npack, (data.nobleGift or 0))--贵族礼包的领取标记 32 位
        DataPack.flush(npack)
    end
end

function AfterCheckYYHall(paramPack,content,result)
    local aid = paramPack[1]
    local pActor = Actor.getActorById(aid)
    if not pActor then
        print("[AfterCheckYYHall][" .. aid .. "] 已离线")
        return
    end
    print("[AfterCheckYYHall][" .. Actor.getName(pActor) .. "] content:"..content)
    print("[AfterCheckYYHall]result:"..result)

    if result == 0 then
        local data = string.match(content,"\"data\":(%d+)")
        local status = string.match(content,"\"status\":(%d+)")
        if status == HttpStatus.Success then
            SendData(pActor,tonumber(data))
        end
    end
end

--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

function OnYYHallLogin(pActor)
    local account = Actor.getAccount(pActor)
    local aid = Actor.getActorId(pActor)
    local now = os.time()
    local gameflag = System.getGameFlag() or "DDCQ"
    local key = System.getYYKey()
    local sign = System.MD5(gameflag,account,"1001",now,key)
    local req = Api..'?account='..account..'&game='..gameflag..'&taskId=1001&time='..now.."&sign="..string.upper(sign)
    print("Require YYHallLogin[" .. Actor.getName(pActor) .. "] : ".. req)
    AsyncWorkDispatcher.Add(
        {'GetHttpContent',Host,Port,req},
        AfterCheckYYHall,
        {aid}
    )
    
    -- 当天初始化
    local data = getData(pActor)
    if data.lastLoginTime == nil then
        data.lastLoginTime = System.getCurrMiniTime()
        data.loginDay = 1
        --print("第一天")
    else
        if not System.isSameDay(data.lastLoginTime, System.getCurrMiniTime()) then
            --print("跨一天")
            data.lastLoginTime = System.getCurrMiniTime()
            data.loginDay = data.loginDay + 1
        end
    end
end

--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------

function OnReqYYHallFreshManGift(pActor, packet)
    local idx = DataPack.readByte(packet)
    local awards = ActivityConfig.freshmanGift
    local data = getData(pActor)
    local aid = Actor.getActorId(pActor)
    if data.lastLoginTime then
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,1) 
        if (data.freshmanGift == nil) or (data.freshmanGift == 0) then
            data.freshmanGift = 1
            SendMail(aid, ActivityConfig.fgTitle or "YY大厅新手礼包", ActivityConfig.fgContent or "恭喜你领取了YY大厅新手礼包！", ActivityConfig.freshmanGift)
            SendData(pActor,data.yydata)
        end
        Actor.SendActivityLog(pActor,ActivityType,ActivityType,2)
    end
end

function OnReqYYHallLoginGift(pActor, packet)
    local idx = DataPack.readByte(packet)
    if (idx > 30) or (idx == 0) then
        return
    end
    if idx > #ActivityConfig.loginGift then
        return
    end
    local awards = ActivityConfig.loginGift[idx]
    idx = idx - 1
    local data = getData(pActor)
    if awards and data.lastLoginTime then
        -- 领取检查
        if not data.loginGift then
            data.loginGift = 0
        end
        local flag = System.getIntBit(data.loginGift, idx)
        --print("loginGift="..data.loginGift.." flag="..flag)
        if flag == 1 then
            return
        end
        -- 天数检查
        if data.loginDay and (data.loginDay > idx )then
            Actor.SendActivityLog(pActor,ActivityType,ActivityType,1) 
            local aid = Actor.getActorId(pActor)
            data.loginGift = System.setIntBit(data.loginGift, idx, true)
            local mailcontent = string.format( ActivityConfig.logContent or "你已通过YY大厅登录超过了%d天，领取了YY大厅登录礼包！" , data.loginDay)
            SendMail(aid, ActivityConfig.logTitle or "YY大厅登录礼包", mailcontent, awards)
            SendData(pActor,data.yydata)
            Actor.SendActivityLog(pActor,ActivityType,ActivityType,2) 
        end
    end
end

function OnReqYYHallLevelGift(pActor, packet)
    local idx = DataPack.readByte(packet)
    if idx > #ActivityConfig.levelGift then
        return
    end
    local conf = ActivityConfig.levelGift[idx]
    local awards = conf.awards
    idx = idx - 1
    local data = getData(pActor)
    if conf and data.lastLoginTime then
        -- 领取检查
        if not data.levelGift then
            data.levelGift = 0
        end
        local flag = System.getIntBit(data.levelGift, idx)
        if flag == 1 then
            return
        end
        -- 等级检查
        local lvl = Actor.getIntProperty(pActor,PROP_CREATURE_LEVEL)
        if lvl >= conf.lvl then
            Actor.SendActivityLog(pActor,ActivityType,ActivityType,1) 
            local aid = Actor.getActorId(pActor)
            data.levelGift = System.setIntBit(data.levelGift, idx, true)
            local mailcontent = string.format( ActivityConfig.lvgContent or "你的等级已达到了%d级，领取了YY大厅等级礼包！" , conf.lvl)
            SendMail(aid, ActivityConfig.lvgTitle or "YY大厅等级礼包", mailcontent, awards)
            SendData(pActor,data.yydata)
            Actor.SendActivityLog(pActor,ActivityType,ActivityType,2) 
        end
    end
end

YYIdentity = {[1]="平民",[2]="贵族",[3]="王室"}

function OnReqYYHallNobleGift(pActor, packet)
    local idx = DataPack.readByte(packet)
    if idx > #ActivityConfig.nobleGift then
        return
    end
    if idx > #YYIdentity then
        return
    end
    local awards = ActivityConfig.nobleGift[idx]
    idx = idx - 1
    local data = getData(pActor)
    if awards and data.lastLoginTime then
        -- 领取检查
        if not data.nobleGift then
            data.nobleGift = 0
        end
        local flag = System.getIntBit(data.nobleGift, idx)
        if flag == 1 then
            return
        end
        -- 身份检查
        if data.yydata > idx then
            Actor.SendActivityLog(pActor,ActivityType,ActivityType,1)
            local aid = Actor.getActorId(pActor)
            data.nobleGift = System.setIntBit(data.nobleGift, idx, true)
            local mailcontent = string.format( ActivityConfig.ngContent or "你的身份为%s，领取了YY大厅贵族礼包！" , YYIdentity[idx+1])
            SendMail(aid, ActivityConfig.ngTitle or "YY大厅等级礼包", mailcontent, awards)
            SendData(pActor,data.yydata)
            Actor.SendActivityLog(pActor,ActivityType,ActivityType,2) 
        end
    end
end

NetmsgDispatcher.Reg(enActivityID, cReqYYHallFreshManGift, OnReqYYHallFreshManGift)
NetmsgDispatcher.Reg(enActivityID, cReqYYHallLoginGift, OnReqYYHallLoginGift)
NetmsgDispatcher.Reg(enActivityID, cReqYYHallLevelGift, OnReqYYHallLevelGift)
NetmsgDispatcher.Reg(enActivityID, cReqYYHallNobleGift, OnReqYYHallNobleGift)

--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------

-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    local currMiniTime = System.getCurrMiniTime()
    local data = getData(pActor)
    if data.lastLoginTime then
        if not System.isSameDay(data.lastLoginTime, System.getCurrMiniTime()) then
            data.lastLoginTime = System.getCurrMiniTime()
            data.loginDay = data.loginDay + 1
        end

        SendData(pActor,data.yydata)
    end
end

function OnUserLogout(pActor,actorId)
    if pActor ==nil then return end 
    local data = getData(pActor)
    data.yydata =nil 
end 

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10011.lua")
ActorEventDispatcher.Reg(aeUserLogout, OnUserLogout, "ActivityType10011.lua")
