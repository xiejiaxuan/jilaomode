local function MakeHouseDoorPrefab(config)
    local prefab_name = config.prefab_name
    local placer_name = config.placer_name or (prefab_name .. "_placer")
    local bank = config.bank or prefab_name
    local build = config.build or bank
    local assets = config.assets or {}
    local prefabs = config.prefabs or {}
    local scale_tuning = config.scale_tuning or "JM_HOUSE_DOOR_SCALE"
    local physics_radius_tuning = config.physics_radius_tuning or "JM_HOUSE_DOOR_PHYSICS_RADIUS"
    local inside_prefab_name = config.inside_prefab_name or prefab_name
    local inside_bank = config.inside_bank or bank
    local inside_build = config.inside_build or inside_bank
    local inside_scale_tuning = config.inside_scale_tuning or scale_tuning
    local inside_physics_radius_tuning = config.inside_physics_radius_tuning or physics_radius_tuning

    local function RemoveHouseCollision(inst)
        if inst._collision_blockers ~= nil then
            for _, blocker in ipairs(inst._collision_blockers) do
                if blocker ~= nil and blocker:IsValid() then
                    blocker:Remove()
                end
            end
        end
        inst._collision_blockers = nil
    end

    local function SpawnHouseCollision(inst)
        RemoveHouseCollision(inst)

        if inst._is_inside_door ~= nil and inst._is_inside_door:value() then
            return
        end

        local half_width = TUNING.JM_HOUSE_DOOR_COLLISION_HALF_WIDTH or 3
        local depth = TUNING.JM_HOUSE_DOOR_COLLISION_DEPTH or 1
        local radius = TUNING.JM_HOUSE_COLLISION_BLOCKER_RADIUS or 0.45
        local spacing = radius * 1.6
        local count = math.max(3, math.ceil((half_width * 2) / spacing) + 1)
        local start_x = -half_width
        local step = (half_width * 2) / math.max(1, count - 1)
        local x, _, z = inst.Transform:GetWorldPosition()

        inst._collision_blockers = {}
        for i = 1, count do
            local blocker = SpawnPrefab("jm_house_collision")
            if blocker ~= nil then
                blocker.Transform:SetPosition(x + start_x + (i - 1) * step, 0, z)
                table.insert(inst._collision_blockers, blocker)
            end
        end

        for _, offset_z in ipairs({ -depth * 0.5, depth * 0.5 }) do
            for _, offset_x in ipairs({ -half_width, half_width }) do
                local blocker = SpawnPrefab("jm_house_collision")
                if blocker ~= nil then
                    blocker.Transform:SetPosition(x + offset_x, 0, z + offset_z)
                    table.insert(inst._collision_blockers, blocker)
                end
            end
        end
    end

    local function IsInsideDoor(inst, fallback)
        return inst._is_inside_door ~= nil and inst._is_inside_door:value() or fallback
    end

    local function ApplyDoorPresentation(inst, inside_override)
        local is_inside = inside_override
        if is_inside == nil then
            is_inside = IsInsideDoor(inst, false)
        end

        inst.AnimState:SetBank(is_inside and inside_bank or bank)
        inst.AnimState:SetBuild(is_inside and inside_build or build)
        inst.AnimState:PlayAnimation("close", true)

        local scale = TUNING[is_inside and inside_scale_tuning or scale_tuning] or 2
        inst.AnimState:SetScale(scale, scale)
    end

    local function placer_postinit(inst)
        ApplyDoorPresentation(inst, false)
    end

    local function MarkPlayerInteriorState(player, in_interior, interior_id)
        if player == nil then
            return
        end
        if in_interior then
            player:AddTag("jm_inside_house")
            player._jm_house_interior_id = interior_id
            player:PushEvent("jm_house_entered", { interior_id = interior_id, door_prefab = prefab_name })

            if player.components.moisture ~= nil and player.components.moisture.SetPercent ~= nil then
                player.components.moisture:SetPercent(0)
            end
            player:AddTag("sheltered")
        else
            player:RemoveTag("jm_inside_house")
            player._jm_house_interior_id = nil
            player:PushEvent("jm_house_exited", { door_prefab = prefab_name })
            player:RemoveTag("sheltered")
        end
    end

    local function OnActivate(inst, doer)
        if doer == nil then
            return
        end
        local target = inst.components.teleporter ~= nil and inst.components.teleporter.targetTeleporter or nil
        local going_inside = target ~= nil and target._is_inside_door ~= nil and target._is_inside_door:value() or false
        local interior_id = going_inside and target._interior_id or nil
        MarkPlayerInteriorState(doer, going_inside, interior_id)
    end

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

        local inside = SpawnPrefab(inside_prefab_name)
        if inside ~= nil then
            if inside.SetHouseDoorInsideState ~= nil then
                inside:SetHouseDoorInsideState(true)
            else
                inside._is_inside_door:set(true)
                ApplyDoorPresentation(inside, true)
            end
            inside._interior_id = slot_id
            inside.Transform:SetPosition(interior_pos.x, 0, interior_pos.z)

            inst.components.teleporter:Target(inside)
            inside.components.teleporter:Target(inst)
            inst._paired_guid = inside.GUID
            inside._paired_guid = inst.GUID
        end
    end

    local function OnBuilt(inst)
        EnsurePairedDoor(inst)
    end

    local function OnHammered(inst, worker)
        if inst._paired_guid ~= nil and Ents[inst._paired_guid] ~= nil then
            local pair = Ents[inst._paired_guid]
            if pair ~= nil and pair:IsValid() then
                pair:Remove()
            end
        end

        if inst.components.lootdropper ~= nil and not inst._is_inside_door:value() then
            inst.components.lootdropper:DropLoot()
        end
        RemoveHouseCollision(inst)
        inst:Remove()
    end

    local function OnHit(inst)
        if inst.AnimState ~= nil then
            inst.AnimState:PlayAnimation("open")
            inst.AnimState:PushAnimation("close")
        end
    end

    local function onsave(inst, data)
        data.is_inside = inst._is_inside_door:value()
        data.paired_guid = inst._paired_guid
        data.interior_id = inst._interior_id
    end

    local function onload(inst, data)
        if data == nil then
            return
        end
        if data.is_inside then
            inst._is_inside_door:set(true)
            ApplyDoorPresentation(inst, true)
        end
        inst._paired_guid = data.paired_guid
        inst._interior_id = data.interior_id
    end

    local function onloadpostpass(inst, newents, data)
        if inst._is_inside_door:value() and inst._interior_id ~= nil then
            local manager = TheWorld.components.jm_interiormanager
            local interior_pos = manager ~= nil and manager:GetSlotPosition(inst._interior_id) or nil
            if interior_pos ~= nil then
                inst.Transform:SetPosition(interior_pos.x, 0, interior_pos.z)
            end
        end

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
                inst.components.teleporter:Target(pair)
            end
        end

        if not inst._is_inside_door:value() and inst.components.teleporter.targetTeleporter == nil then
            EnsurePairedDoor(inst)
        end
    end

    local function getstatus(inst)
        return inst._is_inside_door:value() and "GENERIC" or nil
    end

    local function MakeDoorFn(is_inside_definition, actual_prefab_name)
        return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        if not is_inside_definition then
            inst.entity:AddMiniMapEntity()
        end
        inst.entity:AddNetwork()

        local radius_tuning = is_inside_definition and inside_physics_radius_tuning or physics_radius_tuning
        local physics_radius = TUNING[radius_tuning] or 1
        if physics_radius > 0 then
            MakeObstaclePhysics(inst, physics_radius)
        end

        inst:AddTag("structure")
        inst:AddTag("jm_house_door")
        inst:AddTag(prefab_name)
        inst:AddTag(actual_prefab_name)
        inst:AddTag("teleporter")

        inst._is_inside_door = net_bool(inst.GUID, actual_prefab_name .. "._is_inside_door", actual_prefab_name .. "_door_dirty")
        inst._is_inside_door:set(is_inside_definition)

        inst.SetHouseDoorInsideState = function(inst, is_inside)
            inst._is_inside_door:set(is_inside)
            ApplyDoorPresentation(inst, is_inside)
        end
        inst:ListenForEvent(actual_prefab_name .. "_door_dirty", function(inst)
            ApplyDoorPresentation(inst)
        end)
        ApplyDoorPresentation(inst, is_inside_definition)

        MakeSnowCoveredPristine(inst)
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst._paired_guid = nil
        inst._interior_id = nil
        inst._collision_blockers = nil

        inst:AddComponent("inspectable")
        inst.components.inspectable.getstatus = getstatus

        inst:AddComponent("teleporter")
        inst.components.teleporter.onActivate = OnActivate

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(4)
        inst.components.workable:SetOnFinishCallback(OnHammered)
        inst.components.workable:SetOnWorkCallback(OnHit)

        inst:AddComponent("lootdropper")

        if not is_inside_definition then
            inst:ListenForEvent("onbuilt", OnBuilt)
            inst:DoTaskInTime(0, EnsurePairedDoor)
            inst:DoTaskInTime(0, SpawnHouseCollision)
        end

        MakeLargeBurnable(inst, nil, nil, true)
        MakeLargePropagator(inst)
        MakeSnowCovered(inst)

        inst.OnSave = onsave
        inst.OnLoad = onload
        inst.OnLoadPostPass = onloadpostpass
        inst.OnRemoveEntity = RemoveHouseCollision

        return inst
        end
    end

    local prefab_defs = {
        Prefab(prefab_name, MakeDoorFn(false, prefab_name), assets, prefabs),
    }

    if inside_prefab_name ~= prefab_name then
        table.insert(prefab_defs, Prefab(inside_prefab_name, MakeDoorFn(true, inside_prefab_name), assets, prefabs))
    end

    table.insert(prefab_defs, MakePlacer(placer_name, bank, build, "close", nil, nil, nil, nil, nil, nil, placer_postinit))
    return unpack(prefab_defs)
end

return MakeHouseDoorPrefab
