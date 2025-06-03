----------------------------------------------------------------------------
-- Item: Cologne
-- Originally from Pack 1
-- Chance to charm nearby enemies
----------------------------------------------------------------------------

local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = { "Cologne", "{{Charm}} Creates an aura around Isaac that has a chance to charm enemies who get too close" },
    ["pt_br"] = { "Colônia", "{{Charm}} Cria uma aura ao redor de Isaac que tem chance de encantar inimigos que chegarem muito perto" },
}

local cologne = Item("Cologne", desc)
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

cologne:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, _)
	local max_charm_distance = 120 * math.max( player.SpriteScale.X, player.SpriteScale.Y )
	for _, entity in ipairs(Isaac.GetRoomEntities()) do
		if player.Position:Distance(entity.Position) < max_charm_distance
		and entity:IsVulnerableEnemy() then
			local charm_roll = utils.random(1, cologne.charm_chance)
			if charm_roll == 1 then
				entity:AddCharmed(EntityRef(player), cologne.charm_duration)
			end
		end
	end
end)

return cologne
