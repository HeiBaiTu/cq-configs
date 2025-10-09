-- 基础节点（中间节点）
ANBT_SELECT = 1         --选择节点
ANBT_SEQUENCE = 2       --顺序节点
ANBT_PARALLEL = 3       --并列节点
ANBT_NOT = 4            --取反节点
ANBT_FINAL = ANBT_NOT

-- 判断节点（叶子节点）
ANCT_IsDeath = ANBT_FINAL + 1    --是否死亡
ANCT_HasTask = ANBT_FINAL + 2    --是否有可接任务
ANCT_CanTask = ANBT_FINAL + 3    --是否能进行任务
ANCT_HasFlyShoes = ANBT_FINAL + 4--是否还有小飞鞋
ANCT_HasMonster = ANBT_FINAL + 5 --周围是否有怪物
ANCT_CanAttack = ANBT_FINAL+6    --能否攻击目标
ANCT_TarInAttkRange = ANBT_FINAL+7--目标在可攻击范围内
ANCT_MovePointIsNearTar = ANBT_FINAL+8   --(移动)坐标点为目标旁边
ANCT_MovePointIsPosi = ANBT_FINAL+9      --(移动)坐标点为当前位置
ANCT_PiCanArrive = ANBT_FINAL+10  --(移动)坐标点为可到达的
ANCT_CanNextAction = ANBT_FINAL+11--能进行下一个动作
ANCT_FINAL = ANCT_CanNextAction       

-- 功能节点（叶子节点）
ANFT_ReturnRelive = ANCT_FINAL + 1  --请求回城复活
ANFT_YBRelive = ANCT_FINAL + 2      --请求元宝复活
ANFT_MovePoint = ANCT_FINAL + 3     --往 (移动)坐标点 移动一步
ANFT_SetTarMonster = ANCT_FINAL + 4 --设置目标 - 怪物（如果目标死亡或不存在了）
ANFT_SetTarItem = ANCT_FINAL + 5    --设置目标 - 物品
ANFT_SetMovePointAsHook = ANCT_FINAL + 6     --设置(移动)坐标点 - 挂机点（并寻路）
ANFT_SetMovePointAsTar = ANCT_FINAL + 7      --设置(移动)坐标点 - 目标旁（并寻路）
ANFT_AttackTarget = ANCT_FINAL + 8  --攻击目标
ANFT_ChangeTarMonster = ANCT_FINAL+9--改变目标 - 怪物（非本目标）
ANFT_SetHook = ANCT_FINAL+10        --设置挂机点

AITreeConfig =
{
    ntype = ANBT_SELECT,
    desc = "根节点-任务/挂机",
    nodes =
    {
        [1] =
        {
            ntype = ANBT_SEQUENCE,
            desc = "如果死亡，则回城复活",
            nodes=
            {
                [1]=
                {
                    ntype = ANCT_IsDeath,
                    desc = "死亡了，要复活",
                },
                [2]=
                {
                    ntype = ANFT_ReturnRelive,
                    desc = "回城复活",
                }
            }
        },
        [2] =
        {
            ntype = ANBT_SEQUENCE,
            desc = "有可进行任务，则跑任务",
            nodes=
            {
                [1]=
                {
                    ntype = ANCT_CanTask,
                    desc = "是否有可进行任务",
                },
            }
        },
        [3] =
        {
            ntype = ANBT_SELECT,
            desc = "否则，挂机打怪/跑挂机点",
            nodes =
            {
                [1]=
                {
                    ntype = ANBT_SEQUENCE,
                    desc = "周围有怪物，则去打怪",
                    nodes=
                    {
                        [1] =
                        {
                            ntype = ANCT_HasMonster,--这里要优化，如果周围有“可攻击/可到达”的怪物
                            desc = "周围如果有怪物",
                        },
                        [2] =
                        {
                            ntype = ANCT_CanNextAction,
                            desc = "动作超时检查",
                        },
                        [3] =
                        {
                            ntype = ANFT_SetTarMonster,
                            desc = "设置目标怪物",
                        },
                        [4] =
                        {
                            ntype = ANBT_SELECT,
                            desc = "如果一直无法接近目标，则切换，否则移动到怪物旁打怪",
                            nodes =
                            {
                                [1]=
                                {
                                    ntype = ANBT_SEQUENCE,
                                    desc = "检查切换目标",
                                    nodes =
                                    {
                                        [1] =
                                        {
                                            ntype = ANBT_NOT,
                                            desc = "",
                                            node = { ntype = ANCT_PiCanArrive, desc = "如果目标不能到达" }
                                        },
                                        [2] =
                                        {
                                            ntype = ANFT_ChangeTarMonster,
                                            desc = "切换怪物目标",
                                        }
                                    }
                                },
                                [2]=
                                {
                                    ntype = ANBT_SELECT,
                                    desc = "移动到怪物旁打怪",
                                    nodes =
                                    {
                                        [1]=
                                        {
                                            ntype = ANBT_SEQUENCE,
                                            desc = "打怪",
                                            nodes =
                                            {
                                                [1] =
                                                {
                                                    ntype = ANCT_TarInAttkRange,
                                                    desc = "目标在可攻击范围",
                                                },
                                                [2] =
                                                {
                                                    ntype = ANFT_AttackTarget,
                                                    desc = "攻击目标",
                                                }
                                            }
                                        },
                                        [2]=
                                        {
                                            ntype = ANBT_SELECT,
                                            desc = "追怪",
                                            nodes =
                                            {
                                                [1] =
                                                {
                                                    ntype = ANBT_SEQUENCE,
                                                    desc = "走向怪物",
                                                    nodes =
                                                    {
                                                        [1] =
                                                        {
                                                            ntype = ANCT_MovePointIsNearTar,
                                                            desc = "（移动）坐标点为目标附近",
                                                        },
                                                        [2] =
                                                        {
                                                            ntype = ANFT_MovePoint,
                                                            desc = "往怪物移动一次",
                                                        }
                                                    }
                                                },
                                                [2] =
                                                {
                                                    ntype = ANFT_SetMovePointAsTar,
                                                    desc = "设置（移动）坐标点为目标（怪物）",
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                },
                [2]=
                {
                    ntype = ANBT_SEQUENCE,
                    desc = "没怪物，则跑挂机点",
                    nodes=
                    {
                        [1] =
                        {
                            ntype = ANBT_NOT,
                            desc = "",
                            node = { ntype = ANCT_HasMonster, desc = "周围如果没有怪物" }
                        },
                        [2] =
                        {
                            ntype = ANFT_SetHook,
                            desc = "设置挂机点",
                        },
                        [3] =
                        {
                            ntype = ANCT_CanNextAction,
                            desc = "动作超时检查",
                        },
                        [4] =
                        {
                            ntype = ANBT_SELECT,
                            desc = "跑挂机点",
                            nodes =
                            {
                                [1] =
                                {
                                    ntype = ANBT_SEQUENCE,
                                    desc = "走向挂机点",
                                    nodes =
                                    {
                                        [1] =
                                        {
                                            ntype = ANBT_NOT,
                                            desc = "",
                                            node = { ntype = ANCT_MovePointIsPosi, desc = "还没走到挂机点" }
                                        },
                                        [2] =
                                        {
                                            ntype = ANFT_MovePoint,
                                            desc = "往挂机点移动一步",
                                        }
                                    }
                                },
                                [2] =
                                {
                                    ntype = ANFT_SetMovePointAsHook,
                                    desc = "设置（移动）坐标点为挂机点",
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
