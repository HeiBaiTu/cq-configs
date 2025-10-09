--#include "ActorBeKilledHandler.txt" once          --角色被杀
--#include "ActorChangeNameHandle.txt" once         --角色改名
--#include "ActorConsumeGameGoldHandler.txt" once   --角色使用元宝
--#include "ActorLoginHandler.txt" once             --角色登录
--#include "ActorLevelUpHandler.txt" once	        --角色升级
--#include "ActorEventCircleHandler.txt" once	    --角色转生
--#include "ActorDeadHandler.txt" once              --角色死亡
--#include "ActorReliveHandler.txt" once            --角色复活超时
--#include "ActorLeaveTeamHandler.txt" once         --角色离队
--#include "ActorLogoutHandler.txt" once            --角色登出
--#include "ActorNewDayHandler.txt" once            --角色跨天
--#include "ActorWithDrawGameGoldHandler.txt" once  --角色提取元宝（相当于充值）
--#include "BuffRemovedHandler.txt" once            --角色移除BUFF
--#include "FuBenHandler.txt" once                  --角色副本操作


ActorEventDispatcher.Reg(aeLevel,            defaultHandlerActorLevelUp,         "ActorLevelUpHandler.txt")
ActorEventDispatcher.Reg(aeUserLogin,        defaultHandlerPlayerLogin,          "ActorLoginHandler.txt")
ActorEventDispatcher.Reg(aeUserLogout,       defaultHandlerPlayerLogout,         "ActorLogoutHandler.txt")
ActorEventDispatcher.Reg(aeOnActorDeath,     defaultHandlerActorDead,            "ActorDeadHandler.txt")
ActorEventDispatcher.Reg(aeReliveTimeOut,    defaultHandlerActorReliveTimeOut,   "ActorReliveHandler.txt")
ActorEventDispatcher.Reg(aeNewDayArrive,     defaultHandleActorNewDay,           "ActorNewDayHandler.txt")
ActorEventDispatcher.Reg(aeOnActorBeKilled,  defaultHandlerActorBeKilled,        "ActorBeKilledHandler.txt")
ActorEventDispatcher.Reg(aeWithDrawYuanBao,  defaultHandleActorWithDrawGameGold, "ActorWithDrawGameGoldHandler.txt")
ActorEventDispatcher.Reg(aeConsumeYb,        defaultHandleActorConsumeGameGold,  "ActorConsumeGameGoldHandler.txt")
ActorEventDispatcher.Reg(aeOnEnterFuben,	 defaultHandlerEnterFuben,           "FuBenHandler.txt")
ActorEventDispatcher.Reg(aeOnExitFuben,	     defaultHandlerExitFuben,            "FuBenHandler.txt")
ActorEventDispatcher.Reg(aeBuffRemoved,      defaultHandlerBuffRemoved,          "BuffRemovedHandler.txt")
ActorEventDispatcher.Reg(aeLeaveTeam,        defaultHandlerLeaveTeam,            "ActorLeaveTeamHandler.txt")
ActorEventDispatcher.Reg(aeCircle,           defaultHandlerActorCirclel,         "ActorEventCircleHandler.txt")
ActorEventDispatcher.Reg(aeChangeName,       defaultHandleChangeNameOp,          "ActorChangeNameHandle.txt")