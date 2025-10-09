-- --lua script
-- local LocalDT={}

-- --这个文件是所有的怪物相关的脚本逻辑的总函数
-- --包括怪物的死亡，怪物的刷新处理的一些逻辑的入口在这里

-- function initialization(npcobj)
-- 	thisNPC = npcobj
-- 	for i = 1, table.getn(InitFnTable) do
-- 		InitFnTable[i]( npcobj )
-- 	end
-- end

-- function finalization(npcobj)
-- 	for i = 1, table.getn(FinaFnTable) do
-- 		FinaFnTable[i]( npcobj )
-- 	end
-- 	thisNPC = nil
-- end

-- --当一个怪物刷新出来的时候的时候调用
-- function OnMonsterMob(monster, monId, sceneId,x,y)
-- 	--print("OnMonsterMob, monId=",monId)
--     MonDispatcher.dispatch(monster, monId, sceneId,x,y)
-- end

-- --当一个怪物被杀死的时候
-- --Killer:归属玩家
-- --lastHitKiller：最后一击玩家
-- function OnMonsterKilled(monster, Killer, monId, lastHitKiller)
-- 	--print("OnMonsterKilled, monId=",monId)
-- 	MonDispatcher.event(monster, Killer, monId,lastHitKiller) 
-- end

-- --当一个怪物刷生命周期的时候的时候调用
-- function OnMonsterLiveTimeOut(monster, monId, sceneId)
-- 	--print("OnMonsterLiveTimeOut, monId=",monId)
--     MonDispatcher.dispatch(monster, monId, sceneId)
-- end
