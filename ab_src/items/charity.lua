----------------------------------------------------------------------------
-- Item: Charity
-- Originally from Pack 1
-- Spawns a bum in every treasure room and stats up for less consumables
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local charity = {
	ENABLED = true,
	NAME = "Charity",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_charity.anm2",
	DAMAGE_MODIFIER = 0,
	SPEED_MODIFIER = 0,
	TEAR_HEIGHT_MODIFIER = 0,
	PREVIOUS_TOTAL = 0,
	AB_REF = nil,
	ITEM_REF = nil
}

function charity.setup(Alphabirth)
	charity.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.CHARITY = Alphabirth.API_MOD:registerItem(charity.NAME, charity.COSTUME)
	charity.ITEM_REF = Alphabirth.ITEMS.PASSIVE.CHARITY
	charity.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, charity.handle)
	charity.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, charity.evaluate)
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, charity.postNewRoom)
end

function charity.postNewRoom()
	local room = AlphaAPI.GAME_STATE.ROOM

	if utils.hasCollectible(charity.ITEM_REF.id) then
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
end

function charity.handle(player)
	local keys = player:GetNumKeys()
	local coins = player:GetNumCoins()
	local bombs = player:GetNumBombs()
	local total = (keys + coins + bombs) / 2

	-- Only run if total has changed
	if total ~= charity.PREVIOUS_TOTAL then

		charity.PREVIOUS_TOTAL = total

		-- Values are made to be a little higher than magic mushroom.
		local damage_threshhold = 1.5
		local speed_threshhold = 0.1
		local tear_height_threshhold = 7.5

		local damage_minimum = -1.5
		local speed_minimum = -0.1
		local tear_height_minimum = -7.5

		-- Values are made so that at 20 of each consumable you hit 0 stat boosts.
		charity.DAMAGE_MODIFIER = damage_threshhold - total * 0.15
		charity.SPEED_MODIFIER = speed_threshhold - total * 0.05
		charity.TEAR_HEIGHT_MODIFIER = tear_height_threshhold - total * 0.75

		if charity.DAMAGE_MODIFIER < damage_minimum then
			charity.DAMAGE_MODIFIER = damage_minimum
		end

		if charity.SPEED_MODIFIER < speed_minimum then
			charity.SPEED_MODIFIER = speed_minimum
		end

		if charity.TEAR_HEIGHT_MODIFIER < tear_height_minimum then
			charity.TEAR_HEIGHT_MODIFIER = tear_height_minimum
		end

		player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
		player:AddCacheFlags(CacheFlag.CACHE_SPEED)
		player:AddCacheFlags(CacheFlag.CACHE_RANGE)
		player:EvaluateItems()
	end
end

function charity.evaluate(player, cache_flag)
	if(cache_flag == CacheFlag.CACHE_DAMAGE) then
		player.Damage = player.Damage + charity.DAMAGE_MODIFIER
	elseif(cache_flag == CacheFlag.CACHE_SPEED) then
		player.MoveSpeed = player.MoveSpeed + charity.SPEED_MODIFIER
	elseif(cache_flag == CacheFlag.CACHE_RANGE) then
		player.TearHeight = player.TearHeight - charity.TEAR_HEIGHT_MODIFIER
	end
end

return charity