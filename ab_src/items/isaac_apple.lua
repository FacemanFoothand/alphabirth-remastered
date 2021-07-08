----------------------------------------------------------------------------
-- Item: Isaac's Apple
-- Originally from Pack 1
-- Stops all tears in their tracks
----------------------------------------------------------------------------

local utils = include("code/utils")

local isaac_apple = {
	ENABLED = true,
	NAME = "Isaac's Apple",
	TYPE = "Active",
	AB_REF = nil,
	ITEM_REF = nil
}

function isaac_apple.setup(Alphabirth)
	isaac_apple.AB_REF = Alphabirth
	Alphabirth.ITEMS.ACTIVE.ISAAC_APPLE = Alphabirth.API_MOD:registerItem(isaac_apple.NAME)
	isaac_apple.ITEM_REF = Alphabirth.ITEMS.ACTIVE.ISAAC_APPLE
	isaac_apple.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, isaac_apple.trigger)
end

function isaac_apple.trigger()
	for _, entity in ipairs(AlphaAPI.entities.all) do
		if entity.Type == EntityType.ENTITY_TEAR or entity.Type == EntityType.ENTITY_PROJECTILE then
			entity.Velocity = utils.VECTOR_ZERO
		end
	end
end

return isaac_apple