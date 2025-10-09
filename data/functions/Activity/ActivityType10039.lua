module("ActivityType10039", package.seeall)

--[[
    全局活动，竞技大乱斗 

    个人数据：ActorData[AtvId]
    {
        curYBConsumeNum            记录玩家当前元宝消耗数量
    }

    全局缓存：Cache[AtvId]
    {
    }

    全局数据：GlobalData[AtvId]
    {
        status,                     活动状态，这个即使服务器重启了，也要保存这个数据
        actors = {actorId,...}     记录活动中的玩家id
        rankActors = {
            [actorId] = {
                modelId,                -- 模型Id
                icon,                   -- 头像Id
                helmetId,               -- 头盔道具Id
                soldierSoulAppearance,  -- 衣服Id           
                weaponId,               -- 武器Id
                sex,                    -- 性别
            }
        }
    }
]]--

-- 活动状态
local AtvStatus =
{
    Load = 0,                       -- 从数据库加载活动
    Run = 1,                         -- 活动中
    End = 2,                        -- 结束了（发奖励，等待活动时间结束）
}


-- 活动类型
ActivityType = 10039

-- 对应的活动配置
ActivityConfig = Activity10039Config

-- 排行榜id
RANKING_ID = RANK_DEFINE_ACTIVITY10039


--------------------------------------------------------------------
-- 详细逻辑
--------------------------------------------------------------------


-- 加载活动时（启动服务器从数据库返回的）
function OnLoad(atvId)
    print("ActivityType10039.lua OnLoad atvId : "..atvId)

    if not System.isActivityRunning(atvId) then
        print("ActivityType10039.lua OnLoad not System.isActivityRunning(atvId) atvId : "..atvId)
        return
    end

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    globalData.status = AtvStatus.Run
    
    if nil == globalData.actors then
        globalData.actors = {}
    end
    if nil == globalData.rankActors then
        globalData.rankActors = {}
    end

end

-- 初始化玩家数据
function OnInit(atvId, pActor)
    print("ActivityType10039.lua OnInit actorName : "..Actor.getName(pActor).." atvId : "..atvId)
end

-- 玩家登录
function OnLoginGame(atvId, pActor)
    print("ActivityType10039.lua OnLoginGame actorName : "..Actor.getName(pActor).." atvId : "..atvId)

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if nil == globalData.status or AtvStatus.Run ~= globalData.status then
        print("ActivityType10038 OnLoginGame nil == globalData.status or AtvStatus.Run ~= globalData.status 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return
    end

    local actorId = Actor.getIntProperty(pActor, PROP_ENTITY_ID)
    if nil == globalData.rankActors then
        globalData.rankActors = {}
    end
    -- 更新消耗排行榜数据
    if globalData.rankActors[actorId] then
        globalData.rankActors[actorId] = {}
        globalData.rankActors[actorId].modelId               = Actor.getIntProperty(pActor, PROP_ENTITY_MODELID)
        globalData.rankActors[actorId].icon                  = Actor.getIntProperty(pActor, PROP_ENTITY_ICON)
        globalData.rankActors[actorId].helmetId              = Actor.getUserEquipmentInfo(pActor, 3) --type : 3(头盔)
        globalData.rankActors[actorId].soldierSoulAppearance = Actor.getIntProperty(pActor, PROP_ACTOR_SOLDIERSOULAPPEARANCE)
        globalData.rankActors[actorId].weaponId              = Actor.getIntProperty(pActor, PROP_ACTOR_WEAPON_ID)
        globalData.rankActors[actorId].sex                   = Actor.getIntProperty(pActor, PROP_ACTOR_SEX)
    end

    if nil == globalData.actors then
        globalData.actors = {}
    end
    if globalData.actors[actorId] then
        print("ActivityType10038 OnLoginGame globalData.actors[actorId] 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return
    end
    globalData.actors[actorId] = actorId

    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    actorData.curYBConsumeNum = 0
end

-- 活动开始
function OnStart(atvId)
    print("ActivityType10039.lua OnStart atvId : "..atvId)

    ActivityDispatcher.ClearGlobalData(atvId)

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    globalData.actors = {}
    globalData.rankActors = {}

    globalData.status = AtvStatus.Run

    --清空排行榜
    RankMgr.Clear(RANKING_ID)
end

-- 请求玩家的元宝消耗数据
function OnReqData(atvId, pActor, outPack)
    print("ActivityType10039.lua OnReqData actorName : "..Actor.getName(pActor).." atvId : "..atvId)

    -- 玩家的排名 以及 当前消耗的元宝数
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    DataPack.writeUInt(outPack, (RankMgr.GetValue(actorId, RANKING_ID) or actorData.curYBConsumeNum or 0))
	DataPack.writeWord(outPack, RankMgr.GetMyRank(pActor, RANKING_ID))

    -- 发送元宝消耗排行榜前三名玩家数据
    local ranking = Ranking.getRanking( RANKING_ID )
	if nil == ranking then
		print("ActivityType10039.lua OnReqData nil == ranking actorName : "..Actor.getName(pActor).." atvId : "..atvId)
	end
	local itemNum = Ranking.getRankItemCount(ranking)
	if 3 < itemNum then
		itemNum = 3
	end

    DataPack.writeByte(outPack, itemNum)

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    for index = 1, itemNum do
		local rankItem = Ranking.getItemFromIndex(ranking, index - 1)
		if rankItem then
			local actorId           = Ranking.getId(rankItem)
			local curYBConsumeNum 	= Ranking.getPoint(rankItem)
			local actorName 	 	= Ranking.getSub(rankItem, 0)
			DataPack.writeUInt(outPack, actorId or 0)
			DataPack.writeUInt(outPack, curYBConsumeNum or 0)
			DataPack.writeString(outPack, actorName or "")

            if globalData.rankActors[actorId] then
                DataPack.writeUInt(outPack, globalData.rankActors[actorId].modelId or 0)
                DataPack.writeShort(outPack, globalData.rankActors[actorId].icon or 0)
                DataPack.writeWord(outPack, globalData.rankActors[actorId].helmetId or 0)
                DataPack.writeWord(outPack, globalData.rankActors[actorId].soldierSoulAppearance or 0)
                DataPack.writeShort(outPack, globalData.rankActors[actorId].weaponId or 0)
                DataPack.writeByte(outPack, globalData.rankActors[actorId].sex or 0)
            else -- 针对逻辑服重启，有一段时间报错的处理
                DataPack.writeUInt(outPack, 0)
                DataPack.writeShort(outPack, 0)
                DataPack.writeWord(outPack, 0)
                DataPack.writeWord(outPack, 0)
                DataPack.writeShort(outPack, 0)
                DataPack.writeByte(outPack, 0)
            end
		end
	end
end

-- 请求排行榜数据
function ReqRankData(pActor, atvId)
    print("ActivityType10039.lua ReqRankData actorName : "..Actor.getName(pActor).." atvId : "..atvId)

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    if nil == globalData.status or AtvStatus.Run ~= globalData.status then
        print("ActivityType10038 ReqRankData nil == globalData.status or AtvStatus.Run ~= globalData.status 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return
    end

    local ranking = Ranking.getRanking( RANKING_ID )
    if nil == ranking then
        print("ActivityType10038 ReqRankData nil == ranking 活动Id ："..atvId.." 玩家 "..Actor.getName(pActor))
        return
    end

    local npack = ActivityDispatcher.AllocOperReturn(pActor, atvId, ActivityOperate.sSendRankData)
    if npack then
        local itemNum = Ranking.getRankItemCount(ranking)
        DataPack.writeWord(npack, itemNum)

        for index = 1, itemNum do
            local rankItem = Ranking.getItemFromIndex(ranking, index - 1)
            if rankItem then
                local actorId           = Ranking.getId(rankItem)
                local curYBConsumeNum 	= Ranking.getPoint(rankItem)
                local actorName 	 	= Ranking.getSub(rankItem, 0)
                DataPack.writeUInt(npack, actorId)
                DataPack.writeUInt(npack, curYBConsumeNum)
                DataPack.writeString(npack, actorName)
            end
        end

        DataPack.flush(npack)
    end
end

-- 更新活动数据
function OnUpdateActivity(atvId, pActor, nConsumeYBNum, nYBComsumeRankLimitNum, nValue)
    print("ActivityType10039.lua OnUpdateActivity actorName : "..Actor.getName(pActor).." atvId : "..atvId.." nConsumeYBNum : "..nConsumeYBNum.." nYBComsumeRankLimitNum : "..nYBComsumeRankLimitNum)
    
    local actorData = ActivityDispatcher.GetActorData(pActor, atvId)
    if nil == actorData.curYBConsumeNum then
        actorData.curYBConsumeNum = 0
    end
    actorData.curYBConsumeNum = actorData.curYBConsumeNum + nConsumeYBNum

    if nYBComsumeRankLimitNum <= actorData.curYBConsumeNum then
        local actorId = Actor.getIntProperty( pActor, PROP_ENTITY_ID )
        -- 设置排行榜数据
        RankMgr.SetRank(actorId, RANKING_ID, actorData.curYBConsumeNum)

        -- 保存消耗排行榜数据
        RankMgr.Save(RANKING_ID)

        -- 保存玩家数据
        local globalData = ActivityDispatcher.GetGlobalData(atvId)
        globalData.rankActors[actorId] = {}
        globalData.rankActors[actorId].modelId               = Actor.getIntProperty(pActor, PROP_ENTITY_MODELID)
        globalData.rankActors[actorId].icon                  = Actor.getIntProperty(pActor, PROP_ENTITY_ICON)
        globalData.rankActors[actorId].helmetId              = Actor.getUserEquipmentInfo(pActor, 3) --Item::itHelmet 头盔
        globalData.rankActors[actorId].soldierSoulAppearance = Actor.getIntProperty(pActor, PROP_ACTOR_SOLDIERSOULAPPEARANCE)
        globalData.rankActors[actorId].weaponId              = Actor.getIntProperty(pActor, PROP_ACTOR_WEAPON_ID)
        globalData.rankActors[actorId].sex                   = Actor.getIntProperty(pActor, PROP_ACTOR_SEX)
    end

    print("ActivityType10039.lua OnUpdateActivity actorName : "..Actor.getName(pActor).." atvId : "..atvId.." curYBConsumeNum : "..actorData.curYBConsumeNum)
end

-- 通用操作
function OnOperator(atvId, pActor, inPack)
    print("ActivityType10039.lua OnUpdateActivity actorName : "..Actor.getName(pActor).." atvId : "..atvId)

    -- 操作码对应操作
    local operaCode = DataPack.readByte(inPack)
    if operaCode == ActivityOperate.cReqRankData then
        ReqRankData(pActor, atvId)
    end
end

-- 活动结束
function OnEnd(atvId)
    print("ActivityType10039.lua OnEnd atvId : "..atvId)

    -- 检查奖励相关配置
    if not ActivityConfig or not ActivityConfig[atvId] or not ActivityConfig[atvId] or not ActivityConfig[atvId].reward then
        print("ActivityType10039.lua OnEnd not ActivityConfig or not ActivityConfig[atvId] or not ActivityConfig[atvId] or not ActivityConfig[atvId].reward atvId : "..atvId)
        return
    end

    if not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1 or not ActivityConfig[atvId].mailTitle2 or not ActivityConfig[atvId].mailContent2 then
        print("ActivityType10039.lua OnEnd not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1 or not ActivityConfig[atvId].mailTitle2 or not ActivityConfig[atvId].mailContent2 atvId : "..atvId)
        return
    end

    for awardIndex = 1, 4 do
        if not ActivityConfig[atvId].reward[awardIndex] then
            print("ActivityType10039.lua OnEnd not ActivityConfig[atvId].reward[awardIndex] atvId : "..atvId.." awardIndex : "..awardIndex)
            return
        end
    end
    
    -- 发送奖励
    local ranking = Ranking.getRanking( RANKING_ID )
	if nil == ranking then
		return
	end
	local itemNum = Ranking.getRankItemCount(ranking)
    for index = 1, itemNum do
        local rankItem = Ranking.getItemFromIndex(ranking, index - 1)
        if rankItem then
            local actorId           = Ranking.getId(rankItem)
            local curYBConsumeNum 	= Ranking.getPoint(rankItem)
            local actorName 	 	= Ranking.getSub(rankItem, 0)
            -- 发放前三名奖励
            if index < 4 then
                local content = string.format(ActivityConfig[atvId].mailContent1, index)
                SendMail(actorId, ActivityConfig[atvId].mailTitle1, content, ActivityConfig[atvId].reward[index])
            else
                SendMail(actorId, ActivityConfig[atvId].mailTitle2, ActivityConfig[atvId].mailContent2, ActivityConfig[atvId].reward[4])
            end 
        end
        
    end

    ActivityDispatcher.ClearGlobalData(atvId)

    local globalData = ActivityDispatcher.GetGlobalData(atvId)
    globalData.actors = {}
    globalData.rankActors = {}
    
    globalData.status = AtvStatus.End
end

ActivityDispatcher.Reg(ActivityEvent.OnLoad, ActivityType, OnLoad, "ActivityType10039.lua")
ActivityDispatcher.Reg(ActivityEvent.OnInit, ActivityType, OnInit, "ActivityType10039.lua")
ActivityDispatcher.Reg(ActivityEvent.OnStart, ActivityType, OnStart, "ActivityType10039.lua")
ActivityDispatcher.Reg(ActivityEvent.OnLoginGame, ActivityType, OnLoginGame, "ActivityType10039.lua")
ActivityDispatcher.Reg(ActivityEvent.OnReqData, ActivityType, OnReqData, "ActivityType10039.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdateActivity,  ActivityType, OnUpdateActivity, "ActivityType10039.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd, ActivityType, OnEnd, "ActivityType10039.lua")
ActivityDispatcher.Reg(ActivityEvent.OnOperator, ActivityType, OnOperator, "ActivityType10039.lua")
