module("QuestDispatcher", package.seeall)

local dispatcher = {}

_G.QuestEvent =
{
    OnCompleteQuest = 1,   --任务完成
    Count = 1,
}

--------------------------------------------------------------------
-- Lua接口
--------------------------------------------------------------------

-- @brief 注册事件分发器
-- @param evId 事件id
-- @param questType 任务类型
-- @param func 回调
function Reg(evId, func, file)

	--参数检查
	if evId == nil or func == nil or file == nil then 
		print( debug.traceback() )
		assert(false)
	end

    --事件范围检查
    if evId <= 0 or evId >= QuestEvent.Count then
        assert(false)
    end

    --回调表初始化
    -- if dispatcher[evId] == nil then
    --     dispatcher[evId] = {}
    -- end

    --注册
    dispatcher[evId] = func
    print("[TIP][QuestDispatcher] Event("..evId..") In File("..file.."), And Index="..table.maxn(dispatcher[evId]))
end

--------------------------------------------------------------------
-- CPP回调
--------------------------------------------------------------------

function OnEvent(evId, Qid, ...)
    
    --获取回调
    local func = dispatcher[evId]
    if func == nil  then
        return true
    end

    --回调调用
    if evId == FubenEvent.OnCompleteQuest then --任务完成
        -- return func(fbId, fbEnterType, ...)
    end
    return true
end
