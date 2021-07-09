----------------------------------------------------------------------------
-- Item: Tearleporter
-- Originally from Pack 1
-- Teleport you to the farthest tear away from you
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local tearleporter = Item("Tearleporter")

tearleporter:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	local furthest_tear
	for _, entity in ipairs(Isaac:GetRoomEntities()) do
		if entity.Type == EntityType.ENTITY_TEAR then
			furthest_tear = furthest_tear or entity
			local distance_to_this_tear = player.Position:Distance(entity.Position)
			local distance_to_furthest_tear = player.Position:Distance(furthest_tear.Position)
			if distance_to_furthest_tear < distance_to_this_tear then
				furthest_tear = entity
			end
		end
	end

	if furthest_tear then
		player.Position = furthest_tear.Position
		player:AnimateTeleport(false)
	end
end)

return tearleporter
