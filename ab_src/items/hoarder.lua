----------------------------------------------------------------------------
-- Item: Hoarder
-- Originally from Pack 2
-- Consumables = Damage
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")

local hoarder = Item("Hoarder") ---@type Item
hoarder.ratio = 1 / 25 -- 1 Damage for 25 consumables

---@param player EntityPlayer
---@param flag CacheFlag
hoarder:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    local data = player:GetData()
    if flag == CacheFlag.CACHE_DAMAGE and data.hoarder_damage then
        player.Damage = player.Damage + data.hoarder_damage
    end
end)

---@param player EntityPlayer
hoarder:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player)
    local consumables = player:GetNumCoins() + player:GetNumBombs() + player:GetNumKeys()
    local data = player:GetData()
    if not data.hoarder_damage then
        data.hoarder_damage = 0
    end
    if consumables * hoarder.ratio  ~= data.hoarder_damage then
        data.hoarder_damage = consumables * hoarder.ratio
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:EvaluateItems()
    end
end)

return hoarder
