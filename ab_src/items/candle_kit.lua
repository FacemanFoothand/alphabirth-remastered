----------------------------------------------------------------------------
-- Item: Candle Kit
-- Originally on Pack 1
-- Creates two candle orbitals around Isaac.
-- Each orbital does contact damage and ignites enemies.
----------------------------------------------------------------------------

local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")
local utils = include("ab_src.modules.utils")

local candle_kit = Item("Candle Kit")
local candle_entity = EntityConfig("Candle Kit")

candle_kit:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	if cache_flag == CacheFlag.CACHE_FAMILIARS then
		local amount_to_spawn = (player:GetCollectibleNum(candle_kit.ID) * 2) * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
		player:CheckFamiliar(candle_entity.Variant, amount_to_spawn, utils.RNG)
	end
end)

candle_entity:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function (familiar)
	familiar.OrbitLayer = 4
	familiar:RecalculateOrbitOffset(familiar.OrbitLayer, true)
end)

candle_entity:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (familiar)
	local player = familiar.Player
	familiar.OrbitDistance = EntityFamiliar.GetOrbitDistance(familiar.OrbitLayer)
	local target_position = familiar:GetOrbitPosition(player.Position)
	familiar.Velocity = target_position - familiar.Position
	familiar.CollisionDamage = player.Damage * 0.8
	for i, e in ipairs(AlphaAPI.entities.enemies) do
		if  e.Position:Distance(familiar.Position) < 55 and utils.random(60) == 1 then
			e:AddBurn(EntityRef(familiar), 120, 1.0)
		end
	end
end)

return candle_kit