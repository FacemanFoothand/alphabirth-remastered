----------------------------------------------------------------------------
-- Item: Isaac's Apple
-- Originally from Pack 1
-- Stops all tears in their tracks
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")

local desc = {
    ["en_us"] = {"Isaac's Apple", "Makes all of the tears in a room drop on the spot"},
    ["pt_br"] = {"Maçã do Isaac", "Faz todas as lágrimas em um quarto caírem no lugar"},
}

local isaacs_apple = Item("Isaac's Apple", desc)

isaacs_apple:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	for _, entity in ipairs(Isaac:GetRoomEntities()) do
		if entity.Type == EntityType.ENTITY_TEAR then
			entity.Velocity = Vector.Zero
		end
		if entity.Type == EntityType.ENTITY_PROJECTILE then
			entity.Velocity = Vector.Zero
            entity:ToProjectile():AddFallingAccel(6.0)
		end
	end
end)

return isaacs_apple
