----------------------------------------------------------------------------
-- Item: Brunch
-- Originally from Pack 2
-- +1 Health, +0.6 Tears, Turns Isaac Green
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")

local brunch = Item("Brunch") ---@type Item
brunch.desc = include("ab_src.integrations.eid").brunch

---@param player EntityPlayer
---@param cache_flag CacheFlag
brunch:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
    if cache_flag == CacheFlag.CACHE_FIREDELAY then
        if player.MaxFireDelay < 4 then
            return
        end
        if player.MaxFireDelay < 6 then
            player.MaxFireDelay = 4
        else
            player.MaxFireDelay = player.MaxFireDelay - 2
        end
    end
end)

---@param player EntityPlayer
brunch:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player)
    player.Color = Color(0, 1, 0, 1, 0, 0, 0)
end)

return brunch
