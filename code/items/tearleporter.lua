----------------------------------------------------------------------------
-- Item: Tearleporter
-- Originally from Pack 1
-- Teleport you to the farthest tear away from you
----------------------------------------------------------------------------

local utils = include("code/utils")

local TEARLEPORTER = {
	ENABLED = true,
	NAME = "Tearleporter",
	TYPE = "Active",
	AB_REF = nil,
	ITEM_REF = nil
}

function TEARLEPORTER.setup(Alphabirth)
	TEARLEPORTER.AB_REF = Alphabirth
	Alphabirth.ITEMS.ACTIVE.TEARLEPORTER = Alphabirth.API_MOD:registerItem(TEARLEPORTER.NAME)
	TEARLEPORTER.ITEM_REF = Alphabirth.ITEMS.ACTIVE.TEARLEPORTER
	TEARLEPORTER.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, TEARLEPORTER.trigger)
end

function TEARLEPORTER.trigger()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	local furthest_tear
	for _, entity in ipairs(AlphaAPI.entities.all) do
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
end

return TEARLEPORTER