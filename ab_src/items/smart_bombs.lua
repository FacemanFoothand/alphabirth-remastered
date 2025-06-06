----------------------------------------------------------------------------
-- Item: Smart Bombs
-- Originally from Pack 3
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local utils = include("ab_src.modules.utils")
local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")

local smart_bombs = Item("Smart Bombs") ---@type Item
smart_bombs.desc = include("ab_src.integrations.eid").smart_bombs
smart_bombs.Flag = Flag("smart_bomb_flag") ---@type Flag

local DOOR_SLOTS = {
    DoorSlot.LEFT0,
    DoorSlot.UP0,
    DoorSlot.RIGHT0,
    DoorSlot.DOWN0,
    DoorSlot.LEFT1,
    DoorSlot.UP1,
    DoorSlot.RIGHT1,
    DoorSlot.DOWN1,
}

---@param player EntityPlayer
smart_bombs:AddCallback("ITEM_PICKUP", function(player)
    player:AddBombs(5)
end)

---@param _ EntityPlayer
---@param bomb EntityBomb
smart_bombs:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(_, bomb)
    local room = g.room
    if bomb.SpawnerType == EntityType.ENTITY_PLAYER and not smart_bombs.Flag:EntityHas(bomb) and room:IsClear() then
        local target_entity ---@type GridEntity|nil
        ---@param entity GridEntity
        for _, entity in pairs(utils.get_grid_entities()) do
            for _, slot in pairs(DOOR_SLOTS) do
                local door = room:GetDoor(slot) ---@type GridEntityDoor
                if door and door.State ~= 2 then
                    if
                        door:IsRoomType(RoomType.ROOM_SECRET)
                        or door:IsRoomType(RoomType.ROOM_ULTRASECRET)
                        or door:IsRoomType(RoomType.ROOM_SUPERSECRET)
                    then
                        target_entity = door
                    end
                end
            end

            if entity:ToRock() then --It must be a rock
                local rock_index = entity:GetGridIndex()
                if rock_index == room:GetDungeonRockIdx() then
                    target_entity = entity
                    break
                elseif rock_index == room:GetTintedRockIdx() then
                    target_entity = entity
                    break
                end
            end
        end

        if target_entity ~= nil then
            if (not target_entity:ToRock()) and target_entity.State == 2 then
                target_entity = nil
            else
                smart_bombs.Flag:Apply(bomb)
                bomb:GetData().target = target_entity
                bomb:GetData().init = false
            end
        end
    end
end)

---@param _ EntityPlayer
---@param bomb EntityBomb
smart_bombs:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
    if smart_bombs.Flag:EntityHas(bomb) then
        local sprite = bomb:GetSprite() ---@type Sprite
        if not bomb:GetData().init then
            sprite:Load("gfx/animations/familiars/animation_familiar_smartbombs.anm2", true)
            sprite:Play("LegsAppear", true)
            bomb:GetData().init = true
        end
        if bomb.FrameCount % 20 == 1 then
            if not sprite:IsPlaying("LegsAppear") and not sprite:IsPlaying("PulseWalk") then
                sprite:Play("PulseWalk", true)
            end
            if sprite:IsPlaying("PulseWalk") then
                local target_position = bomb:GetData().target.Position ---@type Vector
                local direction_vector = (target_position - bomb.Position):Normalized()
                local angle = direction_vector:GetAngleDegrees() + math.random(-50, 50)
                bomb.Velocity = bomb.Velocity + (Vector.FromAngle(angle) * 5)
            end
        end
    end
end)

return smart_bombs
