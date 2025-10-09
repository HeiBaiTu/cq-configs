module("Fee", package.seeall)

-- 玩家产生付费
function OnFeeCmd(pActor, sPfId, sProdId, nNum)
    print("[DEBUG][OnFeeCmd] "..Actor.getName(pActor).." sPfId:"..(sPfId or "none").." sProdId:"..(sProdId or "none").." nNum:"..(nNum or 1))
    if ProdItemMapConf and ProdItemMapConf[sPfId] then
        local IDMap = ProdItemMapConf[sPfId][sProdId]
        if IDMap and IDMap.ItemId then
            local ItemId = IDMap.ItemId

            --直接购买元宝
            if ItemId < 200 then
                local conf = RechargeConf[ItemId]
                if conf then
                    local rechargeNum = conf.Num
                    Actor.changeMoney(pActor, mtYuanbao, rechargeNum, GameLog.Log_Recharge, "充值")
                    print("[OnFeeCmd] "..Actor.getName(pActor).." 充值元宝: "..rechargeNum)
                    return true
                end
            --直接购买礼包物品
            elseif ItemId <= 300 then
                local conf = GiftItemConf[ItemId]
                if conf and conf.Items then
                    CommonFunc.Awards.Give(pActor, conf.Items, GameLog.Log_Recharge, "充值")
                    print("[OnFeeCmd] "..Actor.getName(pActor).." 购买礼包: "..ItemId)
                    return true
                end
            end
        end
    elseif sProdId == "gold" then --无配置平台的，直接充值nNum元宝数
        Actor.changeMoney(pActor, mtYuanbao, nNum, GameLog.Log_Recharge, "充值")
        print("[OnFeeCmd] "..Actor.getName(pActor).." 充值元宝: "..nNum)
        return true
    end
    return false
end
