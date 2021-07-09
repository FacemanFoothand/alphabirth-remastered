----------------------------------------------------------------------------
-- Item: Cologne
-- Originally from Pack 1
-- Chance to charm nearby enemies
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")
local random = utils.random

local cologne = Item("Cologne")
cologne.charm_duration = 100
cologne.charm_chance = 100

cologne:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	if cache_flag == CacheFlag.CACHE_TEARCOLOR then
		player.TearColor = Color(
								0.867, 0.627, 0.867,    -- RGB
								1,                      -- Alpha
								0, 0, 0                 -- RGB Offset
							)
	end
end)

cologne:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
	local max_charm_distance = 120 * math.max( player.SpriteScale.X, player.SpriteScale.Y )
	for _, entity in ipairs(AlphaAPI.entities.all) do
		if player.Position:Distance(entity.Position) < max_charm_distance
		and entity:IsVulnerableEnemy() then
			local charm_roll = random(1, cologne.charm_chance)
			if charm_roll == 1 then
				entity:AddCharmed(EntityRef(player), cologne.charm_duration)
			end
		end
	end
end)

return cologne