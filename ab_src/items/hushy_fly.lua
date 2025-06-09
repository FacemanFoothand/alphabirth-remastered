----------------------------------------------------------------------------
-- Item: Hushy FLy
-- Originally from Pack 3
--
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local EntityConfig = require("ab_src.api.entity")

local hushy_fly = Item("Hushy Fly") ---@type Item
hushy_fly.Familiar = EntityConfig("Hushy Fly") ---@type EntityConfig

---@param familiar EntityFamiliar
hushy_fly.Familiar:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(familiar)
    familiar:AddToOrbit(51)
    familiar:RecalculateOrbitOffset(familiar.OrbitLayer, true)
end)

---@param fly EntityFamiliar
hushy_fly.Familiar:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(fly)
    local player = fly.Player
    fly.OrbitDistance = Vector(50, 50)
    fly.Velocity = (fly:GetOrbitPosition(player.Position) - fly.Position)
    if player:GetLastActionTriggers() & ActionTriggers.ACTIONTRIGGER_SHOOTING == 0 then
        fly.OrbitAngleOffset = fly.OrbitAngleOffset + 0.1
    end
end)

hushy_fly:AddSimpleFamiliar(hushy_fly.Familiar.Variant, hushy_fly.Familiar.SubType, nil, false)

return hushy_fly
