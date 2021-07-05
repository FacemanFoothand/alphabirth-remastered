----------------------------------------------------------------------------
-- Item: Chastity
-- Originally from Pack 1
-- Stats up if you haven't gone to the DEVIL room this run
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local chastity = {
	ENABLED = true,
	NAME = "Chastity",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_chastity.anm2",
	AB_REF = nil,
	ITEM_REF = nil
}

function chastity.setup(Alphabirth)
	chastity.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.CHASTITY = Alphabirth.API_MOD:registerItem(chastity.NAME, chastity.COSTUME, {CacheFlag.CACHE_DAMAGE, CacheFlag.CACHE_RANGE, CacheFlag.CACHE_SHOTSPEED, CacheFlag.CACHE_SPEED})
	chastity.ITEM_REF = Alphabirth.ITEMS.PASSIVE.CHASTITY
	chastity.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.evaluate)
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, chastity.postNewRoom)
end

function chastity.postNewRoom()
	local room = AlphaAPI.GAME_STATE.ROOM
	local runData = temperance.AB_REF.data.run

	if room:GetType() == RoomType.ROOM_DEVIL then
		runData.seenDevil = true
		local plist = utils.hasCollectible(chastity.ITEM_REF.id)
		if plist then
			for _, player in ipairs(plist) do
				player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
				player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
				player:AddCacheFlags(CacheFlag.CACHE_RANGE)
				player:AddCacheFlags(CacheFlag.CACHE_SPEED)
				player:EvaluateItems()
			end
		end
	end
end

function chastity.evaluate(player, cache_flag)
	local runData = chastity.AB_REF.data.run

	if not runData.seenDevil then
		if(cache_flag == CacheFlag.CACHE_DAMAGE) then
			player.Damage = (player.Damage + 1.5) * 1.5
		elseif(cache_flag == CacheFlag.CACHE_SHOTSPEED) then
			player.ShotSpeed = player.ShotSpeed + 0.4
		elseif(cache_flag == CacheFlag.CACHE_RANGE) then
			player.TearHeight = player.TearHeight - 5
		elseif (cache_flag == CacheFlag.CACHE_SPEED)then
			player.MoveSpeed = player.MoveSpeed + 0.2
		end
	end
end

return chastity