--#include "data\config/guild/Notice.config" once --
--领取沙巴克奖励
local function getSbkData()
    local var = System.getStaticVar();
    return var.SbkAwardFlag
end

function setSbkAwardFlag(nFlag)
    local var = System.getStaticVar();
    var.SbkAwardFlag = nFlag;
end

function  HandleGetSBKAward(pActor, packet)
    if Actor.getEntityType(pActor) ~= enActor then
        return
    end
    local errorcode = 0;
    while(true) 
    do
        local guild = Actor.getGuildPtr(pActor);
        if guild == nil then
            errorcode = 1;
            break;
        end

        local isSbk = Actor.MyGuildIsSbk(pActor);
        if isSbk == 0 then
            errorcode = 2;
            break;
        end

        local nGuildPos = Actor.getGuildPos(pActor);
        local cfg = NoticeConfig[nGuildPos];
        if cfg == nil then
            errorcode = 3;
            break;
        end
        
        -- 优先检查活动状态：活动进行中不能领取奖励
        if Actor.isActivityRunning(pActor, (cfg.ActivityID or 0)) or Actor.isActivityRunning(pActor, (cfg.ActivityID2 or 0)) then
            errorcode = 5;  -- 活动进行中，不能领取
            break;
        end
        
        -- 再检查是否已领取：每次活动只能领取一次
        local nFlag = getSbkData();
        if nFlag then
            errorcode = 4;  -- 已领取过，不能重复领取
            break;
        end
        if cfg.noticereward then
            CommonFunc.Awards.Give(pActor, cfg.noticereward, GameLog.Log_SBKaward, "沙巴克领奖")
        end
        setSbkAwardFlag(1);
        break;
    end
    -- 回复使用结果
    local npack = DataPack.allocPacket(pActor, enGuildSystemID, sGuildGetSbkAward)
    if npack then
        DataPack.writeByte(npack, errorcode)
        DataPack.flush(npack)
    end
end

NetmsgDispatcher.Reg(enGuildSystemID, cGuildGetSbkAward, HandleGetSBKAward)