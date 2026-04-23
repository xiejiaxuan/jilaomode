PrefabFiles = {
    "jm_house_door",
    "jm_deco_plant",
    "jm_deco_plant_kit",
}

GLOBAL.setfenv(1, GLOBAL)

-- 从 mod 配置读取参数，便于后续在创世界界面调节。
local INTERIOR_SIZE = GetModConfigData("interior_size") or 10
local GRID_SIZE = GetModConfigData("grid_size") or 1.0

-- 统一放到 TUNING，方便各 prefab / component 共享。
TUNING.JM_INTERIOR_SIZE = INTERIOR_SIZE
TUNING.JM_GRID_SIZE = GRID_SIZE
-- 室内区放在地图远端，减少和正常出生区重叠的概率。
TUNING.JM_INTERIOR_START_X = -2500
TUNING.JM_INTERIOR_START_Z = -2500
-- 每个室内实例在 X 轴上间隔这么远，避免互相覆盖。
TUNING.JM_INTERIOR_STRIDE = 40

modimport("scripts/jm_strings.lua")

-- 若已放入自定义图标图集，则注册给背包系统使用。
if softresolvefilepath("images/inventoryimages/jm_deco_plant_kit.xml") ~= nil then
    RegisterInventoryItemAtlas("images/inventoryimages/jm_deco_plant_kit.xml", "jm_deco_plant_kit.tex")
end

AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    if inst.components.jm_interiormanager == nil then
        -- 世界级组件：负责“一个门对应一个室内槽位”的分配。
        inst:AddComponent("jm_interiormanager")
    end
end)

-- 建筑入口门配方。
AddRecipe2(
    "jm_house_door",
    {
        Ingredient("boards", 4),
        Ingredient("cutstone", 4),
    },
    TECH.SCIENCE_ONE,
    {
        placer = "jm_house_door_placer",
        min_spacing = 2,
    },
    { "STRUCTURES" }
)

-- 装饰家具（盆栽）套件配方。
AddRecipe2(
    "jm_deco_plant_kit",
    {
        Ingredient("cutgrass", 6),
        Ingredient("twigs", 3),
    },
    TECH.NONE,
    {
        numtogive = 1,
    },
    { "DECOR" }
)
