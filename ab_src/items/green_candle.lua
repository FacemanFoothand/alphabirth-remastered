----------------------------------------------------------------------------
-- Item: Green Candle
-- Originally from Pack 1
-- Fire a green fire and poison nearby enemies
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")
local utils = include("ab_src.modules.utils")

local green_candle = Item("Green Candle") ---@type Item
green_candle.desc = include("ab_src.integrations.eid").green_candle
green_candle.Flame = EntityConfig("Green Candle", 20) ---@type EntityConfig
green_candle.Flame.poison_range = 80
green_candle.Flame.poison_duration = 120

utils.mixTables(g.defaultPlayerSaveData, {
    holding_green_candle = false,
})

---@param player EntityPlayer
green_candle:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, player)
    local save = g.getPlayerSave(player)
    player:AnimateCollectible(green_candle.ID, "LiftItem", "PlayerPickup")
    save.holding_green_candle = true
end)

---@param player EntityPlayer
green_candle:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player)
    local save = g.getPlayerSave(player)
    if save.holding_green_candle then
        local direction = player:GetFireDirection()
        local direction_vector = utils.getVectorFromDirection(direction)
        if direction_vector ~= Vector.Zero then
            local d = player:GetLastDirection()
            local fire_velocity = (d * player.ShotSpeed) * 28
            green_candle.Flame:Spawn(player.Position, fire_velocity, player)
            player:AnimateCollectible(green_candle.ID, "HideItem", "PlayerPickup")
            save.holding_green_candle = false
        end
    end
end)

---@param entity Entity
green_candle.Flame:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(entity)
    for _, target in ipairs(Isaac:GetRoomEntities()) do
        local distance_to_enemy = entity.Position:Distance(target.Position)
        if target:IsVulnerableEnemy() and distance_to_enemy < green_candle.poison_range then
            local player = (entity.SpawnerEntity):ToPlayer() or {}
            target:AddPoison(EntityRef(player), green_candle.poison_duration, player.Damage)
        end
    end
end)

return green_candle
