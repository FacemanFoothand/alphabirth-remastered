----------------------------------------------------------------------------
-- Item: Charity
-- Originally from Pack 1
-- Spawns a bum in every treasure room and stats up for less consumables
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")
local random = utils.random

local charity = Item("Charity")

utils.mixTables(g.defaultPlayerSaveData, {
	damage_modifier = 0,
	speed_modifier = 0,
	tear_height_modifier = 0,
	previous_total = nil
})

charity:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	local save = g.getPlayerSave(player)
	if(cache_flag == CacheFlag.CACHE_DAMAGE) then
		player.Damage = player.Damage + save.damage_modifier
	elseif(cache_flag == CacheFlag.CACHE_SPEED) then
		player.MoveSpeed = player.MoveSpeed + save.speed_modifier
	elseif(cache_flag == CacheFlag.CACHE_RANGE) then
		player.TearHeight = player.TearHeight - save.tear_height_modifier
	end
end)

charity:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
	local keys = player:GetNumKeys()
	local coins = player:GetNumCoins()
	local bombs = player:GetNumBombs()
	local total = (keys + coins + bombs) / 2
	local save = g.getPlayerSave(player)

	-- Only run if total has changed
	if total ~= save.previous_total then

		save.previous_total = total

		-- Values are made to be a little higher than magic mushroom.
		local damage_threshhold = 1.5
		local speed_threshhold = 0.1
		local tear_height_threshhold = 7.5

		local damage_minimum = -1.5
		local speed_minimum = -0.1
		local tear_height_minimum = -7.5

		-- Values are made so that at 20 of each consumable you hit 0 stat boosts.
		save.damage_modifier = damage_threshhold - total * 0.15
		save.speed_modifier = speed_threshhold - total * 0.05
		save.tear_height_modifier = tear_height_threshhold - total * 0.75

		if save.damage_modifier < damage_minimum then
			save.damage_modifier = damage_minimum
		end

		if save.speed_modifier < speed_minimum then
			save.speed_modifier = speed_minimum
		end

		if save.tear_height_modifier < tear_height_minimum then
			save.tear_height_modifier = tear_height_minimum
		end

		player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
		player:AddCacheFlags(CacheFlag.CACHE_SPEED)
		player:AddCacheFlags(CacheFlag.CACHE_RANGE)
		player:EvaluateItems()
	end
end)

charity:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(player)
	local room = Game():GetRoom()

	if utils.hasCollectible(charity.ID) then
		if room:GetType() == RoomType.ROOM_TREASURE
				and room:IsFirstVisit() then
			local center_position = room:GetCenterPos()
			local position = Isaac.GetFreeNearPosition(center_position, 0)
			local beggartype = random(4, 7)
			Isaac.Spawn(
				EntityType.ENTITY_SLOT,
				beggartype,
				0,
				position,
				utils.VECTOR_ZERO,
				nil
			)
		end
    end
end)


return charity
