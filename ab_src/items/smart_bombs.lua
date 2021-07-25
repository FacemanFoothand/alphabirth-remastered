----------------------------------------------------------------------------
-- Item: Smart Bombs
-- Originally from Pack 3
----------------------------------------------------------------------------
include("alpha_api.lua")
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")

local smartBombs = Item("Smart Bombs")

local FLAG_SMART_BOMB = AlphaAPI.createFlag()
local DOOR_SLOTS = {
    DoorSlot.LEFT0,
    DoorSlot.UP0,
    DoorSlot.RIGHT0,
    DoorSlot.DOWN0,
    DoorSlot.LEFT1,
    DoorSlot.UP1,
    DoorSlot.RIGHT1,
    DoorSlot.DOWN1
}

smartBombs:AddCallback("ITEM_PICKUP", function(player)
	player:AddBombs(5)
end)

smartBombs:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(player, bomb, bomb_variant)
    local room = g.room
    if player:HasCollectible(smartBombs.ID)
    and bomb.SpawnerType == EntityType.ENTITY_PLAYER
    and not AlphaAPI.hasFlag(bomb, FLAG_SMART_BOMB)
    and room:IsClear() then
        local target_entity
        for i, entity in pairs(AlphaAPI.entities.grid) do
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

        for _, slot in pairs(DOOR_SLOTS) do
            local door = room:GetDoor(slot)
            if door then
                if door:IsRoomType(RoomType.ROOM_SECRET) or door:IsRoomType(RoomType.ROOM_SUPERSECRET) then
                   target_entity = door
                    break
                end
            end
        end

        if target_entity ~= nil then
            if target_entity.State == 2 then
                target_entity = nil
            else
                local smart_bomb = bomb:ToBomb()
                AlphaAPI.addFlag(smart_bomb, FLAG_SMART_BOMB)
                smart_bomb:GetData().target = target_entity
                local sprite = smart_bomb:GetSprite()
                sprite:Load("gfx/animations/familiars/animation_familiar_smartbombs.anm2", true)
                sprite:Play("LegsAppear", true)
            end
        end
    end
end)

smartBombs:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(player, bomb, bomb_variant)
    local entity = bomb
    if AlphaAPI.hasFlag(entity, FLAG_SMART_BOMB) then
        if entity.FrameCount % 20 == 1 then
            local sprite = entity:GetSprite()
            if not sprite:IsPlaying("LegsAppear") and not sprite:IsPlaying("PulseWalk") then
                sprite:Play("PulseWalk", true)
            end
            if sprite:IsPlaying("PulseWalk") then
                local target_position = entity:GetData().target.Position
                local direction_vector = (target_position - entity.Position):Normalized()
                local angle = direction_vector:GetAngleDegrees() + math.random(-50, 50)
                entity.Velocity = entity.Velocity + (Vector.FromAngle(angle) * 6)
            end
        end
    end
end)
