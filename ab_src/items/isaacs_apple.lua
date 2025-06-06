----------------------------------------------------------------------------
-- Item: Isaac's Apple
-- Originally from Pack 1
-- Stops all tears in their tracks
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")

local isaacs_apple = Item("Isaac's Apple") ---@type Item
isaacs_apple.desc = include("ab_src.integrations.eid").isaacs_apple

isaacs_apple:AddCallback(ModCallbacks.MC_USE_ITEM, function()
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
