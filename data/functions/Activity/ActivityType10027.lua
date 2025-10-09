module("ActivityType10027", package.seeall)

--[[
    个人数据：userData
    {
        LoginType           = 0 or 1(盒子登录)
        ReqGiftMainType     = 0 ~ 3(1：盒子下载礼包(一次性)；2：实名认证奖励(一次性)；3：每日登录礼包；4：每日首充奖励和每日累计充值奖励)
        ReqSubGiftType1     =                    每日累充奖励Id
        OneDayRechargesYBNum=            ku25    每日累计充值元宝数
        BoxDownloadGiftFlag = 0 or 1     ku25    盒子下载礼包(一次性)
        RealNameAuthGiftFlag= 0 or 1     ku25    实名认证奖励(一次性)
        DailyLoginGiftFlag  = 0 or 1     ku25    每日登录礼包
        OneDayRechargesGiftFlag = 32位   ku25    每日首充奖励和每日累计充值奖励
        WeChatGiftFlag = 0 or 1          ku25    微信礼包码 礼包
    }
]]--


ActivityConfig = PlatformKU25Config      -- 其他礼包
ActivityDailyConfig = LoginKU25Config    -- 每日充值礼包


local PfId = System.getPfId()


function GetKu25UserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.Ku25UserData then
        var.Ku25UserData = {}
    end
    return var.Ku25UserData
end

-- 发送 ku25玩家数据
function SendKu25UserData(pActor)
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSendku25UserData)
    if npack then
        print("[Tip] ActivityType10027 SendKu25UserData")

        local userData = GetKu25UserData(pActor)

        DataPack.writeUInt(npack, userData.OneDayRechargesYBNum)
        DataPack.writeByte(npack, userData.BoxDownloadGiftFlag)
        DataPack.writeByte(npack, userData.RealNameAuthGiftFlag)
        DataPack.writeByte(npack, userData.DailyLoginGiftFlag)
        DataPack.writeUInt(npack, userData.OneDayRechargesGiftFlag)
        DataPack.writeByte(npack, userData.WeChatGiftFlag)
        DataPack.flush(npack)
    end
end

-- 发送 盒子下载 奖励
function SendBoxDownloadGift(pActor)
    print("[Tip] ActivityType10027 SendBoxDownloadGift")

    local userData = GetKu25UserData(pActor)
    if not userData.LoginType then
        print("[Tip] ActivityType10027 SendBoxDownloadGift not userData.LoginType")
        return 
    end

    if 1 == userData.BoxDownloadGiftFlag then
        print("[Tip] ActivityType10027 SendBoxDownloadGift already get BoxDownloadGift")
        return 
    end

    if not ActivityConfig or not ActivityConfig.BoxReward then
        print("[Tip] ActivityType10027 SendBoxDownloadGift not ActivityConfig or not ActivityConfig.BoxReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10027 SendBoxDownloadGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.BoxDownloadGiftFlag = 1

    CommonFunc.Awards.Give(pActor, ActivityConfig.BoxReward, GameLog.Log_Activity10027)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType1 = 0

    SendKu25UserData(pActor)
    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
end

-- 发送 实名认证奖励
function SendRealNameAuthGift(pActor)
    print("[Tip] ActivityType10027 SendRealNameAuthGift")

    local userData =  GetKu25UserData(pActor)
    if 1 == userData.RealNameAuthGiftFlag then
        print("[Tip] ActivityType10027 SendRealNameAuthGift already get RealNameAuthGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.RealnameReward then
        print("[Tip] ActivityType10027 SendRealNameAuthGift not ActivityConfig or not ActivityConfig.RealnameReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10027 SendRealNameAuthGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.RealNameAuthGiftFlag = 1

    CommonFunc.Awards.Give(pActor, ActivityConfig.downloadBoxReward, GameLog.Log_Activity10027)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType1 = 0

    SendKu25UserData(pActor)
    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
end

-- 发送 ku25每日登录奖励
function SendDailyLoginGift(pActor)
    print("[Tip] ActivityType10027 SendDailyLoginGift")

    local userData = GetKu25UserData(pActor)
    if not userData.LoginType then
        print("[Tip] ActivityType10027 SendDailyLoginGift not userData.LoginType")
        return 
    end

    if 1 == userData.DailyLoginGiftFlag then
        print("[Tip] ActivityType10027 SendDailyLoginGift already get BoxDownloadGift")
        return 
    end

    if not ActivityConfig or not ActivityConfig.LoginReward then
        print("[Tip] ActivityType10027 SendDailyLoginGift not ActivityConfig or not ActivityConfig.LoginReward")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10027 SendDailyLoginGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.DailyLoginGiftFlag = 1

    CommonFunc.Awards.Give(pActor, ActivityConfig.LoginReward, GameLog.Log_Activity10027)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType1 = 0

    SendKu25UserData(pActor)
    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
end

-- 发送 每日首充、每日累充奖励
function SendOneDayRechargesGift(pActor)
    print("[Tip] ActivityType10027 SendOneDayRechargesGift")

    local userData = GetKu25UserData(pActor)
    if not userData.LoginType then
        print("[Tip] ActivityType10027 SendOneDayRechargesGift not userData.LoginType")
        return 
    end

    if not ActivityDailyConfig or userData.ReqSubGiftType1 > #ActivityDailyConfig or not ActivityDailyConfig[userData.ReqSubGiftType1] then
        print("[Tip] ActivityType10027 SendOneDayRechargesGift already get OneDayRechargesGift Id : "..userData.ReqSubGiftType1)
        return 
    end

    if not ActivityDailyConfig[userData.ReqSubGiftType1].Target or userData.OneDayRechargesYBNum < ActivityDailyConfig[userData.ReqSubGiftType1].Target then
        print("[Tip] ActivityType10027 SendOneDayRechargesGift not ActivityDailyConfig[userData.ReqSubGiftType1].Target or userData.OneDayRechargesYBNum < ActivityDailyConfig[userData.ReqSubGiftType1].Target Id : "..userData.ReqSubGiftType1)
        return
    end

    if 1 == System.getIntBit(userData.OneDayRechargesGiftFlag, userData.ReqSubGiftType1 - 1) then
        print("[Tip] ActivityType10027 SendOneDayRechargesGift already get OneDayRechargesGift Id : "..userData.ReqSubGiftType1)
        return 
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10027 SendOneDayRechargesGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.OneDayRechargesGiftFlag = System.setIntBit(userData.OneDayRechargesGiftFlag, userData.ReqSubGiftType1 - 1, true)

    print("userData.OneDayRechargesGiftFlag : "..userData.OneDayRechargesGiftFlag.." userData.ReqSubGiftType1 : "..userData.ReqSubGiftType1)

    CommonFunc.Awards.Give(pActor, ActivityDailyConfig[userData.ReqSubGiftType1].reward, GameLog.Log_Activity10027)

    userData.ReqMainGiftType = 0
    userData.ReqSubGiftType1 = 0

    SendKu25UserData(pActor)
    Actor.sendTipmsg(pActor, "|C:0xf56f00&T:领取成功|", tstUI)
end

-- 检查 微信礼包码礼包 是否已经领取
function CheckWeChatGift(pActor)
    print("[Tip] ActivityType10027 CheckWeChatGift")

    if not ActivityConfig or not ActivityConfig.WeChatRewardID then
        print("[Tip] ActivityType10027 CheckWeChatGift not ActivityConfig or not ActivityConfig.WeChatRewardID")
        return
    end

    local userData = GetKu25UserData(pActor)
    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.WeChatRewardID] then
                userData.WeChatGiftFlag = 1
            else
                userData.WeChatGiftFlag = 0
            end
        else
            print("[Tip] ActivityType10027 CheckWeChatGift not cdkdata.codeTypeTimes")
            return
        end
    else
        print("[Tip] ActivityType10027 CheckWeChatGift not cdkdata")
        return
    end

    SendKu25UserData(pActor)
end


--------------------------------------------------------------------
-- cpp回调
--------------------------------------------------------------------


-- 更新每日累计充值元宝数
function ChangeOneDayRechargesYBNum(pActor, YBNum)
    print("[Tip] ActivityType10027 ChangeOneDayRechargesYBNum ActorName : "..Actor.getName(pActor).." YBNum : "..YBNum)

    local userData =  GetKu25UserData(pActor)
    if nil == userData.OneDayRechargesYBNum then
        userData.OneDayRechargesYBNum = 0
    end

    userData.OneDayRechargesYBNum = userData.OneDayRechargesYBNum + YBNum

    -- 玩家数据更新到客户端
    SendKu25UserData(pActor)
end


--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------


-- ku25 玩家登录
function OnReqku25Login(pActor, packet)
    print("[Tip] ActivityType10027 OnReqku25Login")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10027 OnReqku25Login not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10027 OnReqku25Login not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10027 OnReqku25Login not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10027 OnReqku25Login [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetKu25UserData(pActor)

    -- 初始化 登录类型
    userData.LoginType = DataPack.readByte(packet)  -- 1：盒子登录

    -- 初始化 玩家数据
    if nil == userData.LoginType then
        userData.LoginType = 0
    end
    if nil == userData.ReqGiftMainType then
        userData.ReqGiftMainType = 0
    end     
    if nil == userData.ReqSubGiftType1 then
        userData.ReqSubGiftType1 = 0
    end  
    if nil == userData.OneDayRechargesYBNum then
        userData.OneDayRechargesYBNum = 0
    end
    if nil == userData.BoxDownloadGiftFlag then
        userData.BoxDownloadGiftFlag = 0
    end
    if nil == userData.RealNameAuthGiftFlag then
        userData.RealNameAuthGiftFlag = 0
    end
    if nil == userData.DailyLoginGiftFlag then
        userData.DailyLoginGiftFlag = 0
    end      
    if nil == userData.OneDayRechargesGiftFlag then
        userData.OneDayRechargesGiftFlag = 0
    end
    if nil == userData.WeChatGiftFlag then
        userData.WeChatGiftFlag = 0
    end  

    -- 玩家数据更新到客户端
    SendKu25UserData(pActor)
end

-- 请求 ku25奖励
function OnReqKu25Gift(pActor, packet)
    print("[Tip] ActivityType10027 OnReqKu25Gift")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10027 OnReqKu25Gift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10027 OnReqKu25Gift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10027 OnReqKu25Gift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10027 OnReqKu25Gift [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetKu25UserData(pActor)
    userData.ReqGiftMainType = DataPack.readByte(packet)
    userData.ReqSubGiftType1 = DataPack.readByte(packet)

    if not userData.ReqGiftMainType or userData.ReqGiftMainType < 1 or userData.ReqGiftMainType > 5 then
        print("[Tip] ActivityType10027 OnReqKu25Gift not userData.ReqGiftMainType or userData.ReqGiftMainType < 1 or userData.ReqGiftMainType > 5")  
        return
    end

    if 4 == userData.ReqGiftMainType then
        if not userData.ReqSubGiftType1 or userData.ReqSubGiftType1 < 1 or userData.ReqSubGiftType1 > 6 then
            print("[Tip] ActivityType10027 OnReqKu25Gift not userData.ReqSubGiftType1 or userData.ReqSubGiftType1 < 1 or userData.ReqSubGiftType1 > 6")  
            return
        end
    end

    if 1 == userData.ReqGiftMainType then -- 盒子下载礼包(一次性)
        SendBoxDownloadGift(pActor)
    elseif 2 == userData.ReqGiftMainType then -- 实名认证奖励(一次性)
        SendRealNameAuthGift(pActor)
    elseif 3 == userData.ReqGiftMainType then -- 每日登录礼包
        SendDailyLoginGift(pActor)
    elseif 4 == userData.ReqGiftMainType then -- 每日首充奖励和每日累计充值奖励
        SendOneDayRechargesGift(pActor)
    elseif 5 == userData.ReqGiftMainType then -- 检查 是否领取微信礼包码 礼包
        CheckWeChatGift(pActor)
    end
end

NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqku25Login, OnReqku25Login)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqku25Gift,  OnReqKu25Gift)

-- 跨天
function OnNewDayArrive(pActor,ndiffday)
    print("[Tip] ActivityType10027 OnNewDayArrive")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10027 OnNewDayArrive not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10027 OnNewDayArrive not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10027 OnNewDayArrive not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10027 OnNewDayArrive [非本平台活动]")  
        return --非本平台活动
    end

    -- local currMiniTime = System.getCurrMiniTime()
    local data = GetKu25UserData(pActor)
    -- if data.LastTime then
    --     if not System.isSameDay(data.LastTime, currMiniTime) then
    --         data.LastTime = currMiniTime
            data.OneDayRechargesYBNum = 0
            data.DailyLoginGiftFlag = 0
            data.OneDayRechargesGiftFlag = 0
            SendKu25UserData(pActor)
    --     end
    -- end
end

ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10027.lua")