----------------------------------------------------------------------------
-- Item: Faithful Ambivalence
-- Originally from Pack 3
-- A free item of opposing divine polarity spawns in Devil/Angel rooms
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local g = require("ab_src.modules.globals")

local faithful_ambivalence = Item("Faithful Ambivalence") ---@type Item

faithful_ambivalence:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    local type = g.room:GetType()
    local pool = g.game:GetItemPool()
    if g.room:IsFirstVisit() then
        if type == RoomType.ROOM_ANGEL or type == RoomType.ROOM_DEVIL then
            local item = nil
            if type == RoomType.ROOM_ANGEL then
                item = pool:GetCollectible(ItemPoolType.POOL_DEVIL, true, g.room:GetSpawnSeed())
            else
                item = pool:GetCollectible(ItemPoolType.POOL_ANGEL, true, g.room:GetSpawnSeed())
            end

            if item then
                local teleport_pos = g.room:FindFreePickupSpawnPosition(g.room:GetCenterPos())
                Isaac.Spawn(
                    EntityType.ENTITY_PICKUP,
                    PickupVariant.PICKUP_COLLECTIBLE,
                    item,
                    teleport_pos,
                    Vector.Zero,
                    nil
                )
            end
        end
    end
end)

return faithful_ambivalence
