----------------------------------------------------------------------------
-- Item: Judas' Fez
-- Originally from Pack 2
-- Cheanges all heart containers but one into black hearts, 1.35x Damage multiplier
-- Book of Belial effect in one of 3 rooms
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")
local g = require("ab_src.modules.globals")

local judas_fez = Item("Judas' Fez") ---@type Item

utils.mixTables(g.defaultPlayerSaveData, {
    fez_room_counter = 0,
})

---@param player EntityPlayer
---@param flag CacheFlag
judas_fez:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    if flag == CacheFlag.CACHE_DAMAGE then
        local count = player:GetCollectibleNum(judas_fez.ID)
        player.Damage = player.Damage * (1 + 0.35 * count)
    end
end)

---@param player EntityPlayer
judas_fez:AddCallback("ITEM_PICKUP", function(player)
    local hearts = player:GetMaxHearts() - 2
    player:AddMaxHearts(hearts * -1)
    player:AddBlackHearts(hearts)
end)

---@param player EntityPlayer
judas_fez:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(player)
    local room = g.room
    local save = g.getPlayerSave(player)
    if room:IsFirstVisit() and not room:IsClear() then
        save.fez_room_counter = save.fez_room_counter + 1
        if save.fez_room_counter >= 3 then
            player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL)
            save.fez_room_counter = 0
        end
    end
end)

return judas_fez
