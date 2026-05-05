local assets = {
    Asset("ANIM", "anim/jm_interior_wall.zip"),
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, TUNING.JM_INTERIOR_WALL_PHYSICS_RADIUS or 0.65)

    inst.AnimState:SetBank("jm_interior_wall")
    inst.AnimState:SetBuild("jm_interior_wall")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetScale(TUNING.JM_INTERIOR_WALL_SCALE or 1.2, TUNING.JM_INTERIOR_WALL_SCALE or 1.2)

    inst:AddTag("blocker")
    inst:AddTag("NOCLICK")
    inst:AddTag("jm_interior_boundary")
    inst:AddTag("jm_interior_wall")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = true

    return inst
end

return Prefab("jm_interior_wall", fn, assets)
