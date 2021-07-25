----------------------------------------------------------------------------
-- Item: The Cosmos
-- Originally from Pack 3
----------------------------------------------------------------------------
include("alpha_api.lua")
local EntityConfig = include("ab_src.api.entity")
local g = require("ab_src.modules.globals")
local utils = require("ab_src.modules.utils")
local Item = include("ab_src.api.item")

local cosmos = Item("The Cosmos")
cosmos.Mercury = EntityConfig("Cosmos Mercury")
cosmos.Venus = EntityConfig("Cosmos Venus")
cosmos.Pluto = EntityConfig("Cosmos Pluto")

local mercury_burn_chance = 0.05
local mercury_burn_duration = 60
cosmos.Mercury:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (familiar)
    familiar:AddToOrbit(30)
    familiar:GetData().orbit_distance = Vector(40, 40)
end)

cosmos.Mercury:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (familiar)
    local player = familiar:ToFamiliar().Player
	familiar.OrbitDistance = familiar:GetData().orbit_distance
    familiar.OrbitAngleOffset = familiar.OrbitAngleOffset + 0.05
    familiar.Velocity = (familiar:GetOrbitPosition(player.Position) - familiar.Position)
end)

local venus_charm_chance = 0.05
local venus_charm_duration = 120
cosmos.Venus:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (familiar)
    familiar:AddToOrbit(31)
    familiar:GetData().orbit_distance = Vector(60, 60)
end)

cosmos.Venus:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (familiar)
    local player = familiar:ToFamiliar().Player
	familiar.OrbitDistance = familiar:GetData().orbit_distance
    familiar.OrbitAngleOffset = familiar.OrbitAngleOffset + 0.035
    familiar.Velocity = (familiar:GetOrbitPosition(player.Position) - familiar.Position)
end)

local pluto_freeze_chance = 0.05
local pluto_freeze_duration = 90
cosmos.Pluto:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (familiar)
    familiar:AddToOrbit(50)
    familiar:GetData().orbit_distance = Vector(80, 80)
end)

cosmos.Pluto:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (familiar)
    local player = familiar:ToFamiliar().Player
	familiar.OrbitDistance = familiar:GetData().orbit_distance
    familiar.OrbitAngleOffset = familiar.OrbitAngleOffset + 0.02
    familiar.Velocity = (familiar:GetOrbitPosition(player.Position) - familiar.Position)
end)

cosmos:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(entity, damage_amount, damage_flag, damage_source, invincibility_frames)
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    if damage_source.Entity then
        local random = utils.random(0,1)
        if AlphaAPI.matchConfig(damage_source.Entity, cosmos.Mercury) then
            if random < mercury_burn_chance then
                entity:AddBurn(EntityRef(player), mercury_burn_duration, player.Damage)
            end
        elseif AlphaAPI.matchConfig(damage_source.Entity, cosmos.Venus) then
            if random < venus_charm_chance then
                entity:AddCharmed(venus_charm_duration)
            end
        elseif AlphaAPI.matchConfig(damage_source.Entity, cosmos.Pluto) then
            if random < pluto_freeze_chance then
                entity:AddFreeze(EntityRef(player), pluto_freeze_duration)
            end
        end
    end
end)

cosmos:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local amount_to_spawn = player:GetCollectibleNum(cosmos.ID) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(cosmos.Mercury.Variant, amount_to_spawn, player:GetCollectibleRNG(cosmos.ID))
        player:CheckFamiliar(cosmos.Venus.Variant, amount_to_spawn, player:GetCollectibleRNG(cosmos.ID))
        player:CheckFamiliar(cosmos.Pluto.Variant, amount_to_spawn, player:GetCollectibleRNG(cosmos.ID))
    end
end)
