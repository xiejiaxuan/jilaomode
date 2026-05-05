local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, TUNING.JM_HOUSE_COLLISION_BLOCKER_RADIUS or 0.45)

    inst:AddTag("NOCLICK")
    inst:AddTag("blocker")
    inst:AddTag("jm_house_collision")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("jm_house_collision", fn)
