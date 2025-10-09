module("ActivityType10023", package.seeall)


--活动类型
ActivityType = 10023
--对应的活动配置
ActivityConfig = Platform7youxiConfig
local PfId = System.getPfId()


--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

-- 7游戏玩家登录
function On7GameLogin(pActor)
    print("[Tip]  ActivityType10023 On7GameLogin")

    -- 平台验证
    if not PfId then
        print("[Tip]  ActivityType10023 On7GameLogin not PfId")
        return 
    end
    if not ActivityConfig then
        print("[Tip]  ActivityType10023 On7GameLogin not ActivityConfig")
        return
    end
    if not ActivityConfig.SPID then
        print("[Tip]  ActivityType10023 On7GameLogin not ActivityConfig.SPID")
        return
    end
    if tostring(PfId) ~= tostring(ActivityConfig.SPID) then
        print("[Tip] [非本平台活动]")  
        return --非本平台活动
    end


    local npack = DataPack.allocPacket(pActor, enPlatforMwelfareID, sSend7GameGitfData)
    if npack then
        print("[Tip]  ActivityType10023 On7GameLogin sSend7GameGitfData ")
        local nCurYuanBaoCount = Actor.getIntProperty(pActor,PROP_ACTOR_DRAW_YB_COUNT)
        
        local nGiftFlag = 0;
        local cdkdata = getActorCdkData(pActor)
        if cdkdata then
            if cdkdata.codeTypeTimes and PlatformConfig.type then
                if cdkdata.codeTypeTimes[PlatformConfig.type] then
                    nGiftFlag = 1;
                end
            end
        end

        print("[Tip]  ActivityType10023 On7GameLogin sSend7GameGitfData nGiftFlag : "..nGiftFlag)

        DataPack.writeByte(npack, (nGiftFlag or 0))                  -- 是否领取 7游戏 微信礼包  0否1是
        DataPack.flush(npack)
    end
end

