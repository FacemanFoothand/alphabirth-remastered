----------------------------------------------------------------------------
-- Item: Patience
-- Originally from Pack 1
-- Damage up the longer you're in a room
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local patience = Item("Patience")

utils.mixTables(g.defaultPlayerSaveData, {
	patience_damage_modifier = 0
})

patience:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
	local save = g.getPlayerSave(player)
	local second_has_passed = g.room:GetFrameCount() % 61 == 1
	local room_is_clear = g.room:IsClear()
	local last_patience_bonus = save.patience_damage_modifier

	if second_has_passed
		and not room_is_clear then
		save.patience_damage_modifier = math.min(save.patience_damage_modifier + 0.2, 5.0)
		if last_patience_bonus ~= save.patience_damage_modifier then
			player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
			player:EvaluateItems()
		end
	end

	if g.room:GetFrameCount() == 1 then
		save.patience_damage_modifier = 0
	end
end)

patience:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	local save = g.getPlayerSave(player)
	if cache_flag ==  CacheFlag.CACHE_DAMAGE and g.room:GetFrameCount() > 1 then
		player.Damage = player.Damage + save.patience_damage_modifier
	end
end)

return patience