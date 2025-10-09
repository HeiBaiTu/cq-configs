-- module("ActivityOnlineMin", package.seeall)
--[[
   
    累计在线
    
    个人数据：onlinedata
    {
        onlineTime --累计在线时间
        lastLoginTime --登录时间
        loginday--登录天数
        bitState --bit位
    }
]]--
OnlineCfg = OnlineTimeRewardConfig
OnlineTimeconst = OnlineTimeconstConfig 

--对应的活动配置
function getOnlineData(pActor)
    local var = Actor.getStaticVar(pActor)
    if var.onlinedata== nil then
        var.onlinedata = {}
    end
    return var.onlinedata
end

function SendOnlineData(pActor)
    local npack = DataPack.allocPacket(pActor, enMiscSystemID, sGetOnlineTime)
    if npack then
        local data = getOnlineData(pActor)
        if data.onlineTime == nil then
            data.onlineTime = 0;
        end
        data.onlineTime = (data.onlineTime or 0) + Actor.getTotalOnlineTime(pActor);
        -- print("SendOnlineData.."..data.onlineTime);
        -- local totalTime =  data.onlineTime + Actor.getTotalOnlineTime(pActor);
        DataPack.writeUInt(npack, (data.onlineTime or 0))--累计登录时间
        DataPack.writeUInt(npack, (data.loginday or 0))--累计天数
        DataPack.writeInt(npack, (data.bitState or 0))--礼包的领取标记 32 位
        DataPack.flush(npack)
    end
end

--------------------------------------------------------------------
-- 客户端请求协议回调
-------------------------------------------------------------------
function OnOnlineLogin(pActor)
    local data = getOnlineData(pActor);
    if data.lastLoginTime == nil then
        data.lastLoginTime = System.getCurrMiniTime()
        data.loginday =1
    end
    SendOnlineData(pActor);
end

function OnGetOlineTimeAward(pActor, packet)
    local ntype = DataPack.readByte(packet);
    local nIndex = DataPack.readInt(packet);
    local data = getOnlineData(pActor)
    if data == nil then
        return
    end
    -- print("ntype.."..ntype.."..nIndex.."..nIndex)
    local Cfg= OnlineCfg[ntype]
    if not Cfg or not Cfg[nIndex] then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无此奖励|", tstUI)
        return
    end
    local flag = System.getIntBit(data.bitState, nIndex-1)
    --print("loginGift="..data.levelGift.." flag="..flag)
    if flag == 1 then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:奖励已领取|", tstUI)
        return
    end
    if ntype == 1 then
        local totalTime = data.onlineTime + Actor.getTotalOnlineTime(pActor);
        if totalTime < Cfg[nIndex].onlineTimes then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:累计在线时间未到|", tstUI)
            return;
        end
    elseif ntype == 2 then
        if data.loginday < Cfg[nIndex].onlineTimes then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:累计登录未到|", tstUI)
            return
        end
    end

    if CommonFunc.Awards.CheckBagIsEnough(pActor,8,tmLeftBagNumNotEnough,tstUI) ~= true then
        return
    end
    data.bitState = System.setIntBit((data.bitState or 0), nIndex-1, true)
    -- print("nIndex.."..nIndex);
    CommonFunc.Awards.Give(pActor, Cfg[nIndex].reward, GameLog.Log_TotalOnlineTime)
    SendOnlineData(pActor)
end
--------------------------------------------------------------------
-- 玩家 回调注册
--------------------------------------------------------------------
-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    local currMiniTime = System.getCurrMiniTime()
    local data = getOnlineData(pActor)
    if data.lastLoginTime then
        if not System.isSameDay(data.lastLoginTime, System.getCurrMiniTime()) then
            data.lastLoginTime = System.getCurrMiniTime()
            data.loginday = data.loginday + 1
        end
        SendOnlineData(pActor)
    end
end

function UpdateOnlineTime(pActor,totalTime)
    -- local currMiniTime = System.getCurrMiniTime()
    
    if OnlineTimeconst.limit then
        if Actor.checkCommonLimit(pActor,
                                (OnlineTimeconst.limit.level or 0), 
                                (OnlineTimeconst.limit.zsLevel or 0),
                                (OnlineTimeconst.limit.vip or 0), 
                                (OnlineTimeconst.limit.office or 0) ) == false then

            return;
        end
    end
    local data = getOnlineData(pActor)
    data.onlineTime = (data.onlineTime or 0) + totalTime;
    -- print("UpdateOnlineTime.."..data.onlineTime.."..totalTime.."..totalTime);
    -- SendOnlineData(pActor);
end


ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityOnlineMin.lua")


NetmsgDispatcher.Reg(enMiscSystemID, cGetOnlineTime, OnOnlineLogin)
NetmsgDispatcher.Reg(enMiscSystemID, cGetOnlineAward, OnGetOlineTimeAward)