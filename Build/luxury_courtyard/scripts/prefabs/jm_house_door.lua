local MakeHouseDoorPrefab = require("prefabs/jm_house_common")

return MakeHouseDoorPrefab({
    prefab_name = "jm_house_door",
    placer_name = "jm_house_door_placer",
    bank = "jm_house_door",
    build = "jm_house_door",
    assets = {
        Asset("ANIM", "anim/jm_house_door.zip"),
        Asset("IMAGE", "images/inventoryimages/jm_house_door.tex"),
        Asset("ATLAS", "images/inventoryimages/jm_house_door.xml"),
    },
})
