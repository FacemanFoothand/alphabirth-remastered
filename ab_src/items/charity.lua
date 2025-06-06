----------------------------------------------------------------------------
-- Item: Charity
-- Originally from Pack 1
-- Spawns a bum in every treasure room and stats up for less consumables
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local charity = Item("Charity") ---@type Item
charity.desc = include("ab_src.integrations.eid").charity
charity.max_damage = 2.0
charity.max_speed = 0.2
charity.max_luck = 3
charity.min_damage = -1
charity.min_speed = -0.1
charity.min_luck = -1.5

charity.beggar_variants = {
    4,  -- Beggar
    7,  -- Key Master
    8,  -- Donation Machine
    9,  -- Bomb Bum
    13, -- Battery Bum
    18, -- Rotten Beggar
}

utils.mixTables(g.defaultPlayerSaveData, {
    damage_modifier = 0,
    speed_modifier = 0,
    luck_modifier = 0,
    previous_total = nil
})

---@param player EntityPlayer
---@param cache_flag CacheFlag
charity:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
    local save = g.getPlayerSave(player)
    if cache_flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage + save.damage_modifier
    elseif cache_flag == CacheFlag.CACHE_SPEED then
        player.MoveSpeed = player.MoveSpeed + save.speed_modifier
    elseif cache_flag == CacheFlag.CACHE_LUCK then
        player.Luck = player.Luck + save.luck_modifier
    end
end)

---@param player EntityPlayer
charity:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player)
    local keys = player:GetNumKeys()
    local bombs = player:GetNumBombs()
    local coins = player:GetNumCoins()
    local hasDeepPockets = player:HasCollectible(CollectibleType.COLLECTIBLE_DEEP_POCKETS)

    local coin_cap = hasDeepPockets and 999 or 99
    local max_capacity = coin_cap + 99 + 99 -- coins + bombs + keys
    local total = keys + coins + bombs

    local save = g.getPlayerSave(player)

    if total ~= save.previous_total then
        save.previous_total = total

        local over_capacity = total > (max_capacity * 0.7)
        local fraction = total / max_capacity

        local function scaleStat(base, min)
            local value = base * (1 - fraction)
            if over_capacity then
                return math.max(value, min)
            else
                return math.max(value, 0)
            end
        end

        save.damage_modifier = scaleStat(charity.max_damage, charity.min_damage)
        save.speed_modifier = scaleStat(charity.max_speed, charity.min_speed)
        save.luck_modifier = scaleStat(charity.max_luck, charity.min_luck)

        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:AddCacheFlags(CacheFlag.CACHE_SPEED)
        player:AddCacheFlags(CacheFlag.CACHE_LUCK)
        player:EvaluateItems()
    end
end)

charity:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    local room = Game():GetRoom()
    if room:GetType() == RoomType.ROOM_TREASURE and room:IsFirstVisit() then
        local center_position = room:GetCenterPos()
        local position = Isaac.GetFreeNearPosition(center_position, 0)
        local beggar_type = charity.beggar_variants[utils.random(1, #charity.beggar_variants)]
        Isaac.Spawn(
            EntityType.ENTITY_SLOT,
            beggar_type,
            0,
            position,
            Vector.Zero,
            nil
        )
    end
end)

return charity
