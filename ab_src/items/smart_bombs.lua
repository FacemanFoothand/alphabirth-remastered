----------------------------------------------------------------------------
-- Item: Smart Bombs
-- Originally from Pack 3
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local utils = include("ab_src.modules.utils")
local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")

local desc = {
    ["en_us"] = {"Smart Bombs", "{{ArrowUp}} +5 Bombs#If placed after room clear the bomb will walk towards vulnerable secrets#It will seek out {{SecretRoom}} Secret Rooms, {{SoulHeart}} Tinted Rocks and {{MinecartRoom}} Crawlspaces"},
    ["pt_br"] = {"Bombas Inteligentes", "{{ArrowUp}} +5 Bombas#Se usadas depois de o quarto estiver limpo as bombas andarão até segredos#Irão procurar {{SecretRoom}} Quartos Secretos, {{SoulHeart}} Rochas Tingidas e {{MinecartRoom}} Crawlspaces"},
}

local smart_bombs = Item("Smart Bombs", desc)
smart_bombs.Flag = Flag("smart_bomb_flag")

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

smart_bombs:AddCallback("ITEM_PICKUP", function(player)
	player:AddBombs(5)
end)

smart_bombs:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(player, bomb, bomb_variant)
    local room = g.room
    if bomb.SpawnerType == EntityType.ENTITY_PLAYER
    and not smart_bombs.Flag:EntityHas(bomb)
    and room:IsClear() then
        local target_entity
        for i, entity in pairs(utils.get_grid_entities()) do
            for _, slot in pairs(DOOR_SLOTS) do
                local door = room:GetDoor(slot)
                if door and door.State ~= 2 then
                    if door:IsRoomType(RoomType.ROOM_SECRET)
                    or door:IsRoomType(RoomType.ROOM_ULTRASECRET)
                    or door:IsRoomType(RoomType.ROOM_SUPERSECRET) then
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
                local smart_bomb = bomb:ToBomb()
                smart_bombs.Flag:Apply(smart_bomb)
                smart_bomb:GetData().target = target_entity
                smart_bomb:GetData().init = false
            end
        end
    end
end)

smart_bombs:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(player, bomb, bomb_variant)
    local entity = bomb
    if smart_bombs.Flag:EntityHas(entity) then
        local sprite = bomb:GetSprite()
        if not entity:GetData().init then
            sprite:Load("gfx/animations/familiars/animation_familiar_smartbombs.anm2", true)
            sprite:Play("LegsAppear", true)
            entity:GetData().init = true
        end
        if entity.FrameCount % 20 == 1 then
            if not sprite:IsPlaying("LegsAppear") and not sprite:IsPlaying("PulseWalk") then
                sprite:Play("PulseWalk", true)
            end
            if sprite:IsPlaying("PulseWalk") then
                local target_position = entity:GetData().target.Position
                local direction_vector = (target_position - entity.Position):Normalized()
                local angle = direction_vector:GetAngleDegrees() + math.random(-50, 50)
                entity.Velocity = entity.Velocity + (Vector.FromAngle(angle) * 8)
            end
        end
    end
end)

return smart_bombs
