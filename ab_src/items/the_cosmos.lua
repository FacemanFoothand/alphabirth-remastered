----------------------------------------------------------------------------
-- Item: The Cosmos
-- Originally from Pack 3
----------------------------------------------------------------------------

local EntityConfig = include("ab_src.api.entity")
local utils = require("ab_src.modules.utils")
local Item = include("ab_src.api.item")

local desc = {
    ["en_us"] = {"The Cosmos", "3 orbitals that deal damage and status effects on contact#{{Burning}} Mecury has an 8% chance to inflict {{Burning}} Burning, effect scales with Isaac's damage#{{Charm}} Venus has an 8% chance to inflict {{Charm}} Charm#{{Freezing}} Pluto has an 8% chance to inflict {{Freezing}} Freeze"},
    ["pt_br"] = {"O Cosmos", "3 orbitais que dão dano e aplicam efeitos em contato#{{Burning}} Mercúrio tem uma chance de 8% para aplicar {{Burning}} Burning, o efeito escala com o Dano de Isaac#{{Charm}} Venus tem uma chance de 8% para aplicar {{Charm}} Charm#{{Freezing}} Plutão tem uma chance de 8% para aplicar {{Freezing}} Freeze"},
}

local cosmos = Item("The Cosmos", desc)
cosmos.Mercury = EntityConfig("Cosmos Mercury")
cosmos.Venus = EntityConfig("Cosmos Venus")
cosmos.Pluto = EntityConfig("Cosmos Pluto")
cosmos.Mercury.burn_chance = 0.08
cosmos.Mercury.burn_duration = 60
cosmos.Venus.charm_chance = 0.08
cosmos.Venus.charm_duration = 120
cosmos.Pluto.freeze_chance = 0.08
cosmos.Pluto.freeze_duration = 90

cosmos:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    if flag == CacheFlag.CACHE_FAMILIARS then
        local amount_to_spawn = player:GetCollectibleNum(cosmos.ID) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
        player:CheckFamiliar(cosmos.Mercury.Variant, amount_to_spawn, player:GetCollectibleRNG(cosmos.ID))
        player:CheckFamiliar(cosmos.Venus.Variant, amount_to_spawn, player:GetCollectibleRNG(cosmos.ID))
        player:CheckFamiliar(cosmos.Pluto.Variant, amount_to_spawn, player:GetCollectibleRNG(cosmos.ID))
    end
end)

cosmos.Mercury:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (familiar)
    familiar:AddToOrbit(30)
    familiar:GetData().orbit_distance = Vector(40, 40)
end)

cosmos.Venus:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (familiar)
    familiar:AddToOrbit(31)
    familiar:GetData().orbit_distance = Vector(60, 60)
end)

cosmos.Pluto:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (familiar)
    familiar:AddToOrbit(50)
    familiar:GetData().orbit_distance = Vector(80, 80)
end)

cosmos.Mercury:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (familiar)
    local player = familiar:ToFamiliar().Player
	familiar.OrbitDistance = familiar:GetData().orbit_distance
    familiar.OrbitAngleOffset = familiar.OrbitAngleOffset + 0.05
    familiar.Velocity = (familiar:GetOrbitPosition(player.Position) - familiar.Position)
end)

cosmos.Venus:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (familiar)
    local player = familiar:ToFamiliar().Player
	familiar.OrbitDistance = familiar:GetData().orbit_distance
    familiar.OrbitAngleOffset = familiar.OrbitAngleOffset + 0.035
    familiar.Velocity = (familiar:GetOrbitPosition(player.Position) - familiar.Position)
end)

cosmos.Pluto:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (familiar)
    local player = familiar:ToFamiliar().Player
	familiar.OrbitDistance = familiar:GetData().orbit_distance
    familiar.OrbitAngleOffset = familiar.OrbitAngleOffset + 0.02
    familiar.Velocity = (familiar:GetOrbitPosition(player.Position) - familiar.Position)
end)

cosmos:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(player, entity, _, _, damage_source, _)
    if damage_source.Entity then
        local random = utils.random(0,100) / 100.0
        if cosmos.Mercury:Matches(damage_source.Entity) then
            if random < cosmos.Mercury.burn_chance then
                entity:AddBurn(EntityRef(player), cosmos.Mercury.burn_duration, player.Damage)
            end
        elseif cosmos.Venus:Matches(damage_source.Entity) then
            if random < cosmos.Venus.charm_chance then
                entity:AddCharmed(EntityRef(player), cosmos.Venus.charm_duration)
            end
        elseif cosmos.Pluto:Matches(damage_source.Entity) then
            if random < cosmos.Pluto.freeze_chance then
                entity:AddFreeze(EntityRef(player), cosmos.Pluto.freeze_duration)
                entity:AddEntityFlags(EntityFlag.FLAG_ICE)
                entity:TakeDamage(20, 0, EntityRef(player), 0)
            end
        end
    end
end)

return cosmos
