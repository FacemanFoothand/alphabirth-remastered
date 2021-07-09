----------------------------------------------------------------------------
-- Item: Green Candle
-- Originally from Pack 1
-- Fire a green fire and poison nearby enemies
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")
local utils = include("ab_src.modules.utils")

local green_candle = Item("Green Candle")
local flame_entity = EntityConfig("Green Candle", 20)
green_candle.poison_range = 120
green_candle.poison_duration = 120

utils.mixTables(g.defaultPlayerSaveData, {
	holding_green_candle = false
})

green_candle:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	local save = g.getPlayerSave(player)
	player:AnimateCollectible(green_candle.ID, "LiftItem", "PlayerPickup")
	save.holding_green_candle = true
end)

green_candle:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
	local save = g.getPlayerSave(player)
	if save.holding_green_candle then
		local direction = player:GetFireDirection()
		local direction_vector = utils.getVectorFromDirection(direction)

		if direction_vector ~= utils.VECTOR_ZERO then
			local firevelocity = (direction_vector * player.ShotSpeed) * 28
			flame_entity:Spawn(
				player.Position,
				firevelocity,
				player
			)

			player:AnimateCollectible(green_candle.ID, "HideItem", "PlayerPickup")
			save.holding_green_candle = false
		end
	end
end)

flame_entity:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function (entity, effect, effect_variant)
	for _, target in ipairs(Isaac:GetRoomEntities()) do
		local distance_to_enemy = entity.Position:Distance(target.Position)
		if target:IsVulnerableEnemy() and distance_to_enemy < green_candle.poison_range then
			local player = (entity.SpawnerEntity):ToPlayer()
			target:AddPoison(
				EntityRef(player),
				green_candle.poison_duration,
				player.Damage
			)
		end
	end
end)

return green_candle