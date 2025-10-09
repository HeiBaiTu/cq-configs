module("ActivityType10035", package.seeall)


--[[
    个人数据：userData
    {
        ReqMainGiftType                 快玩 请求奖励类型 0：默认类型(服务器自用)；1：检查SVIP礼包领取标志；2：检查微信礼包领取标志；

        SVIPGiftFlag = 0 or 1           快玩 超级VIP 礼包领取标志
        WeChatGiftFlag = 0 or 1         快玩 微信礼包 礼包领取标志
    }
]]--


--活动类型
ActivityType = 10035
--对应的活动配置
ActivityConfig = PlatformteeqeeConfig


local PfId = System.getPfId()


function GetKuaiWanUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.UserDataKuaiWan then
        var.UserDataKuaiWan = {}
    end
    return var.UserDataKuaiWan
end

-- 发送 KuaiWan 玩家数据
function SendKuaiWanUserData(pActor)
    print("[Tip] ActivityType10035 SendKuaiWanUserData actorName : "..Actor.getName(pActor))

    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, cSendKuaiWanUserData)
    if npack then
        local userData = GetKuaiWanUserData(pActor)

        DataPack.writeByte(npack, userData.SVIPGiftFlag)
        DataPack.writeByte(npack, userData.WeChatGiftFlag)
        DataPack.flush(npack)
    end
end

-- 查看快玩 SVIP 礼包领取情况
function CheckSVIPGift(pActor)
    print("ActivityType10035 CheckSVIPGift")

    local userData = GetKuaiWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if not ActivityConfig or not ActivityConfig.SVIPReward then
        print("ActivityType10035 CheckSVIPGift not ActivityConfig or not ActivityConfig.SVIPReward")
        return
    end
    
    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        -- 超级vip奖励
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.SVIPReward] then
                userData.SVIPGiftFlag = 1
            end
        else
            print("ActivityType10035 CheckSVIPGift not cdkdata.codeTypeTimes")
        end
    else
        print("ActivityType10035 CheckSVIPGift not cdkdata")
    end

    SendKuaiWanUserData(pActor)
end

-- 查看快玩 WeChat 礼包领取情况
function CheckWeChatGift(pActor)
    print("ActivityType10035 CheckWeChatGift")

    local userData = GetKuaiWanUserData(pActor)
    userData.ReqMainGiftType = 0

    if not ActivityConfig or not ActivityConfig.WechatReward then
        print("ActivityType10035 CheckWeChatGift not ActivityConfig or not ActivityConfig.WechatReward")
        return
    end

    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        -- 超级vip奖励
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.WechatReward] then
                userData.WeChatGiftFlag = 1
            end
        else
            print("ActivityType10035 CheckWeChatGift not cdkdata.codeTypeTimes")
        end
    else
        print("ActivityType10035 CheckWeChatGift not cdkdata")
    end

    SendKuaiWanUserData(pActor)
end


-- KuaiWan 用户登录
function OnReqKuaiWanLogin(pActor)
    print("ActivityType10035 OnReqKuaiWanLogin ctorName : "..Actor.getName(pActor))
    
    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10035 OnReqKuaiWanLogin not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10035 OnReqKuaiWanLogin not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10035 OnReqKuaiWanLogin not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10035 OnReqKuaiWanLogin [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetKuaiWanUserData(pActor)
    if nil == userData.SVIPGiftFlag then
        userData.SVIPGiftFlag = 0
    end
    if nil == userData.WeChatGiftFlag then
        userData.WeChatGiftFlag = 0
    end

    SendKuaiWanUserData(pActor)
end

-- KuaiWan 获取奖励领取标志
function OnReqKuaiWanGiftFlag(pActor, packet)
    print("ActivityType10035 OnReqKuaiWanGiftFlag actorName : "..Actor.getName(pActor))

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10035 OnReqKuaiWanGiftFlag not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10035 OnReqKuaiWanGiftFlag not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10035 OnReqKuaiWanGiftFlag not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10035 OnReqKuaiWanGiftFlag [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetKuaiWanUserData(pActor)
    userData.ReqMainGiftType = DataPack.readByte(packet)

    if nil == userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 2 then
        print("ActivityType10035 OnReqKuaiWanGiftFlag nil == userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 2")
        return
    end

    if 1 == userData.ReqMainGiftType then
        CheckSVIPGift(pActor)
    elseif 2 == userData.ReqMainGiftType then
        CheckWeChatGift(pActor)
    end
end

NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqKuaiWanLogin, OnReqKuaiWanLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqKuaiWanGift, OnReqKuaiWanGiftFlag)
