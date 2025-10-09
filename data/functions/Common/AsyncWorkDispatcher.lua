module("AsyncWorkDispatcher", package.seeall)

local CallBackList = {}

-- @brief 添加异步工作
-- @param asyncWork 异步工作内容 => { 'function', arg1, arg2 ... } 
-- @param callback 完成回调 格式： callback(paramPack,retParam...) => paramPack为传入参数包，retParam为异步工作返回值
-- @param paramPack 回调参数包
-- @note asyncWork.function 在异步线程中调用，且应函数应定义在 AsyncWorkerFunction.txt
function Add(asyncWork,callback,paramPack)
	local cbid = System.addAsyncWorker(asyncWork)
	if cbid ~= nil and cbid ~= 0 and callback ~= nil then
		CallBackList[cbid] = {callback, paramPack}
	end
end

--------------------------------------------------------------------
-- 提供给CPP的回调
--------------------------------------------------------------------

function OnWorkFinish(cbid, empty, ...)
	if not cbid then return end
	local callback = CallBackList[cbid]
	if callback ~= nil then
		func = callback[1]
		paramPack = callback[2]
		func(paramPack, ...)
		CallBackList[cbid] = nil
	end
end
