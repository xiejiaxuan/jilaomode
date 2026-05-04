local JMInteriorManager = Class(function(self, inst)
    self.inst = inst
    -- 下一个可用室内槽位 ID（自增）。
    self.next_id = 1
    -- 仅用于记录已分配的槽位，便于存档恢复。
    self.slots = {}
end)

--[[
    EnsureInteriorGround(center, size)
    作用:
      在室内中心点周围铺一块方形地板，作为可活动区域。
    参数:
      center (Vector3) - 室内中心坐标
      size   (number)  - 边长（格）
    返回:
      无
]]
-- 在目标位置铺一块木地板，作为“室内可活动区域”。
local function EnsureInteriorGround(center, size)
    if TheWorld == nil or TheWorld.Map == nil then
        return
    end
    if TheWorld.Map.GetTileCoordsAtPoint == nil or TheWorld.Map.GetTileCenterPoint == nil then
        return
    end
    if not TheWorld.Map:IsInMapBounds(center.x, 0, center.z) then
        return
    end

    local center_tx, center_tz = TheWorld.Map:GetTileCoordsAtPoint(center.x, 0, center.z)
    local half = math.floor(size / 2)
    for x = -half, half do
        for z = -half, half do
            local tx = center_tx + x
            local tz = center_tz + z
            local world_x, world_y, world_z = TheWorld.Map:GetTileCenterPoint(tx, tz)
            world_z = world_z or world_y
            if world_x ~= nil and TheWorld.Map:IsInMapBounds(world_x, 0, world_z) then
                TheWorld.Map:SetTile(tx, tz, WORLD_TILES.WOODFLOOR)
            end
        end
    end
end

--[[
    BuildSlotPosition(id)
    作用:
      把室内槽位 ID 映射成实际世界坐标。
      这里“室内”并不是新地图，而是同一张地图上的远端区域。
    参数:
      id (number) - 槽位编号
    返回:
      Vector3 - 该槽位对应的世界坐标
]]
-- 把槽位 ID 映射到实际世界坐标（同一张地图里的隐藏区域）。
local function BuildSlotPosition(id)
    if TheWorld ~= nil and TheWorld.Map ~= nil and TheWorld.Map.GetSize ~= nil and TheWorld.Map.GetTileCenterPoint ~= nil then
        local map_width, map_height = TheWorld.Map:GetSize()
        if map_width ~= nil and map_height ~= nil and map_width > 0 and map_height > 0 then
            local tile_scale = TILE_SCALE or 4
            local interior_size = TUNING.JM_INTERIOR_SIZE or 10
            local stride_world = TUNING.JM_INTERIOR_STRIDE or 40
            local stride_tiles = math.max(interior_size + 8, math.ceil(stride_world / tile_scale))
            local margin = math.max(interior_size + 8, stride_tiles)
            local usable_width = math.max(1, map_width - margin * 2)
            local usable_height = math.max(1, map_height - margin * 2)
            local slots_per_row = math.max(1, math.floor(usable_width / stride_tiles))
            local rows = math.max(1, math.floor(usable_height / stride_tiles))
            local index = math.max(0, (id or 1) - 1)
            local tx = margin + (index % slots_per_row) * stride_tiles
            local tz = margin + (math.floor(index / slots_per_row) % rows) * stride_tiles
            local world_x, world_y, world_z = TheWorld.Map:GetTileCenterPoint(tx, tz)
            world_z = world_z or world_y

            if world_x ~= nil and TheWorld.Map:IsInMapBounds(world_x, 0, world_z) then
                return Vector3(world_x, 0, world_z)
            end
        end
    end

    local stride = TUNING.JM_INTERIOR_STRIDE or 40
    local start_x = TUNING.JM_INTERIOR_START_X or -2500
    local start_z = TUNING.JM_INTERIOR_START_Z or -2500
    return Vector3(start_x + (id * stride), 0, start_z)
end

--[[
    JMInteriorManager:AllocateSlot()
    作用:
      为新建筑分配一个全新室内槽位，并铺地板。
    参数:
      无
    返回:
      id  (number)  - 新槽位 ID
      pos (Vector3) - 新槽位坐标
]]
function JMInteriorManager:AllocateSlot()
    -- 分配新槽位：给新建房门使用。
    local id = self.next_id
    self.next_id = self.next_id + 1
    self.slots[id] = true
    local pos = BuildSlotPosition(id)
    EnsureInteriorGround(pos, TUNING.JM_INTERIOR_SIZE or 10)
    return id, pos
end

--[[
    JMInteriorManager:GetSlotPosition(id)
    作用:
      获取已有槽位的坐标（常用于读档恢复后重新定位）。
    参数:
      id (number) - 槽位 ID
    返回:
      pos (Vector3|nil) - 槽位坐标；id 无效时返回 nil
]]
function JMInteriorManager:GetSlotPosition(id)
    -- 按已有 ID 取坐标：给读档恢复或后续扩展使用。
    if id == nil then
        return nil
    end
    self.slots[id] = true
    local pos = BuildSlotPosition(id)
    EnsureInteriorGround(pos, TUNING.JM_INTERIOR_SIZE or 10)
    return pos
end

--[[
    JMInteriorManager:OnSave()
    作用:
      将组件关键状态写入存档。
    返回:
      table - 可序列化数据
]]
function JMInteriorManager:OnSave()
    -- 只保存必要状态，避免存档膨胀。
    return {
        next_id = self.next_id,
        slots = self.slots,
    }
end

--[[
    JMInteriorManager:OnLoad(data)
    作用:
      从存档恢复组件状态。
    参数:
      data (table|nil) - OnSave 保存的数据
    返回:
      无
]]
function JMInteriorManager:OnLoad(data)
    if data == nil then
        return
    end
    self.next_id = data.next_id or self.next_id
    self.slots = data.slots or self.slots
end

return JMInteriorManager
