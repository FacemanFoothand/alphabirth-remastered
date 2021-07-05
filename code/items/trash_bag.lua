----------------------------------------------------------------------------
-- Item: Trash Bag
-- Originally from Pack 1
-- 28% chance for 3 blue flies, 28% chance for 3 blue spiders,
-- 41% chance for a random pickup, 3% chance for a trinket
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local TRASH_BAG = {
	ENABLED = true,
	NAME = "Trash Bag",
	TYPE = "Active",
	AB_REF = nil,
	ITEM_REF = nil
}

function TRASH_BAG.setup(Alphabirth)
	TRASH_BAG.AB_REF = Alphabirth
	Alphabirth.ITEMS.ACTIVE.TRASH_BAG = Alphabirth.API_MOD:registerItem(TRASH_BAG.NAME)
	TRASH_BAG.ITEM_REF = Alphabirth.ITEMS.ACTIVE.TRASH_BAG
	TRASH_BAG.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, TRASH_BAG.trigger)
end

function TRASH_BAG.trigger()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	-- Always spawns either spiders or flies
	-- 25% chance to spawn extra spiders, 25% for extra flies,
	-- 50% to spawn a pickup, 3% to spawn a pickup, 0.2% to spawn an item
	local spider_fly_chance = random(1, 2)
	if spider_fly_chance == 1 then
		for i = 1, random(1, 4) do
			player:AddBlueSpider(player.Position)
		end
	else
		player:AddBlueFlies(random(1, 4),
			player.Position,
			nil)
	end

	local blue_fly_chance = random(1, 4)
	if blue_fly_chance == 1 then
		player:AddBlueFlies(random(1, 4),
			player.Position,
			nil)
	end

	local blue_spider_chance = random(1, 4)
	if blue_spider_chance == 1 then
		for i = 1, random(1, 4) do
			player:AddBlueSpider(player.Position)
		end
	end

	local pickup_chance = random(1, (100 - (player.Luck * 2)))
	if pickup_chance <= 50 then
		local pickup_type = random(1, 7)
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

	local trinket_chance = random(1, 33)
	if trinket_chance == 1 then
		local spawn_position = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
		Isaac.Spawn(EntityType.ENTITY_PICKUP,
			PickupVariant.PICKUP_TRINKET,
			0,
			spawn_position,
			utils.VECTOR_ZERO,
			player)
	end

	local item_chance = random(1, 500)
	if item_chance == 1 then
		local spawn_position = AlphaAPI.GAME_STATE.ROOM:FindFreePickupSpawnPosition(player.Position, 1, true)
		Isaac.Spawn(EntityType.ENTITY_PICKUP,
			PickupVariant.PICKUP_COLLECTIBLE,
			0,
			spawn_position,
			utils.VECTOR_ZERO,
			player)
	end
end

return TRASH_BAG