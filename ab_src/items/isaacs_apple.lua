----------------------------------------------------------------------------
-- Item: Isaac's Apple
-- Originally from Pack 1
-- Stops all tears in their tracks
----------------------------------------------------------------------------

local Item = include("ab_src.api.item")
local isaacs_apple = Item("Isaac's Apple")

isaacs_apple:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	for _, entity in ipairs(Isaac:GetRoomEntities()) do
		if entity.Type == EntityType.ENTITY_TEAR or entity.Type == EntityType.ENTITY_PROJECTILE then
			entity.Velocity = Vector.Zero
		end
	end
end)

return isaacs_apple