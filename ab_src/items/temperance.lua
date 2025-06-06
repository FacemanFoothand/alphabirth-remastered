----------------------------------------------------------------------------
-- Item: Temperance
-- Originally from Pack 1
-- Stats up if you haven't gone to the treasure room on the floor
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local temperance = Item("Temperance") ---@type Item
temperance.desc = include("ab_src.integrations.eid").temperance

utils.mixTables(g.defaultPlayerSaveData, {
	run = {
		floor = {
			seen_treasure = false
		}
	}
})

---@param player EntityPlayer
---@param cache_flag CacheFlag
temperance:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	local save = g.getPlayerSave(player)

	if not save.run.floor.seen_treasure then
		if(cache_flag == CacheFlag.CACHE_DAMAGE) then
			player.Damage = player.Damage + 2
		elseif(cache_flag == CacheFlag.CACHE_SPEED) then
			player.MoveSpeed = player.MoveSpeed + 0.15
		elseif(cache_flag == CacheFlag.CACHE_RANGE) then
			player.TearHeight = player.TearHeight - 8.5
		end
	end
end)

---@param player EntityPlayer
temperance:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(player)
	local room = g.room
	local save = g.getPlayerSave(player)

	if save.run.floor.seen_treasure == false and room:GetType() == RoomType.ROOM_TREASURE then
		save.run.floor.seen_treasure = true
		player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
		player:AddCacheFlags(CacheFlag.CACHE_SPEED)
		player:AddCacheFlags(CacheFlag.CACHE_RANGE)
		player:EvaluateItems()
	end
end)

return temperance
