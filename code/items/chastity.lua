----------------------------------------------------------------------------
-- Item: Chastity
-- Originally from Pack 1
-- Stats up if you haven't gone to the DEVIL room this run
----------------------------------------------------------------------------

local g = require("code.globals")
local Item = include("code.item")
local utils = include("code.utils")

local chastity = Item("Chastity")

g.mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(player)
	local room = g.room

	if room:GetType() == RoomType.ROOM_DEVIL then
		g.saveData.run.seenDevil = true

		for _, player in ipairs(g.players) do
			if chastity:PlayerHas(player) then
				player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
				player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
				player:AddCacheFlags(CacheFlag.CACHE_RANGE)
				player:AddCacheFlags(CacheFlag.CACHE_SPEED)
				player:EvaluateItems()
			end
		end
	end
end)

chastity:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	if not g.saveData.run.seenDevil then
		if cache_flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = (player.Damage + 1.5) * 1.5
		elseif cache_flag == CacheFlag.CACHE_SHOTSPEED then
			player.ShotSpeed = player.ShotSpeed + 0.4
		elseif cache_flag == CacheFlag.CACHE_RANGE then
			player.TearHeight = player.TearHeight - 5
		elseif cache_flag == CacheFlag.CACHE_SPEED then
			player.MoveSpeed = player.MoveSpeed + 0.2
		end
	end
end)

return chastity
