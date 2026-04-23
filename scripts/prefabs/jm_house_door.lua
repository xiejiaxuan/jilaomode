local assets = {
    Asset("ANIM", "anim/treasure_chest.zip"),
    Asset("ANIM", "anim/jm_house_door.zip"),
    Asset("ATLAS", "images/inventoryimages.xml"),
}

local prefabs = {}
local USE_CUSTOM_DOOR_ANIM = softresolvefilepath("anim/jm_house_door.zip") ~= nil

--[[
    MarkPlayerInteriorState(player, in_interior)
    作用:
      给玩家打“室内状态”Tag。家具部署逻辑依赖这个 Tag。
    参数:
      player      (EntityScript) - 玩家实体
      in_interior (boolean)      - 是否处于室内状态
    返回:
      无
]]
-- 用玩家 Tag 标记“是否在室内”，供家具摆放校验使用。
local function MarkPlayerInteriorState(player, in_interior)
    if player == nil then
        return
    end
    if in_interior then
        player:AddTag("jm_inside_house")
    else
        player:RemoveTag("jm_inside_house")
    end
end

--[[
    OnActivate(inst, doer)
    触发时机:
      玩家使用 teleporter 组件完成传送时。
    作用:
      根据“传送目标门”是否是室内门，更新玩家室内状态。
]]
local function OnActivate(inst, doer)
    if doer == nil then
        return
    end
    -- 判断本次传送后的目标门是否“室内门”，据此设置玩家状态。
    local target = inst.components.teleporter ~= nil and inst.components.teleporter.targetTeleporter or nil
    local going_inside = target ~= nil and target._is_inside_door ~= nil and target._is_inside_door:value() or false
    MarkPlayerInteriorState(doer, going_inside)
end

--[[
    EnsurePairedDoor(inst)
    作用:
      为室外门创建并配对一个室内门，形成双向传送。
    关键点:
      1) 只在主机端执行（ismastersim）
      2) 只对室外门执行（防止递归创建）
      3) 使用世界组件分配室内槽位坐标
]]
-- 仅室外门会执行：自动创建并配对一个室内门。
local function EnsurePairedDoor(inst)
    if not TheWorld.ismastersim then
        return
    end
    if inst._is_inside_door:value() then
        return
    end
    if inst._paired_guid ~= nil then
        return
    end

    local manager = TheWorld.components.jm_interiormanager
    if manager == nil then
        return
    end

    local slot_id, interior_pos = manager:AllocateSlot()
    inst._interior_id = slot_id

    local inside = SpawnPrefab("jm_house_door")
    if inside ~= nil then
        -- 该门标记为室内门，并放到分配好的室内坐标。
        inside._is_inside_door:set(true)
        inside._interior_id = slot_id
        inside.Transform:SetPosition(interior_pos.x, 0, interior_pos.z)

        -- 建立双向传送关系：室外 <-> 室内。
        inst.components.teleporter.targetTeleporter = inside
        inside.components.teleporter.targetTeleporter = inst
        inst._paired_guid = inside.GUID
        inside._paired_guid = inst.GUID
    end
end

-- 建造完成事件回调：触发门配对流程。
local function OnBuilt(inst)
    EnsurePairedDoor(inst)
end

--[[
    OnHammered(inst, worker)
    作用:
      处理门被锤毁的逻辑。
      - 删除配对门，避免残留
      - 仅室外门掉落材料，避免资源复制
]]
local function OnHammered(inst, worker)
    -- 任一门被敲掉时，配对门也一起移除，避免残留孤儿门。
    if inst._paired_guid ~= nil and Ents[inst._paired_guid] ~= nil then
        local pair = Ents[inst._paired_guid]
        if pair ~= nil and pair:IsValid() then
            pair:Remove()
        end
    end

    if inst.components.lootdropper ~= nil and not inst._is_inside_door:value() then
        -- 只让室外门掉落材料，避免刷资源。
        inst.components.lootdropper:DropLoot()
    end
    inst:Remove()
end

-- 受击反馈（动画）。
local function OnHit(inst)
    if inst.AnimState ~= nil then
        inst.AnimState:PlayAnimation("open")
        inst.AnimState:PushAnimation("close")
    end
end

-- 存档：保存配对关系和门类型。
local function onsave(inst, data)
    -- 保存“门类型/配对关系/槽位 ID”，保证读档后关系不丢。
    data.is_inside = inst._is_inside_door:value()
    data.paired_guid = inst._paired_guid
    data.interior_id = inst._interior_id
end

-- 读档：恢复基础字段（真正关联在 onloadpostpass 做）。
local function onload(inst, data)
    if data == nil then
        return
    end
    if data.is_inside then
        inst._is_inside_door:set(true)
    end
    inst._paired_guid = data.paired_guid
    inst._interior_id = data.interior_id
end

--[[
    onloadpostpass(inst, newents, data)
    作用:
      在所有实体完成恢复后，重新绑定“门 A <-> 门 B”引用。
    为什么需要它:
      OnLoad 阶段很多实体还没准备好，直接引用可能为空。
]]
local function onloadpostpass(inst, newents, data)
    if data == nil or data.paired_guid == nil then
        if not inst._is_inside_door:value() then
            EnsurePairedDoor(inst)
        end
        return
    end

    local pair_data = newents[data.paired_guid]
    if pair_data ~= nil and pair_data.entity ~= nil then
        local pair = pair_data.entity
        inst._paired_guid = pair.GUID
        if inst.components.teleporter ~= nil then
            inst.components.teleporter.targetTeleporter = pair
        end
    end

    -- 容错：若配对门丢失，则为室外门自动补建一个室内门。
    if not inst._is_inside_door:value() and inst.components.teleporter.targetTeleporter == nil then
        EnsurePairedDoor(inst)
    end
end

-- inspectable 状态钩子（目前用于保留扩展位）。
local function getstatus(inst)
    return inst._is_inside_door:value() and "GENERIC" or nil
end

--[[
    fn()
    作用:
      门 prefab 主构造函数（实体 + 网络 + 主机组件）。
    DST 结构提示:
      - AddNetwork + SetPristine: 客户端/主机共享的网络层定义
      - if not ismastersim then return: 客户端不创建服务端组件
]]
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.6)

    -- 有自定义资源时优先使用；没有则回退到原版箱子资源，保证 mod 可运行。
    local bank = USE_CUSTOM_DOOR_ANIM and "jm_house_door" or "treasure_chest"
    local build = USE_CUSTOM_DOOR_ANIM and "jm_house_door" or "treasure_chest"
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("close", true)

    inst:AddTag("structure")
    inst:AddTag("jm_house_door")

    -- 网络变量：同步“是否室内门”到客户端。
    inst._is_inside_door = net_bool(inst.GUID, "jm_house_door._is_inside_door", "jm_door_dirty")
    inst._is_inside_door:set(false)

    MakeSnowCoveredPristine(inst)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst._paired_guid = nil
    inst._interior_id = nil

    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:AddComponent("teleporter")
    -- teleporter 组件是 DST 内置传送机制，targetTeleporter 指向目的地。
    inst.components.teleporter.onActivate = OnActivate

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(OnHammered)
    inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("lootdropper")

    inst:ListenForEvent("onbuilt", OnBuilt)

    MakeLargeBurnable(inst, nil, nil, true)
    MakeLargePropagator(inst)
    MakeSnowCovered(inst)

    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnLoadPostPass = onloadpostpass

    return inst
end

-- 放置预览实体（绿色半透明）。
local function placer_fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:SetPristine()

    local bank = USE_CUSTOM_DOOR_ANIM and "jm_house_door" or "treasure_chest"
    local build = USE_CUSTOM_DOOR_ANIM and "jm_house_door" or "treasure_chest"
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("close", true)
    inst.AnimState:SetMultColour(0, 1, 0, 0.6)

    return inst
end

return Prefab("jm_house_door", fn, assets, prefabs),
    MakePlacer("jm_house_door_placer", USE_CUSTOM_DOOR_ANIM and "jm_house_door" or "treasure_chest", USE_CUSTOM_DOOR_ANIM and "jm_house_door" or "treasure_chest", "close")
