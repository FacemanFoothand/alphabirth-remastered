----------------------------------------------------------------------------
-- Item: Tearleporter
-- Originally from Pack 1
-- Teleport you to the farthest tear away from you
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local g = require("ab_src.modules.globals")

local tearleporter = Item("Tearleporter")
tearleporter.desc = include("ab_src.integrations.eid").tearleporter

---@param player EntityPlayer
tearleporter:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, player)
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
        g.sfx:Play(SoundEffect.SOUND_HELL_PORTAL1, 1, 0, false, 1)
		player:AnimateTeleport(false)
        furthest_tear:Kill()
	end
end)

return tearleporter
