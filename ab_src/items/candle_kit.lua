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

---@param familiar EntityFamiliar
candle_kit.Familiar:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(familiar)
    familiar.OrbitLayer = 4
    familiar:RecalculateOrbitOffset(familiar.OrbitLayer, true)
end)

---@param familiar EntityFamiliar
candle_kit.Familiar:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(familiar)
    local player = familiar.Player
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

candle_kit:AddSimpleFamiliar(candle_kit.Familiar.Variant, candle_kit.Familiar.SubType, nil, false, 2)

return candle_kit
