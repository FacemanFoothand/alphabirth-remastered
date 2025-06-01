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

entropy:AddCallback(ModCallbacks.MC_POST_LASER_INIT, function(laser)
    local player = laser:GetLastParent():ToPlayer()
    if not player then return end

    if not entropy_flag and utils.getLuckRNG(player, 66, 5) then
        local angle = player:GetLastDirection():GetAngleDegrees()
        local avoid_center = 5
        local variance = 7
        local deviation

        if utils.random(0, 1) == 0 then
            deviation = utils.random(-variance, -avoid_center)
        else
            deviation = utils.random(avoid_center, variance)
        end

        local new_angle = angle + deviation
        local velocity_vector = Vector.FromAngle(new_angle)
        local length = player.ShotSpeed * 10.0 + player.Velocity:Length()
        local adjusted_velocity = velocity_vector:Resized(length)

        entropy_flag = true

        if player:HasWeaponType(WeaponType.WEAPON_BRIMSTONE) then
            player:FireBrimstone(velocity_vector, player, 1.0)
        elseif player:HasWeaponType(WeaponType.WEAPON_LASER) then
            player:FireTechLaser(player.Position, LaserOffset.LASER_TECH2_OFFSET, velocity_vector, false, false, player, 1.0)
        elseif player:HasWeaponType(WeaponType.WEAPON_TECH_X) then
            player:FireTechXLaser(player.Position, adjusted_velocity, 40.0, player, 1.0)
        end
    end

    entropy_flag = false
end)

entropy:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    if flag == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = player.MaxFireDelay - 3
    end
end)
