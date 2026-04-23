local assets = {
    Asset("ANIM", "anim/pottedfern.zip"),
    Asset("ANIM", "anim/jm_deco_plant.zip"),
}
local USE_CUSTOM_PLANT_ANIM = softresolvefilepath("anim/jm_deco_plant.zip") ~= nil

--[[
    deco_fn()
    作用:
      已放置状态的装饰家具实体（不是背包物品）。
    交互:
      - 可检查（inspectable）
      - 可锤掉（workable）
      - 锤掉后返还 kit，便于重新摆放
]]
local function deco_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 0.25)

    local bank = USE_CUSTOM_PLANT_ANIM and "jm_deco_plant" or "pottedfern"
    local build = USE_CUSTOM_PLANT_ANIM and "jm_deco_plant" or "pottedfern"
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("structure")
    inst:AddTag("jm_indoor_decor")
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(1)
    -- 这里用内联回调即可：逻辑短、语义集中，便于学习阅读。
    inst.components.workable:SetOnFinishCallback(function(plant)
        if plant.components.lootdropper ~= nil then
            plant.components.lootdropper:SpawnLootPrefab("jm_deco_plant_kit")
        end
        plant:Remove()
    end)

    inst:AddComponent("lootdropper")
    MakeHauntableWork(inst)

    return inst
end

return Prefab("jm_deco_plant", deco_fn, assets)
