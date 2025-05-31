----------------------------------------------------------------------------
-- Item: Beggar's Cup
-- Originally from Pack 1
-- Gives the player more luck the fewer consumables they have
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Beggar's Cup", "#{{ArrowUp}} +5 Luck#{{ArrowDown}} For every coin Isaac has he loses {{ColorRed}}0.1{{CR}} of the Luck bonus."},
    ["pt_br"] = {"Caneca de Pedinte", "#{{ArrowUp}} +5 Sorte#{{ArrowDown}} Para cada moeda que Isaac tem é subtraido {{ColorRed}}0.1{{CR}} Sorte do bonus."},
}

local beggars_cup = Item("Beggar's Cup", desc)

utils.mixTables(g.defaultPlayerSaveData, {
	luck_modifier = 0,
	previous_total = nil
})

beggars_cup:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
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

beggars_cup:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	local save = g.getPlayerSave(player)
	if cache_flag == CacheFlag.CACHE_LUCK then
		player.Luck = player.Luck + save.luck_modifier
	end
end)

return beggars_cup
