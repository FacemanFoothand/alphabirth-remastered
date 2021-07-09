----------------------------------------------------------------------------
-- Item: Trash Bag
-- Originally from Pack 1
-- 28% chance for 3 blue flies, 28% chance for 3 blue spiders,
-- 41% chance for a random pickup, 3% chance for a trinket
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local trash_bag = Item("Trash Bag")

trash_bag:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
		-- Always spawns either spiders or flies
	-- 25% chance to spawn extra spiders, 25% for extra flies,
	-- 50% to spawn a pickup, 3% to spawn a pickup, 0.2% to spawn an item
	local spider_fly_chance = utils.random(1, 2)
	if spider_fly_chance == 1 then
		for i = 1, utils.random(1, 4) do
			player:AddBlueSpider(player.Position)
		end
	else
		player:AddBlueFlies(utils.random(1, 4),
			player.Position,
			nil)
	end

	local blue_fly_chance = utils.random(1, 4)
	if blue_fly_chance == 1 then
		player:AddBlueFlies(utils.random(1, 4),
			player.Position,
			nil)
	end

	local blue_spider_chance = utils.random(1, 4)
	if blue_spider_chance == 1 then
		for i = 1, utils.random(1, 4) do
			player:AddBlueSpider(player.Position)
		end
	end

	local pickup_chance = utils.random(1, (100 - (player.Luck * 2)))
	if pickup_chance <= 50 then
		local pickup_type = utils.random(1, 7)
		local subtype_to_spawn = 0 -- seems to be random for most pickups
		local pickup_to_spawn = nil
		if pickup_type == 1 then
			pickup_to_spawn = PickupVariant.PICKUP_HEART
		elseif pickup_type == 2 then
			pickup_to_spawn = PickupVariant.PICKUP_COIN
		elseif pickup_type == 3 then
			pickup_to_spawn = PickupVariant.PICKUP_KEY
		elseif pickup_type == 4 then
			pickup_to_spawn = PickupVariant.PICKUP_GRAB_BAG
		elseif pickup_type == 5 then
			pickup_to_spawn = PickupVariant.PICKUP_PILL
		elseif pickup_type == 6 then
			pickup_to_spawn = PickupVariant.PICKUP_LIL_BATTERY
		elseif pickup_type == 7 then
			pickup_to_spawn = PickupVariant.PICKUP_TAROTCARD
		end

		local spawn_position = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
		Isaac.Spawn(EntityType.ENTITY_PICKUP,
			pickup_to_spawn,
			subtype_to_spawn,
			spawn_position,
			utils.VECTOR_ZERO,
			player)
	end

	local trinket_chance = utils.random(1, 33)
	if trinket_chance == 1 then
		local spawn_position = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
		Isaac.Spawn(EntityType.ENTITY_PICKUP,
			PickupVariant.PICKUP_TRINKET,
			0,
			spawn_position,
			utils.VECTOR_ZERO,
			player)
	end

	local item_chance = utils.random(1, 500)
	if item_chance == 1 then
		local spawn_position = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
		Isaac.Spawn(EntityType.ENTITY_PICKUP,
			PickupVariant.PICKUP_COLLECTIBLE,
			0,
			spawn_position,
			utils.VECTOR_ZERO,
			player)
	end
end)

return trash_bag