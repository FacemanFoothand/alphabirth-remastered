----------------------------------------------------------------------------
-- Item: Entropy
-- Originally from Pack 3
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Entropy", "{{ArrowUp}} 1.5x Tears multiplier#Chance to fire an extra tear with a slightly off trajectory#{{LuckSmall}} 100% Chance at 7 Luck"},
    ["pt_br"] = {"Entropia", "{{ArrowUp}} 1.5x Multiplicador de Lágrimas#Chance de atirar uma lágrima extra com trajetória diferente%{{LuckSmall}} 100% de chance com 7 Sorte"},
}

local entropy = Item("Entropy", desc)

local entropy_flag = false

entropy:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, function(entity)
    local data = entity:GetData()
    local player = entity:GetLastParent():ToPlayer()
    if not entropy_flag and utils.getLuckRNG(player, 66, 5) then
        local angle = player:GetAimDirection():GetAngleDegrees()
        local avoid_center = 6
        local variance = 15
        local deviation
        if utils.random(0, 1) == 0 then
            deviation = utils.random(-variance, -avoid_center)
        else
            deviation = utils.random(avoid_center, variance)
        end
        local length = player.ShotSpeed * 10.0 + entity.Velocity:Length()

        entropy_flag = true
        player:FireTear(
            player.Position,
            Vector.FromAngle(angle + deviation):Resized(length),
            true, false, false
        )
    end
    entropy_flag = false
end)

entropy:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    if flag == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = player.MaxFireDelay - 3
    end
end)
