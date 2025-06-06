----------------------------------------------------------------------------
-- Item: Candle Kit
-- Originally on Pack 1
-- Creates two candle orbitals around Isaac.
-- Each orbital does contact damage and ignites enemies.
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")
local utils = include("ab_src.modules.utils")

local candle_kit = Item("Candle Kit") ---@type Item
candle_kit.desc = include("ab_src.integrations.eid").candle_kit
candle_kit.Familiar = EntityConfig("Candle Kit") ---@type EntityConfig

---@param player EntityPlayer
---@param cache_flag CacheFlag
candle_kit:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
    if cache_flag == CacheFlag.CACHE_FAMILIARS then
        local amount_to_spawn = (player:GetCollectibleNum(candle_kit.ID) * 2)
            * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(candle_kit.Familiar.Variant, amount_to_spawn, utils.RNG)
    end
end)

---@param familiar EntityFamiliar
candle_kit.Familiar:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(familiar)
    familiar.OrbitLayer = 4
    familiar:RecalculateOrbitOffset(familiar.OrbitLayer, true)
end)

---@param familiar EntityFamiliar
candle_kit.Familiar:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(familiar)
    local player = familiar.Player
    if player:GetCollectibleNum(candle_kit.ID) < 1 then
        familiar:Remove()
    end
    familiar.OrbitDistance = EntityFamiliar.GetOrbitDistance(familiar.OrbitLayer)
    local target_position = familiar:GetOrbitPosition(player.Position)
    familiar.Velocity = target_position - familiar.Position
    familiar.CollisionDamage = player.Damage * 0.8
    for _, e in ipairs(Isaac.GetRoomEntities()) do
        if e:IsVulnerableEnemy() and e.Position:Distance(familiar.Position) < 55 and utils.random(60) == 1 then
            e:AddBurn(EntityRef(familiar), 120, 1.0)
        end
    end
end)

return candle_kit
