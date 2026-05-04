PrefabFiles = {
    "jm_house_door",
    "jm_deco_plant",
    "jm_deco_plant_kit",
}

local MOD_NAME = modname
local GetModConfigDataForMod = GetModConfigData
local ModImportForMod = modimport
local Ingredient = GLOBAL.Ingredient
local SoftResolveFilePath = GLOBAL.softresolvefilepath
local RegisterInventoryItemAtlas = GLOBAL.RegisterInventoryItemAtlas
local Math = GLOBAL.math

local INTERIOR_SIZE = GetModConfigDataForMod("interior_size", MOD_NAME) or 10
local GRID_SIZE = GetModConfigDataForMod("grid_size", MOD_NAME) or 1.0
local HOUSE_DOOR_SCALE = GetModConfigDataForMod("house_door_scale", MOD_NAME) or 5
local HOUSE_DOOR_ATLAS = "images/inventoryimages/jm_house_door.xml"
local HOUSE_DOOR_IMAGE = "jm_house_door.tex"
local PLANT_KIT_ATLAS = "images/inventoryimages/jm_deco_plant_kit.xml"
local PLANT_KIT_IMAGE = "jm_deco_plant_kit.tex"

Assets = {
    Asset("ANIM", "anim/jm_house_door.zip"),
    Asset("IMAGE", "images/inventoryimages/jm_house_door.tex"),
    Asset("ATLAS", "images/inventoryimages/jm_house_door.xml"),
}

GLOBAL.TUNING.JM_INTERIOR_SIZE = INTERIOR_SIZE
GLOBAL.TUNING.JM_GRID_SIZE = GRID_SIZE
GLOBAL.TUNING.JM_INTERIOR_STRIDE = 40
GLOBAL.TUNING.JM_HOUSE_DOOR_SCALE = HOUSE_DOOR_SCALE
GLOBAL.TUNING.JM_HOUSE_DOOR_PHYSICS_RADIUS = Math.max(1, HOUSE_DOOR_SCALE * 0.5)

ModImportForMod("scripts/jm_strings.lua")

if SoftResolveFilePath(HOUSE_DOOR_ATLAS) ~= nil then
    RegisterInventoryItemAtlas(HOUSE_DOOR_ATLAS, HOUSE_DOOR_IMAGE)
end

if SoftResolveFilePath(PLANT_KIT_ATLAS) ~= nil then
    RegisterInventoryItemAtlas(PLANT_KIT_ATLAS, PLANT_KIT_IMAGE)
end

AddPrefabPostInit("world", function(inst)
    if not GLOBAL.TheWorld.ismastersim then
        return
    end
    if inst.components.jm_interiormanager == nil then
        inst:AddComponent("jm_interiormanager")
    end
end)

AddRecipe2(
    "jm_house_door",
    {
        Ingredient("boards", 4),
        Ingredient("cutstone", 4),
    },
    GLOBAL.TECH.SCIENCE_ONE,
    {
        atlas = HOUSE_DOOR_ATLAS,
        image = HOUSE_DOOR_IMAGE,
        placer = "jm_house_door_placer",
        min_spacing = 2,
    },
    { "STRUCTURES" }
)

AddRecipe2(
    "jm_deco_plant_kit",
    {
        Ingredient("cutgrass", 6),
        Ingredient("twigs", 3),
    },
    GLOBAL.TECH.NONE,
    {
        image = "petals.tex",
        numtogive = 1,
    },
    { "DECOR" }
)
