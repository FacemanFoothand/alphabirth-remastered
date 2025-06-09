----------------------------------------------------------------------------
-- Item: Isaac's Skull
-- Originally from Pack 3
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")

local isaacs_skull = Item("Isaac's Skull") ---@type Item
isaacs_skull.desc = include("ab_src.integrations.eid").isaacs_skull

---@param rng RNG
---@param player EntityPlayer
isaacs_skull:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, rng, player)
    local effects = player:GetEffects()
    local has_duality = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_DUALITY) > 0

    if has_duality then
        effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_GODHEAD)
        effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BRIMSTONE)
    else
        if rng:RandomInt(2) == 1 then
            effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_BRIMSTONE)
        else
            effects:AddCollectibleEffect(CollectibleType.COLLECTIBLE_GODHEAD)
        end
    end

    return true
end)

return isaacs_skull
