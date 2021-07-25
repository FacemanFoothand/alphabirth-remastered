----------------------------------------------------------------------------
-- Item: Alastor's Candle
-- Originally from Pack 3
-- Spawn 2 Spinning Flames
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")

local alastorsCandle = Item("Alastor's Candle")
alastorsCandle.Flame = EntityConfig("Alastor's Flame")

alastorsCandle:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
        return
    end

    local offset
    for i = 1, 2 do
        local flame = alastorsCandle.Flame:Spawn(player.Position, Vector(0,0), nil)
        local data = flame:GetData()
        if i == 1 then
            offset = math.pi
        elseif i == 2 then
            offset = 0
        end
        data.offset = offset
        data.roomIdx = g.level:GetCurrentRoomIndex()
        data.center_distance = 100
    end

    return true
end)

alastorsCandle.Flame:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(familiar)
    local data = familiar:GetData()
    local room = g.room
    local player = familiar:ToFamiliar().Player
    local room_index = g.level:GetCurrentRoomIndex()

    local frame = g.game:GetFrameCount()

    if not data.dist_modifier then
        data.dist_modifier = 1
    end

    if data.roomIdx ~= room_index or room:GetFrameCount() == 1 then
        familiar:Remove()
    end

    if data.center_distance == 100 then
        data.dist_modifier = 1
    elseif data.center_distance == 30 then
        data.dist_modifier = -1
    end

    local off = (frame / 10) + data.offset

    local x_offset = math.cos(off) * data.center_distance
    local y_offset = math.sin(off) * data.center_distance
    familiar.Velocity = Vector(player.Position.X + x_offset, player.Position.Y + y_offset) - familiar.Position

    data.center_distance = data.center_distance - data.dist_modifier

    --Add Fear to Nearby entities
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsEnemy() then
            if entity.Position:Distance(familiar.Position) < 60 and math.random(100) == 1 then
                entity:AddFear(EntityRef(familiar), 60)
            end
        end
    end
end)

return alastorsCandle