PrefabFiles = {
    "jm_house_door",
    "jm_pink_house",
    "jm_house_collision",
    "jm_interior_wall",
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
local HOUSE_DOOR_FRAME_WIDTH = 256
local HOUSE_DOOR_PIXELS_PER_WORLD_UNIT = 150
local HOUSE_DOOR_VISUAL_HALF_WIDTH = HOUSE_DOOR_SCALE * HOUSE_DOOR_FRAME_WIDTH / HOUSE_DOOR_PIXELS_PER_WORLD_UNIT / 2
local HOUSE_INSIDE_DOOR_SCALE = Math.max(2, HOUSE_DOOR_SCALE * 0.55)
local HOUSE_DOOR_ATLAS = "images/inventoryimages/jm_house_door.xml"
local HOUSE_DOOR_IMAGE = "jm_house_door.tex"
local PINK_HOUSE_ATLAS = "images/inventoryimages/jm_pink_house.xml"
local PINK_HOUSE_IMAGE = "jm_pink_house.tex"
local PLANT_KIT_ATLAS = "images/inventoryimages/jm_deco_plant_kit.xml"
local PLANT_KIT_IMAGE = "jm_deco_plant_kit.tex"

Assets = {
    Asset("ANIM", "anim/jm_house_door.zip"),
    Asset("IMAGE", "images/inventoryimages/jm_house_door.tex"),
    Asset("ATLAS", "images/inventoryimages/jm_house_door.xml"),
    Asset("ANIM", "anim/jm_pink_house.zip"),
    Asset("ANIM", "anim/jm_pink_inside_door.zip"),
    Asset("ANIM", "anim/jm_interior_wall.zip"),
    Asset("IMAGE", "images/inventoryimages/jm_pink_house.tex"),
    Asset("ATLAS", "images/inventoryimages/jm_pink_house.xml"),
}

GLOBAL.TUNING.JM_INTERIOR_SIZE = INTERIOR_SIZE
GLOBAL.TUNING.JM_GRID_SIZE = GRID_SIZE
GLOBAL.TUNING.JM_INTERIOR_DARK_PADDING = 8
GLOBAL.TUNING.JM_INTERIOR_STRIDE = 120
GLOBAL.TUNING.JM_HOUSE_DOOR_SCALE = HOUSE_DOOR_SCALE
GLOBAL.TUNING.JM_HOUSE_DOOR_PHYSICS_RADIUS = 0
GLOBAL.TUNING.JM_HOUSE_DOOR_COLLISION_HALF_WIDTH = Math.max(1, HOUSE_DOOR_VISUAL_HALF_WIDTH * 0.9)
GLOBAL.TUNING.JM_HOUSE_DOOR_COLLISION_DEPTH = Math.max(0.9, HOUSE_DOOR_SCALE * 0.18)
GLOBAL.TUNING.JM_HOUSE_COLLISION_BLOCKER_RADIUS = 0.45
GLOBAL.TUNING.JM_HOUSE_DOOR_MIN_SPACING = Math.max(2, HOUSE_DOOR_VISUAL_HALF_WIDTH * 0.9)
GLOBAL.TUNING.JM_HOUSE_INSIDE_DOOR_SCALE = HOUSE_INSIDE_DOOR_SCALE
GLOBAL.TUNING.JM_HOUSE_INSIDE_DOOR_PHYSICS_RADIUS = Math.max(0.5, HOUSE_INSIDE_DOOR_SCALE * 0.35)
GLOBAL.TUNING.JM_INTERIOR_WALL_SCALE = 1.2
GLOBAL.TUNING.JM_INTERIOR_WALL_PHYSICS_RADIUS = 0.65

ModImportForMod("scripts/jm_strings.lua")

if SoftResolveFilePath(HOUSE_DOOR_ATLAS) ~= nil then
    RegisterInventoryItemAtlas(HOUSE_DOOR_ATLAS, HOUSE_DOOR_IMAGE)
end

if SoftResolveFilePath(PINK_HOUSE_ATLAS) ~= nil then
    RegisterInventoryItemAtlas(PINK_HOUSE_ATLAS, PINK_HOUSE_IMAGE)
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
        min_spacing = GLOBAL.TUNING.JM_HOUSE_DOOR_MIN_SPACING,
    },
    { "STRUCTURES" }
)

AddRecipe2(
    "jm_pink_house",
    {
        Ingredient("boards", 4),
        Ingredient("cutstone", 4),
    },
    GLOBAL.TECH.SCIENCE_ONE,
    {
        atlas = PINK_HOUSE_ATLAS,
        image = PINK_HOUSE_IMAGE,
        placer = "jm_pink_house_placer",
        min_spacing = GLOBAL.TUNING.JM_HOUSE_DOOR_MIN_SPACING,
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
