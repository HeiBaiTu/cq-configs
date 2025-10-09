module("ActivityType10029", package.seeall)


--[[
    个人数据：userData
    {
        LoginType = 0 or 1                      爱奇艺 登录类型(1：游戏盒子登录)
        ReqMainGiftType                         爱奇艺 请求奖励主类型：1：领取盒子下载 礼包领取；2：检查 微信礼包码 领取；3：检查 SVIP礼包码 领取；4：检查 QQ群礼包码 领取
        DownLoadBoxGiftFlag = 0 or 1            爱奇艺 盒子下载 礼包领取标志
        WeChatGiftFlag      = 0 or 1            爱奇艺 微信礼包码 礼包领取标志
        SVIPGiftFlag        = 0 or 1            爱奇艺 SVIP礼包码 礼包领取标志
        QQGroupGiftFlag     = 0 or 1            爱奇艺 QQ群礼包码 礼包领取标志
    }
]]--


--活动类型
ActivityType = 10029
--对应的活动配置
ActivityConfig = PlatformaiqiyiConfig


local PfId = System.getPfId()


function GetAiQiYiUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.AiQiYiUserData then
        var.AiQiYiUserData = {}
    end
    return var.AiQiYiUserData
end

function SendAiQiYiUserData(pActor)
    print("[Tip] ActivityType10029 SendAiQiYiUserData")
    local userData = GetAiQiYiUserData(pActor)
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSendAiQiYiUserData)
    if npack then
        DataPack.writeByte(npack, userData.DownLoadBoxGiftFlag)
        DataPack.writeByte(npack, userData.WeChatGiftFlag)
        DataPack.writeByte(npack, userData.SVIPGiftFlag)
        DataPack.writeByte(npack, userData.QQGroupGiftFlag)
        DataPack.flush(npack)
    end
end


--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------


-- 发送 爱奇艺微端下载奖励
function SendDownLoadBoxGift(pActor)
    print("[Tip] ActivityType10029 SendDownLoadBoxGift")

    local userData = GetAiQiYiUserData(pActor)
    if not userData.LoginType then
        print("[Tip] ActivityType10029 SendDownLoadBoxGift not userData.LoginType")
        return
    end

    if 1 == userData.DownLoadBoxGiftFlag then
        print("[Tip] ActivityType10029 SendDownLoadBoxGift already get DownLoadBoxGift")
        return
    end

    if not ActivityConfig or not ActivityConfig.rewardClient then
        print("[Tip] ActivityType10029 SendDownLoadBoxGift not ActivityConfig or not ActivityConfig.rewardClient")
        return
    end

    --检测格子 16 : 活动通用
    if true ~= CommonFunc.Awards.CheckBagIsEnough(pActor,16,tmDefNoBagNum,tstUI) then
        print("[Tip] ActivityType10029 SendDownLoadBoxGift not CheckBagIsEnough")
        return
    end

    -- 设置标志
    userData.DownLoadBoxGiftFlag = 1
    
    CommonFunc.Awards.Give(pActor, ActivityConfig.rewardClient, GameLog.Log_Activity10029)

    SendAiQiYiUserData(pActor)
end

-- 检查玩家 微信礼包码 领取状态
function CheckWeChatGift(pActor)
    print("[Tip] ActivityType10029 CheckWeChatGift")

    if not ActivityConfig or not ActivityConfig.wechat then
        print("[Tip] ActivityType10029 CheckWeChatGift")
        return
    end

    local userData = GetAiQiYiUserData(pActor)
    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        -- 超级vip奖励
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.wechat] then
                userData.WeChatGiftFlag = 1
            else
                print("[Tip] ActivityType10029 CheckWeChatGift not cdkdata.codeTypeTimes[ActivityConfig.wechat]")
            end
        else
            print("[Tip] ActivityType10029 CheckWeChatGift not cdkdata.codeTypeTimes")
        end
    else
        print("[Tip] ActivityType10029 CheckWeChatGift not cdkdata")
    end

    SendAiQiYiUserData(pActor)
end

-- 检查玩家 SVIP礼包码 领取状态
function CheckSVIPGift(pActor)
    print("[Tip] ActivityType10029 CheckSVIPGift")

    if not ActivityConfig or not ActivityConfig.SVIP then
        print("[Tip] ActivityType10029 CheckSVIPGift")
        return
    end

    local userData = GetAiQiYiUserData(pActor)
    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        -- 超级vip奖励
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.SVIP] then
                userData.SVIPGiftFlag = 1
            else
                print("[Tip] ActivityType10029 CheckSVIPGift not cdkdata.codeTypeTimes[ActivityConfig.SVIP]")
            end
        else
            print("[Tip] ActivityType10029 CheckSVIPGift not cdkdata.codeTypeTimes")
        end
    else
        print("[Tip] ActivityType10029 CheckSVIPGift not cdkdata")
    end

    SendAiQiYiUserData(pActor)
end

-- 检查玩家 QQ群礼包码 领取状态
function CheckQQGroupGift(pActor)
    print("[Tip] ActivityType10029 CheckQQGroupGift")

    if not ActivityConfig or not ActivityConfig.QQ then
        print("[Tip] ActivityType10029 CheckQQGroupGift")
        return
    end

    local userData = GetAiQiYiUserData(pActor)
    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        -- 超级vip奖励
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.QQ] then
                userData.QQGroupGiftFlag = 1
            else
                print("[Tip] ActivityType10029 CheckQQGroupGift not cdkdata.codeTypeTimes[ActivityConfig.QQ]")
            end
        else
            print("[Tip] ActivityType10029 CheckQQGroupGift not cdkdata.codeTypeTimes")
        end
    else
        print("[Tip] ActivityType10029 CheckQQGroupGift not cdkdata")
    end

    SendAiQiYiUserData(pActor)
end

-- 爱奇艺玩家登录
function OnReqAiQiYiLogin(pActor, packet)
    print("[Tip] ActivityType10029 OnReqAiQiYiLogin")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10029 OnReqAiQiYiLogin not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10029 OnReqAiQiYiLogin not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10029 OnReqAiQiYiLogin not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10029 OnReqAiQiYiLogin [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetAiQiYiUserData(pActor)

    -- 初始化 登录类型
    userData.LoginType = DataPack.readByte(packet)

    if not userData.LoginType then
        userData.LoginType = 0
    end
    if not userData.ReqMainGiftType then
        userData.ReqMainGiftType = 0
    end
    if nil == userData.DownLoadBoxGiftFlag then
        userData.DownLoadBoxGiftFlag = 0
    end
    if nil == userData.WeChatGiftFlag then
        userData.WeChatGiftFlag = 0
    end
    if nil == userData.SVIPGiftFlag then
        userData.SVIPGiftFlag = 0
    end
    if nil == userData.QQGroupGiftFlag then
        userData.QQGroupGiftFlag = 0
    end

    SendAiQiYiUserData(pActor)
end

-- 请求爱奇艺礼包
function OnReqAiQiYiGift(pActor, packet)
    print("[Tip] ActivityType10029 OnReqAiQiYiGift")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10029 OnReqAiQiYiGift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10029 OnReqAiQiYiGift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10029 OnReqAiQiYiGift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10029 OnReqAiQiYiGift [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetAiQiYiUserData(pActor)

    -- 初始化 请求奖励类型
    userData.ReqMainGiftType = DataPack.readByte(packet)

    if not userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 4 then
        print("[Tip] ActivityType10029 OnReqAiQiYiGift not userData.ReqMainGiftType or userData.ReqMainGiftType < 1 or userData.ReqMainGiftType > 4")
        return
    end

    if 1 == userData.ReqMainGiftType then      -- 请求 盒子下载 奖励
        SendDownLoadBoxGift(pActor)
    elseif 2 == userData.ReqMainGiftType  then -- 检查 微信礼包码 领取
        CheckWeChatGift(pActor)
    elseif 3 == userData.ReqMainGiftType  then -- 检查 SVIP礼包码 领取
        CheckSVIPGift(pActor)
    elseif 4 == userData.ReqMainGiftType  then -- 检查 QQ群礼包码 领取
        CheckQQGroupGift(pActor)
    end
    
end

NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqAiQiYiLogin, OnReqAiQiYiLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqAiQiYiGift,  OnReqAiQiYiGift)
    

