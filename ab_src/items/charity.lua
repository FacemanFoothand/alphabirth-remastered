----------------------------------------------------------------------------
-- Item: Charity
-- Originally from Pack 1
-- Spawns a bum in every treasure room and stats up for less consumables
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")
local random = utils.random

local desc = {
    ["en_us"] = {"Charity", "{{ArrowUp}} +0.2 Speed#{{ArrowUp}} +3 Luck#{{ArrowUp}} +2 Damage#{{ArrowDown}} For every pickup Isaac has the bonus is reduced, eventually going negative if he carries over 70% of max#Spawns a beggar in every item room"},
    ["pt_br"] = {"Caridade", "{{ArrowUp}} +0.2 Velocidade#{{ArrowUp}} +3 Sorte#{{ArrowUp}} +2 Dano#{{ArrowDown}} Para cada pickup que Isaac tem o bonus é reduzido, eventualmente tornando negativo se estiver carregando mais de 70% da capacidade máxima#Spawna um pedinte em cada quarto de item."},
}

local charity = Item("Charity", desc)

utils.mixTables(g.defaultPlayerSaveData, {
    damage_modifier = 0,
    speed_modifier = 0,
    luck_modifier = 0,
    previous_total = nil
})

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

charity:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
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

        -- Stat maxes
        local base_damage = 2
        local base_speed = 0.2
        local base_luck = 3

        -- Stat minimums (half of max, negative)
        local damage_min = -1
        local speed_min = -0.1
        local luck_min = -1.5

        local function scaleStat(base, min)
            local value = base * (1 - fraction)
            if over_capacity then
                return math.max(value, min)
            else
                return math.max(value, 0)
            end
        end

        save.damage_modifier = scaleStat(base_damage, damage_min)
        save.speed_modifier = scaleStat(base_speed, speed_min)
        save.luck_modifier = scaleStat(base_luck, luck_min)

        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:AddCacheFlags(CacheFlag.CACHE_SPEED)
        player:AddCacheFlags(CacheFlag.CACHE_LUCK)
        player:EvaluateItems()
    end
end)

charity:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(player)
    local room = Game():GetRoom()

    if utils.hasCollectible(charity.ID) then
        if room:GetType() == RoomType.ROOM_TREASURE and room:IsFirstVisit() then
            local center_position = room:GetCenterPos()
            local position = Isaac.GetFreeNearPosition(center_position, 0)
            local beggartype = random(4, 7)
            Isaac.Spawn(
                EntityType.ENTITY_SLOT,
                beggartype,
                0,
                position,
                utils.VECTOR_ZERO,
                nil
            )
        end
    end
end)

return charity
