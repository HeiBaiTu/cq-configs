module("ActivityType10030", package.seeall)


--[[
    个人数据：userData
    {
        SVIPGiftFlag = 0 or 1            yaodou SVIP 礼包领取标志
    }
]]--


local PfId = System.getPfId()


--活动类型
ActivityType = 10029
--对应的活动配置
ActivityConfig = PlatformYaodouConfig


function GetYaoDouUserData(pActor)
    local var = Actor.getStaticVar(pActor)
    if nil == var.YaoDouUserData then
        var.YaoDouUserData = {}
    end
    return var.YaoDouUserData
end

function SendYaoDouUserData(pActor)
    print("[Tip] ActivityType10030 SendYaoDouUserData")
    local userData = GetYaoDouUserData(pActor)
    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSendYaoDouUserData)
    if npack then
        DataPack.writeByte(npack, userData.SVIPGiftFlag)
        DataPack.flush(npack)
    end
end

--------------------------------------------------------------------
-- 客户端请求协议回调
--------------------------------------------------------------------


-- 检查玩家 SVIP 礼包领取状态
function CheckSVIPGift(pActor)
    print("[Tip] ActivityType10030 CheckSVIPGift")

    if not ActivityConfig or not ActivityConfig.CDkeytype then
        print("[Tip] ActivityType10030 CheckSVIPGift")
        return
    end

    local userData = GetYaoDouUserData(pActor)
    local cdkdata = getActorCdkData(pActor)
    if cdkdata then
        -- 超级vip奖励
        if cdkdata.codeTypeTimes then
            if cdkdata.codeTypeTimes[ActivityConfig.CDkeytype] then
                userData.SVIPGiftFlag = 1
            else
                print("[Tip] ActivityType10030 CheckSVIPGift not cdkdata.codeTypeTimes[ActivityConfig.CDkeytype]")
            end
        else
            print("[Tip] ActivityType10030 CheckSVIPGift not cdkdata.codeTypeTimes")
        end
    else
        print("[Tip] ActivityType10030 CheckSVIPGift not cdkdata")
    end

    SendYaoDouUserData(pActor)
end

-- yaodou玩家登录
function OnReqYaoDouLogin(pActor)
    print("[Tip] ActivityType10030 OnReqYaoDouLogin")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10030 OnReqYaoDouLogin not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10030 OnReqYaoDouLogin not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10030 OnReqYaoDouLogin not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10030 OnReqYaoDouLogin [非本平台活动]")  
        return --非本平台活动
    end

    local userData = GetYaoDouUserData(pActor)

    if nil == userData.SVIPGiftFlag then
        userData.SVIPGiftFlag = 0
    end

    SendYaoDouUserData(pActor)
end

-- 请求yaodou礼包
function OnReqYaoDouGift(pActor)
    print("[Tip] ActivityType10030 OnReqYaoDouGift")

    -- 平台验证
    if not PfId then
        print("[Tip] ActivityType10030 OnReqYaoDouGift not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip] ActivityType10030 OnReqYaoDouGift not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip] ActivityType10030 OnReqYaoDouGift not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] ActivityType10030 OnReqYaoDouGift [非本平台活动]")  
        return --非本平台活动
    end

    CheckSVIPGift(pActor)
end

NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqYaoDouLogin, OnReqYaoDouLogin)
NetmsgDispatcher.Reg(enPlatforMwelfareID, cReqYaoDouGift,  OnReqYaoDouGift)