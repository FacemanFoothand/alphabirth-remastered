----------------------------------------------------------------------------
-- Item: Beggar's Cup
-- Originally from Pack 1
-- Gives the player more luck the fewer consumables they have
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local beggars_cup = Item("Beggar's Cup") ---@type Item
beggars_cup.desc = include("ab_src.integrations.eid").beggars_cup

utils.mixTables(g.defaultPlayerSaveData, {
	luck_modifier = 0,
	previous_total = nil
})

---@param player EntityPlayer
beggars_cup:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player)
	local save = g.getPlayerSave(player)
	local coins = player:GetNumCoins()
	local total = coins / 10

	-- Only run if total has changed
	if total ~= save.previous_total then
		save.previous_total = total
		local luck_threshold = 5
		local luck_minimum = 0

		save.luck_modifier = luck_threshold - total

		if save.luck_modifier < luck_minimum then
			save.luck_modifier = luck_minimum
		end

		player:AddCacheFlags(CacheFlag.CACHE_LUCK)
		player:EvaluateItems()
	end
end)

---@param player EntityPlayer
---@param cache_flag CacheFlag
beggars_cup:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	local save = g.getPlayerSave(player)
	if cache_flag == CacheFlag.CACHE_LUCK then
		player.Luck = player.Luck + save.luck_modifier
	end
end)

return beggars_cup
