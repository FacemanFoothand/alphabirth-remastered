----------------------------------------------------------------------------
-- Item: Temperance
-- Originally from Pack 1
-- Stats up if you haven't gone to the treasure room on the floor
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local temperance = {
	ENABLED = true,
	NAME = "Temperance",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_temperance.anm2",
	AB_REF = nil,
	ITEM_REF = nil
}

function temperance.setup(Alphabirth)
	temperance.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.TEMPERANCE = Alphabirth.API_MOD:registerItem(temperance.NAME, temperance.COSTUME)
	temperance.ITEM_REF = Alphabirth.ITEMS.PASSIVE.TEMPERANCE
	temperance.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, temperance.evaluate)
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, temperance.postNewRoom)
end

function temperance.postNewRoom()
	local room = AlphaAPI.GAME_STATE.ROOM
	local runData = temperance.AB_REF.data.run

	if runData.seenTreasure == false and room:GetType() == RoomType.ROOM_TREASURE then
		runData.seenTreasure = true
		for _, player in ipairs(utils.hasCollectible(temperance.ITEM_REF.id)) do
			player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			player:AddCacheFlags(CacheFlag.CACHE_SPEED)
			player:AddCacheFlags(CacheFlag.CACHE_RANGE)
			player:EvaluateItems()
		end
	end
end

function temperance.evaluate(player, cache_flag)
	local runData = temperance.AB_REF.data.run

	if not runData.seenTreasure then
		if(cache_flag == CacheFlag.CACHE_DAMAGE) then
			player.Damage = player.Damage + 2
		elseif(cache_flag == CacheFlag.CACHE_SPEED) then
			player.MoveSpeed = player.MoveSpeed + 0.15
		elseif(cache_flag == CacheFlag.CACHE_RANGE) then
			player.TearHeight = player.TearHeight - 8.5
		end
	end
end

return temperance