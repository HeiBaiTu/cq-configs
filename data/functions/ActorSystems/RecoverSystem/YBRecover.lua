--回收元宝
--回收 19-6
-- 获取玩家的 recover 数据
local function getYbActorData(pActor)
    if Actor.getEntityType(pActor) ~= enActor then
        assert(false)
    end
    local var = Actor.getStaticVar(pActor);
    if var.YBRecoverData == nil then
        var.YBRecoverData = {}
    end

    return var.YBRecoverData
end

function getUseTimeData(pActor, nIdx, nType)
    local data = getYbActorData(pActor);
    if data.daily == nil then
        data.daily = {}
    end
    if data.forever == nil then
        data.forever = {}
    end
    if nType == 1 then
        return data.daily[nIdx] or 0
    else
        return data.forever[nIdx] or 0
    end
end

function AddUsetimeData(pActor, nIdx, nType)
    local data = getYbActorData(pActor);
    if data.daily == nil then
        data.daily = {}
    end
    if data.forever == nil then
        data.forever = {}
    end
    if nType == 1 then
        data.daily[nIdx] = (data.daily[nIdx] or 0) + 1
    else
        data.forever[nIdx] = (data.forever[nIdx] or 0) + 1
    end
end

function  HandleRecoverItem(pActor, packet)
    if Actor.getEntityType(pActor) ~= enActor then
        return
    end
    local nId = DataPack.readInt(packet)
    local errorcode = 0;
    local nOpenDay = System.getDaysSinceOpenServer();
    local recoverCfg = YBrecoverConfig[nId];
    local nLeftTime = 0;
    while(true) 
    do
        if recoverCfg == nil then
            errorcode = 1;
            break;
        end
        if recoverCfg.recoverlimit then
            if Actor.checkActorLevel(pActor, recoverCfg.recoverlimit.level or 0, recoverCfg.recoverlimit.zsLevel or 0) ~= true then
                errorcode = 2;
                break;
            end

            if nOpenDay < recoverCfg.recoverlimit.openDay then
                errorcode = 3;
                break;
            end
            if recoverCfg.daylimit > 0 then
                if nOpenDay > (recoverCfg.recoverlimit.openDay + recoverCfg.daylimit - 1) then
                    errorcode = 4;
                    break;
                end
            end
            if recoverCfg.timeslimit > 0 then
                if recoverCfg.timeslimit <= getUseTimeData(pActor, recoverCfg.id, recoverCfg.dayclear or 0) then
                    errorcode = 5;
                    break;
                end
            end
        end

        local nActorRight = Actor.GetMaxColorCardLevel(pActor);
        if nActorRight < recoverCfg.privilegelimit then
            errorcode = 6;
            break;
        end
        local item = recoverCfg.item
        if item and CommonFunc.Consumes.CheckActorSources(pActor, item,tstUI) ~= true then
            errorcode = 7;
            break
        end
        if item and CommonFunc.Consumes.Remove(pActor, item, GameLog.Log_YBRecover, "回收给元宝") ~= true then
            errorcode = 8
            break
        end 
        local nAward = recoverCfg.privilegeaward[nActorRight]
        if nAward then
            if CommonFunc.Awards.Give(pActor, nAward, GameLog.Log_YBRecover, "回收给元宝") ~= true  then 
                errorcode = 9 
                break
            end 
        end
        nLeftTime = recoverCfg.timeslimit
        if recoverCfg.timeslimit > 0 then
            AddUsetimeData(pActor, recoverCfg.id, (recoverCfg.dayclear or 0));
            nLeftTime = recoverCfg.timeslimit - getUseTimeData(pActor, recoverCfg.id, (recoverCfg.dayclear or 0));
        end
        break;
    end
    -- 回复使用结果
    local npack = DataPack.allocPacket(pActor, enBasicFunctionsSystemID, enYBRecoverResult)
    if npack then
        -- print("errorcode"..errorcode)
        DataPack.writeByte(npack, errorcode)
        DataPack.writeInt(npack, nId)
        DataPack.writeInt(npack, nLeftTime)
        DataPack.flush(npack)
    end
end

--列表 19-7
function ClientGetData(pActor, packet)
    local nCount = 0;

    local recoverCfg = YBrecoverConfig;
    local nOpenDay = System.getDaysSinceOpenServer();

    if recoverCfg then
        for _, cfg in ipairs(recoverCfg) do
            if cfg.timeslimit > 0 or cfg.daylimit > 0 then
                DataPack.writeInt(packet, cfg.id);
                local nLeftTime = cfg.daylimit
                if cfg.daylimit > 0 then
                    local nLeftDay = cfg.recoverlimit.openDay + cfg.daylimit - nOpenDay;
                    local todaytime = System.getToday() + nLeftDay*24*3600;
	 			    local nNowTime = System.getRealtimeMiniTime();
                    nLeftTime = todaytime - nNowTime;
                    if nLeftTime < 0 then
                        nLeftTime = 0
                    end
                    -- print("openday.."..cfg.recoverlimit.openDay.."..cfg.daylimit.."..cfg.daylimit.."oop.."..nOpenDay)
                end

                DataPack.writeInt(packet, nLeftTime);
                local nLeftTimes = cfg.timeslimit
                if cfg.timeslimit > 0 then
                    local nUseCount = getUseTimeData(pActor, cfg.id, (cfg.dayclear or 0));
                    nLeftTimes = cfg.timeslimit - nUseCount;
                end

                DataPack.writeShort(packet, nLeftTimes);
                nCount = nCount + 1;
            end
        end
    end
    return nCount;
end
function OnNewDayArrive(pActor)
    local ybData = getYbActorData(pActor);
    if ybData == nil then
        return
    end
    if ybData.daily == nil then
        return
    end

    ybData.daily = nil
end

NetmsgDispatcher.Reg(enBasicFunctionsSystemID, enYBRecover, HandleRecoverItem)
ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "YBRecover.lua")