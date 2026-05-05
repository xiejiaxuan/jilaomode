local MakeHouseDoorPrefab = require("prefabs/jm_house_common")

return MakeHouseDoorPrefab({
    prefab_name = "jm_pink_house",
    placer_name = "jm_pink_house_placer",
    bank = "jm_pink_house",
    build = "jm_pink_house",
    inside_prefab_name = "jm_pink_house_inside_door",
    inside_bank = "jm_pink_inside_door",
    inside_build = "jm_pink_inside_door",
    inside_scale_tuning = "JM_HOUSE_INSIDE_DOOR_SCALE",
    inside_physics_radius_tuning = "JM_HOUSE_INSIDE_DOOR_PHYSICS_RADIUS",
    assets = {
        Asset("ANIM", "anim/jm_pink_house.zip"),
        Asset("ANIM", "anim/jm_pink_inside_door.zip"),
        Asset("IMAGE", "images/inventoryimages/jm_pink_house.tex"),
        Asset("ATLAS", "images/inventoryimages/jm_pink_house.xml"),
    },
})
