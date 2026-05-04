local USE_CUSTOM_PLANT_ANIM = softresolvefilepath("anim/jm_deco_plant.zip") ~= nil
local USE_CUSTOM_KIT_ATLAS = softresolvefilepath("images/inventoryimages/jm_deco_plant_kit.xml") ~= nil
local FALLBACK_PLANT_ANIM = "cave_ferns_potted"
local assets = {
    Asset("ANIM", "anim/cave_ferns_potted.zip"),
    Asset("ATLAS", "images/inventoryimages.xml"),
}

if USE_CUSTOM_PLANT_ANIM then
    table.insert(assets, Asset("ANIM", "anim/jm_deco_plant.zip"))
end

if USE_CUSTOM_KIT_ATLAS then
    table.insert(assets, Asset("ATLAS", "images/inventoryimages/jm_deco_plant_kit.xml"))
end

--[[
    SnapToGrid(value, grid)
    作用:
      将坐标吸附到最近网格点。
    示例:
      grid=1.0 时 10.49 -> 10, 10.5 -> 11
    返回:
      number - 吸附后的坐标值
]]
-- 将任意坐标吸附到最近网格点（例如 1.0 或 0.5）。
local function SnapToGrid(value, grid)
    return math.floor((value / grid) + 0.5) * grid
end

--[[
    CanDeploy(_, pt, deployer)
    deployable 的“可放置判定”回调。
    规则:
      1) 玩家必须处于室内（有 jm_inside_house Tag）
      2) 目标点附近不能和已有结构重叠
]]
local function CanDeploy(_, pt, deployer)
    -- 只允许“在室内状态”玩家摆放家具。
    if deployer == nil or not deployer:HasTag("jm_inside_house") then
        return false
    end
    -- 简单防重叠：附近有结构/装饰则禁止摆放。
    local ents = TheSim:FindEntities(pt.x, 0, pt.z, 0.6, nil, { "INLIMBO", "player" }, { "jm_indoor_decor", "structure" })
    return #ents == 0
end

--[[
    OnDeploy(inst, pt, deployer)
    deployable 的“实际放置”回调。
    流程:
      1) 目标点吸附网格
      2) 生成真实装饰 prefab
      3) 消耗 kit 物品
]]
local function OnDeploy(inst, pt, deployer)
    local grid = TUNING.JM_GRID_SIZE or 1.0
    -- 先吸附再生成，保证多人联机时坐标一致、布局整齐。
    local x = SnapToGrid(pt.x, grid)
    local z = SnapToGrid(pt.z, grid)
    local deco = SpawnPrefab("jm_deco_plant")
    if deco ~= nil then
        deco.Transform:SetPosition(x, 0, z)
    end
    inst:Remove()
end

-- 家具套件（背包物品）构造函数。
local function kit_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    local bank = USE_CUSTOM_PLANT_ANIM and "jm_deco_plant" or FALLBACK_PLANT_ANIM
    local build = USE_CUSTOM_PLANT_ANIM and "jm_deco_plant" or FALLBACK_PLANT_ANIM
    inst.AnimState:SetBank(bank)
    inst.AnimState:SetBuild(build)
    inst.AnimState:PlayAnimation("idle", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    if USE_CUSTOM_KIT_ATLAS then
        inst.components.inventoryitem.imagename = "jm_deco_plant_kit"
        inst.components.inventoryitem.atlasname = "images/inventoryimages/jm_deco_plant_kit.xml"
    else
        inst.components.inventoryitem.imagename = "petals"
        inst.components.inventoryitem.atlasname = "images/inventoryimages.xml"
    end

    inst:AddComponent("deployable")
    -- 使用 CUSTOM 以便我们自己定义“可放置条件”。
    inst.components.deployable:SetDeployMode(DEPLOYMODE.CUSTOM)
    inst.components.deployable.ondeploy = OnDeploy
    inst.components.deployable:SetDeploySpacing(DEPLOYSPACING.NONE)
    inst.components.deployable:SetCustomCanDeployFn(CanDeploy)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("jm_deco_plant_kit", kit_fn, assets)
