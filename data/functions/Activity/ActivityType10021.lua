module("ActivityType10021", package.seeall)

--[[
    个人活动
   二充

    个人数据：ActorData[AtvId]
    {
        nSecondLeftTimes = 1111  当前档奖励位领取标志位
        nSecondGetFlag //领取标志
    }

    全局缓存：Cache[AtvId]
    {   
        
    }

    全局数据：GlobalData[AtvId]
    {
    
    }
]]--

--活动类型
ActivityType = 10021
--对应的活动配置
ActivityConfig10021 = Activity10021Config
if ActivityConfig10021 == nil then
    assert(false)
end




--玩家请求领取礼包
function reqGetGiftBox(pActor, atvId , indexId,inerIndex)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    local Cfg = ActivityConfig10021[atvId]

    if inerIndex ~= 1 then
        -- Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无可领取的礼包|", tstUI)
        return;
    end 

    if actorData.nSecondLeftTimes == nil then
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:无可领取的礼包|", tstUI)
        return;
    end 

    if Cfg[1][1].Count == nil then 
        --print("配置错误") 
    end  
    local currentYuanBaoCount = Actor.getIntProperty(pActor,PROP_ACTOR_DRAW_YB_COUNT)
    if currentYuanBaoCount < Cfg[1][1].Count then 
        Actor.sendTipmsg(pActor, "|C:0xf56f00&T:未达到最低充值额度|", tstUI)
        return 
    end 


--print("indexId: "..indexId.."    InnerIndex : "..inerIndex)
    if Cfg ~=nil and Cfg[indexId]~=nil and  Cfg[indexId][inerIndex] ~=nil then 
        --配置检查
        --if indexId ~= Cfg.GiftTable[indexId].value then return end 
        if nil == Cfg[indexId][inerIndex].GiftTable then return end 
        if indexId ~= Cfg[indexId][inerIndex].jobs then return end 
        local Award = Cfg[indexId][inerIndex].GiftTable 
        

        --提示没有购买次数
        if System.getIntBit((actorData.nSecondLeftTimes or 0),inerIndex-1)  == 1  then 
            --Actor.sendTipmsgWithId(pActor, tmNomoreYubao, tstUI)
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:您已领取|", tstUI)
            return 
        end 

        -- if actorData.GetTime == nil then
        --     actorData.nextIndex =1
        --     if inerIndex ~= 1 then 
        --         if inerIndex == 2 then
        --             Actor.sendTipmsg(pActor, "|C:0xf56f00&T:充值后第二天才可领取|", tstUI)
        --         elseif inerIndex == 3 then
        --             Actor.sendTipmsg(pActor, "|C:0xf56f00&T:充值后第三天才可领取|", tstUI)
        --         end 
        --         return 
        --     end 
        -- else     
        --     if actorData.GetTime == System.getDaysSinceOpenServer() then
        --         --if actorData.nextIndex ~= inerIndex then
        --             if inerIndex == 2 and System.getIntBit((actorData.nSecondLeftTimes or 0),inerIndex-1) ==1 then
        --                 Actor.sendTipmsg(pActor, "|C:0xf56f00&T:充值后第二天才可领取|", tstUI)
        --             elseif inerIndex == 3 and System.getIntBit((actorData.nSecondLeftTimes or 0),inerIndex-1) ==1 then
        --                 Actor.sendTipmsg(pActor, "|C:0xf56f00&T:充值后第三天才可领取|", tstUI)
        --             end 
                    
        --         --end 
        --         return 
        --     end 
            
        -- end 

        --检查格子够不够
        -- if CommonFunc.Awards.CheckBagGridCount(pActor,Award) ~= true then
        --     Actor.sendTipmsgWithId(pActor, tmLeftBagNumNotEnough, tstUI)
        --     return
        -- end
        
        if inerIndex > actorData.nSecondGetFlag then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:该礼包领取时间未到|", tstUI)
            return
        end
        if CommonFunc.Awards.CheckBagIsEnough(pActor,17) ~= true then
            Actor.sendTipmsg(pActor, "|C:0xf56f00&T:背包不足，药品、装备、材料包裹都必须剩余2格|", tstUI)
            return
        end

        
        --if actorData.nSecondLeftTimes == 1 then 
            --CommonFunc.GiveCommonAward(pActor, Award, GameLog.Log_Activity10021,  "二充领取礼包|"..atvId)
        CommonFunc.Awards.Give(pActor, Award, GameLog.Log_Activity10021,  "二充领取礼包|"..atvId)
--print("req--->   nSecondLeftTimes : "..(actorData.nSecondLeftTimes or 0 ).."  GetTime : "..(actorData.GetTime or 0 ).."  nextIndex : "..(actorData.nextIndex or 0 ))
        actorData.nSecondLeftTimes = System.setIntBit(actorData.nSecondLeftTimes, inerIndex-1, true)
        -- print("inerIndex..."..actorData.nSecondLeftTimes)
        Actor.sendTipmsgWithId(pActor, tmMailGetItemSuccess, tstUI)
        ---策划fw
        local strName = Actor.getName(pActor)
        if inerIndex == 1 and  Cfg[1][1].tips then
            local strTips = string.format(Cfg[1][1].tips,strName)
            System.broadcastTipmsgLimitLev(strTips, tstKillDrop)
        end

        if inerIndex == 1 and  Cfg[1][1].tips2 then
            local strTips2 = string.format(Cfg[1][1].tips2,strName)
            System.broadcastTipmsgLimitLev(strTips2, tstChatSystem)
        end
        --end 
        Actor.SendActivityLog(pActor,atvId,ActivityType,2)
    
    end 

    -- 发送一个活动数据
    Actor.sendActivityData(pActor, atvId)
end 



--------------------------我是分界线----------------------------

-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("[GActivity 10021]  二充"..Actor.getName(pActor).." 初始化 id："..atvId)
                        
end

--活动开始
function OnStart(atvId, pActor)
    print("[activitytype 10021] ---onstart  atvId:"..atvId)

    ActivityDispatcher.ClearActorData(pActor, atvId)
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if actorData.nSecondLeftTimes == nil then
        actorData.nSecondLeftTimes = 0
    end  
end


-- 通用操作
function OnOperator(atvId, pActor, inPack)
    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    local InnerIndex = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cReqPurchaseGiftbag then --请求领取二充奖励
        local myjob = Actor.getIntProperty(pActor, PROP_ACTOR_VOCATION)
        --print("-------myjob:"..myjob)
        reqGetGiftBox(pActor, atvId , myjob,InnerIndex)
    end
end


-- 获取活动数据
function OnReqData(atvId, pActor, outPack)
    --print("OnReqData 1111 atvId : ".. atvId.." name : "..Actor.getName(pActor))
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    --local outPack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendActorDataTimes)

    if actorData.nSecondLeftTimes == nil then
        actorData.nSecondLeftTimes = 0
    end  

    if  outPack then  
        --print("OnReqData 2222 atvId : ".. atvId.." name : "..Actor.getName(pActor).."getRechargeStatus() : "..Actor.getRechargeStatus(pActor))
        DataPack.writeUInt(outPack, Actor.getRechargeStatus(pActor) or 0) 
        DataPack.writeByte(outPack, actorData.nSecondLeftTimes or 0)  
    end
    --print("OnReqData 3333 atvId : ".. atvId.." name : "..Actor.getName(pActor))
end

--活动红点数据
function OnGetRedPoint(atvId, pActor)
    local ret = 0
    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)

    if actorData.nSecondGetFlag == nil then
        return ret
    end

    if actorData.nSecondLeftTimes == nil then
        actorData.nSecondLeftTimes = 0
    end

    local Cfg = ActivityConfig10021[atvId]

    local currentYuanBaoCount = Actor.getIntProperty(pActor,PROP_ACTOR_DRAW_YB_COUNT)
    if currentYuanBaoCount >= Cfg[1][1].Count  then 
        for i = 1, actorData.nSecondGetFlag,1 do
            if System.getIntBit((actorData.nSecondLeftTimes or 0),i-1)  == 0 then 
                ret = System.setIntBit(ret, i-1, true)
            end 
        end        
    end    
    return ret

end
ActivityDispatcher.Reg(ActivityEvent.OnGetRedPoint, ActivityType, OnGetRedPoint, "ActivityType10021.lua")


-- 活动结束
function OnEnd(atvId, pActor)
    ActivityDispatcher.ClearActorData(pActor, atvId)
end

---更新活动数据
function OnUpdateActivity(atvId, pActor, nValue)

    local actorData = ActivityDispatcher.GetActorData(pActor,atvId)
    
    if actorData.nSecondLeftTimes == nil then
        actorData.nSecondLeftTimes = 0
    end
    if actorData.nSecondGetFlag then
        return;
    end
    
    local Cfg = ActivityConfig10021[atvId]
    if nValue >= Cfg[1][1].Count  then
        if actorData.nSecondGetFlag == nil then
            actorData.nSecondGetFlag = 0;
        end
        actorData.nSecondGetFlag = actorData.nSecondGetFlag +1; 
        
        Actor.setRechargeStatus(pActor, 2)  
    end 

    Actor.sendActivityData(pActor, atvId)
end

ActivityDispatcher.Reg(ActivityEvent.OnUpdateActivity, ActivityType, OnUpdateActivity, "ActivityType10021.lua")

ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10021.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10021.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10021.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10021.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10021.lua")


-- 跨天,
function OnNewDayArrive(pActor,ndiffday)
    --print("[ActivityType10004 ] "..Actor.getName(pActor).." 跨"..ndiffday.."天")
    local runAtvIdList = Actor.getRunningActivityId(pActor,ActivityType)
    if runAtvIdList == nil then 
        return 
    end
    if runAtvIdList then
        for i,atvId in ipairs(runAtvIdList) do
            local Cfg = ActivityConfig10021[atvId]

            local currentYuanBaoCount = Actor.getIntProperty(pActor,PROP_ACTOR_DRAW_YB_COUNT)
            if currentYuanBaoCount >= Cfg[1][1].Count  then 
                local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
                if actorData.nSecondGetFlag then
                    actorData.nSecondGetFlag = actorData.nSecondGetFlag + ndiffday;
                end
            end
        end
        
    end
end
ActorEventDispatcher.Reg(aeNewDayArrive, OnNewDayArrive, "ActivityType10021.lua")