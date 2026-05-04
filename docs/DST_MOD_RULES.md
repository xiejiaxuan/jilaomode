# DST Mod Coding Rules

This file records the project rules learned while debugging `Build/luxury_courtyard`.

## File Encoding

- Keep Lua and Markdown files as UTF-8 without BOM.
- When reading files from PowerShell, use explicit UTF-8 to avoid false mojibake:

```powershell
$enc = New-Object System.Text.UTF8Encoding($false)
$text = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath "path\to\file.lua"), $enc)
```

## `modmain.lua` Environment

- Do not wrap the whole `modmain.lua` with `GLOBAL.setfenv(1, GLOBAL)`.
- Keep the mod environment so DST mod APIs remain available:
  - `AddPrefabPostInit`
  - `AddRecipe2`
  - `modimport`
  - `GetModConfigData`
- For game globals, use `GLOBAL.*` explicitly.

Good pattern:

```lua
local MOD_NAME = modname
local GetModConfigDataForMod = GetModConfigData
local ModImportForMod = modimport
local Ingredient = GLOBAL.Ingredient

local INTERIOR_SIZE = GetModConfigDataForMod("interior_size", MOD_NAME) or 10

GLOBAL.TUNING.JM_INTERIOR_SIZE = INTERIOR_SIZE

ModImportForMod("scripts/jm_strings.lua")
```

## Imported Scripts

- Files imported by `modimport` may need explicit `GLOBAL` access.
- For string files, bind `STRINGS` explicitly:

```lua
local STRINGS = GLOBAL.STRINGS
```

## Assets And Fallbacks

- Do not declare `Asset(...)` for files that may not exist.
- If a custom asset is optional, check it first and only then insert the asset.

```lua
local USE_CUSTOM = softresolvefilepath("anim/my_anim.zip") ~= nil
local assets = {
    Asset("ANIM", "anim/known_existing_fallback.zip"),
}

if USE_CUSTOM then
    table.insert(assets, Asset("ANIM", "anim/my_anim.zip"))
end
```

- Confirm fallback assets really exist in DST's `data/anim` folder.
- `anim/pottedfern.zip` does not exist in the current local DST install.
- `anim/cave_ferns_potted.zip` does exist and is usable as a plant fallback.

## Animation Banks

- A zip existing on disk is not enough. Its internal bank/build names must match `AnimState:SetBank()` and `AnimState:SetBuild()`.
- If logs show `Could not find anim bank [name]`, temporarily fall back to a known vanilla bank while fixing the custom animation package.
- For single-image custom anims built with Klei `buildanimation.py`, keep the names aligned across all layers:
  - `build.xml`: `<Build name="jm_house_door">`
  - Lua: `AnimState:SetBank("jm_house_door")` and `AnimState:SetBuild("jm_house_door")`
  - `animation.xml`: animation `root` should match the bank expected by Lua.
- If an entity is invisible but still blocks movement, check `client_log.txt` first for `Could not find anim bank [name]`.
- For large building sprites, tune the animation/build anchor, not just `AnimState:SetScale`.
  - If the visible sprite appears far below the entity/collision point, the frame anchor is likely too high.
  - For the current house-door PNG, `build.xml` uses `y="-128"` so the bottom-center of the 256x256 sprite sits near the entity origin.
  - Keep `animation.xml` frame bounds consistent with the chosen anchor to avoid selection/culling weirdness.

Current house-door source convention:

```xml
<Build name="jm_house_door">
  <Symbol name="house">
    <Frame framenum="0" duration="1" x="0" y="-128" w="256" h="256" image="house/house-0"/>
  </Symbol>
</Build>
```

```xml
<anim name="close" root="jm_house_door" framerate="30">
  <frame x="0" y="-128" w="256" h="256">
    <element name="house" frame="0" layername="house" m_a="1" m_b="0" m_c="0" m_d="1" m_tx="0" m_ty="0" z_index="0"/>
  </frame>
</anim>
```

## Map Tiles

- `TheWorld.Map:SetTile(x, y, tile)` expects tile coordinates, not world coordinates.
- Convert world position first:

```lua
local tx, tz = TheWorld.Map:GetTileCoordsAtPoint(world_x, 0, world_z)
TheWorld.Map:SetTile(tx, tz, WORLD_TILES.WOODFLOOR)
```

- Check bounds before editing map tiles:

```lua
if not TheWorld.Map:IsInMapBounds(world_x, 0, world_z) then
    return
end
```

- Avoid hardcoded far coordinates like `-2500, -2500` unless bounds are guaranteed.

## Recipe Icons

- If a prefab has no custom inventory atlas, specify a known vanilla `image` in `AddRecipe2` options.

```lua
AddRecipe2(
    "my_prefab",
    ingredients,
    GLOBAL.TECH.NONE,
    {
        image = "petals.tex",
    },
    { "DECOR" }
)
```

- Repeated warnings like `Could not find region 'my_prefab.tex' from atlas 'images/inventoryimages4.xml'` mean the recipe UI is looking for an icon that does not exist.
- For custom recipe/inventory icons, create and register both `.tex` and `.xml`.
- Register the atlas in `modmain.lua`, and pass both `atlas` and `image` to `AddRecipe2`.

```lua
local HOUSE_DOOR_ATLAS = "images/inventoryimages/jm_house_door.xml"
local HOUSE_DOOR_IMAGE = "jm_house_door.tex"

RegisterInventoryItemAtlas(HOUSE_DOOR_ATLAS, HOUSE_DOOR_IMAGE)

AddRecipe2("jm_house_door", ingredients, GLOBAL.TECH.SCIENCE_ONE, {
    atlas = HOUSE_DOOR_ATLAS,
    image = HOUSE_DOOR_IMAGE,
    placer = "jm_house_door_placer",
}, { "STRUCTURES" })
```

## Teleporter Interaction

- A `teleporter` component alone is not enough for player click interaction.
- The vanilla component action checks for the `teleporter` tag before adding `ACTIONS.JUMPIN`.
- Prefer using `components.teleporter:Target(other)` instead of assigning `targetTeleporter` directly, because the setter updates active state and tags.

```lua
inst:AddComponent("teleporter")
inst.components.teleporter.onActivate = OnActivate
inst.components.teleporter:Target(inside)
inside.components.teleporter:Target(inst)
```

- Add a zero-delay pairing fallback for buildable paired doors, so an entity created without the expected `onbuilt` event still gets a destination:

```lua
inst:ListenForEvent("onbuilt", OnBuilt)
inst:DoTaskInTime(0, EnsurePairedDoor)
```

- Guard against recursive pairing by checking an inside-door flag before spawning the paired door.

## Mod Configuration

- Put tunable visual/debug values in `modinfo.lua` configuration options instead of hardcoding them.
- Read config with the current mod name:

```lua
local MOD_NAME = modname
local HOUSE_DOOR_SCALE = GetModConfigData("house_door_scale", MOD_NAME) or 5
GLOBAL.TUNING.JM_HOUSE_DOOR_SCALE = HOUSE_DOOR_SCALE
GLOBAL.TUNING.JM_HOUSE_DOOR_PHYSICS_RADIUS = GLOBAL.math.max(1, HOUSE_DOOR_SCALE * 0.5)
```

- Keep visual scale and physics radius in sync. Otherwise the building may look huge while the collision/interaction point still feels tiny.

## Headless Validation

Use the nullrenderer dedicated server for fast mod loading checks:

```powershell
& "E:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\bin64\dontstarve_dedicated_server_nullrenderer_x64.exe" `
  -persistent_storage_root "$env:USERPROFILE\Documents\Klei\DoNotStarveTogether" `
  -conf_dir "1153187325" `
  -cluster "Cluster_5" `
  -shard "Master"
```

Important notes:

- `LOADING LUA SUCCESS` means Lua startup passed.
- `ModIndex: Load sequence finished successfully` means mod registration passed.
- `E_INVALID_TOKEN` or missing `cluster_token.txt` is a dedicated server auth issue, not a mod loading issue.
- Run the executable from DST's `bin64` working directory. If it is started from the repo directory, it may fail before mod loading with `Could not load lua file scripts/main.lua`.
- Stop leftover nullrenderer processes after test runs:

```powershell
Get-Process |
  Where-Object { $_.ProcessName -like "dontstarve_dedicated_server_nullrenderer*" } |
  Stop-Process -Force
```

## Log Locations

Client log:

```text
C:\Users\Administrator\Documents\Klei\DoNotStarveTogether\client_log.txt
```

Cluster 5 Master server log:

```text
C:\Users\Administrator\Documents\Klei\DoNotStarveTogether\1153187325\Cluster_5\Master\server_log.txt
```

Useful search terms:

```text
luxury_courtyard
MOD ERROR
LUA ERROR
stack traceback
error calling
Disabling
Could not find
Could not find anim bank
Could not find region
```

## Current Project Lessons

- Keep loading issues separate from runtime issues:
  - Loading: `modmain`, strings, prefab registration, asset declaration.
  - Runtime: building, deploying, teleporting, map tile editing, save/load.
- Headless validation catches loading and prefab registration quickly.
- In-game client logs are still needed for runtime actions such as crafting, placing, teleporting, and deploying.
- When testing local DST, remember the game loads the copied mod directory under:

```text
E:\Program Files (x86)\Steam\steamapps\common\Don't Starve Together\mods\luxury_courtyard
```

  Sync changed files there before testing in game, or package/copy the whole mod directory.
- Fully restart the world/game after changing `.zip` animation resources. DST often keeps old anim banks loaded during the current session.
