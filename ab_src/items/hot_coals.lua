----------------------------------------------------------------------------
-- Item: Hot Coals
-- Originally from Pack 2
-- +1.4 damage while moving -0.7 damage while standing still, starts fires when moving
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local g = require("ab_src.modules.globals")
local utils = require("ab_src.modules.utils")

local hot_coals = Item("Hot Coals") ---@type Item

utils.mixTables(g.defaultPlayerSaveData, {
    ["hot_coals"] = {
        dmg_modifier = 1,
        frame_count = 0,
    },
})

hot_coals:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    if flag == CacheFlag.CACHE_DAMAGE then
        local save = g.getPlayerSave(player)
        player.Damage = player.Damage + save.hot_coals.dmg_modifier
    end
end)

hot_coals:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player)
    local save = g.getPlayerSave(player).hot_coals
    local direction = player:GetMovementVector()
    local reval = false
    if direction:Length() == 0.0 then
        if save.dmg_modifier ~= 0.7 then
            reval = true
        end
        save.dmg_modifier = -0.7
        save.frame_count = 0
    else
        if save.dmg_modifier ~= 1.4 then
            reval = true
        end
        save.dmg_modifier = 1.4
        local trail = Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.PLAYER_CREEP_BLACKPOWDER,
            1,
            player.Position,
            Vector(0, 0),
            player
        ):ToEffect() or {}

        trail:SetTimeout(15)
        --trail:SetColor(Color(0.5, 0, 0, 0.5, 100, 100, 100), 0, 0, false, false)

        save.frame_count = save.frame_count + 1
        if save.frame_count == 100 then
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, player.Position, Vector(0, 0), player)
            local flame = Isaac.Spawn(
                EntityType.ENTITY_EFFECT,
                EffectVariant.RED_CANDLE_FLAME,
                0,
                player.Position,
                Vector(0, 0),
                player
            ):ToEffect()
            flame.CollisionDamage = player.Damage * 4
            save.frame_count = 0
        end
    end
    if reval then
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:EvaluateItems()
    end
end)

return hot_coals
