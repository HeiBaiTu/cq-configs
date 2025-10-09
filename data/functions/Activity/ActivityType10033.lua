module("ActivityType10033", package.seeall)


ActivityType = 10033


--排行榜id
RANKING_ID = RANK_DEFINE_ACTIVITY10033


ActivityConfig = Activity10033Config


--------------------------------------------------------------------
-- 活动 回调注册
--------------------------------------------------------------------

-- 活动开始
function OnStart(atvId)
    print("ActivityType10033 OnStart")
    
    --清空排行榜
    RankMgr.Clear(RANKING_ID)
end

---更新活动数据
function OnUpdateActivity(atvId, pActor, nType, nSubType, nValue)
    print("ActivityType10033 OnUpdateActivity actorName : "..Actor.getName(pActor).." nType : "..nType)
    local actorId = Actor.getActorId(pActor)

    -- 更新并保存玩家充值排行榜数据
    RankMgr.SetRank(actorId, RANKING_ID, nType)
    RankMgr.Save(RANKING_ID)
end


-- 活动结束
function OnEnd(atvId)
    print("ActivityType10033 OnEnd atvId : "..atvId)

    if not ActivityConfig or not ActivityConfig[atvId] then
        print("ActivityType10033 OnEnd not ActivityConfig or not ActivityConfig[atvId]")
        return
    end

    if not ActivityConfig[atvId].pay or not ActivityConfig[atvId].awardList then
        print("ActivityType10033 OnEnd not ActivityConfig[atvId].pay or not ActivityConfig[atvId].awardList")
    end

    if not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1 then
        print("ActivityType10033 OnEnd not ActivityConfig[atvId].mailTitle1 or not ActivityConfig[atvId].mailContent1")
        return
    end

    if not ActivityConfig[atvId].mailTitle2 or not ActivityConfig[atvId].mailContent2 then
        print("ActivityType10033 OnEnd not ActivityConfig[atvId].mailTitle2 or not ActivityConfig[atvId].mailContent2")
        return
    end

    local rankAward = ActivityConfig[atvId].awardList
    local ranking = Ranking.getRanking( RANKING_ID )
    if ranking then
        local itemNum = Ranking.getRankItemCount(ranking)
        local startIndex = 1
        for awardIndex,awardInfo in ipairs(rankAward) do
            print("awardIndex : "..awardIndex)
            local rankNum = awardInfo.value
            if rankNum > itemNum then
                rankNum = itemNum
            end
            for curIndex = startIndex, rankNum do
                local rankItem = Ranking.getItemFromIndex(ranking, curIndex - 1)
                local actorId = Ranking.getId(rankItem)
               local curPayValue = RankMgr.GetValue(actorId, RANKING_ID)

                if curPayValue >= ActivityConfig[atvId].pay then
                    if 1 == awardIndex then
                        SendMail(actorId, ActivityConfig[atvId].mailTitle1, ActivityConfig[atvId].mailContent1, awardInfo.awards)
                    elseif 2 == awardIndex then
                        SendMail(actorId, ActivityConfig[atvId].mailTitle2, ActivityConfig[atvId].mailContent2, awardInfo.awards)
                    end
                else
                    print("actorId : "..actorId.." curPayValue : "..curPayValue)
                end
            end

            startIndex = rankNum + 1
            if startIndex > itemNum then
                print("ActivityType10033 (id:"..atvId..") 奖励发完! 一共"..rankNum.."人获得上榜奖励!")
                return
            end
        end
    end
end


ActivityDispatcher.Reg(ActivityEvent.OnStart,           ActivityType, OnStart,          "ActivityType10033.lua")
ActivityDispatcher.Reg(ActivityEvent.OnUpdateActivity,  ActivityType, OnUpdateActivity, "ActivityType10033.lua")
ActivityDispatcher.Reg(ActivityEvent.OnEnd,             ActivityType, OnEnd,            "ActivityType10033.lua")module("ActivityType10033", package.seeall)