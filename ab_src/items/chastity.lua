----------------------------------------------------------------------------
-- Item: Chastity
-- Originally from Pack 1
-- Stats up if you haven't gone to the DEVIL room this run
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local chastity = Item("Chastity") ---@type Item
chastity.desc = include("ab_src.integrations.eid").chastity

utils.mixTables(g.defaultSaveData, {
	run = {
		seen_devil = false
	}
})

---@param player EntityPlayer
chastity:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(player)
	if g.room:GetType() == RoomType.ROOM_DEVIL then
		g.saveData.run.seen_devil = true
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
        player:AddCacheFlags(CacheFlag.CACHE_RANGE)
        player:AddCacheFlags(CacheFlag.CACHE_SPEED)
        player:EvaluateItems()
	end
end)

---@param player EntityPlayer
---@param cache_flag CacheFlag
chastity:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	if not g.saveData.run.seen_devil then
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
