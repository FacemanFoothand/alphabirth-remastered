----------------------------------------------------------------------------
-- Item: Delirium's Brain
-- Originally from Pack 1
-- Reverse trajectory of all tears and damages enemies
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local deliriums_brain = Item("Delirium's Brain")

deliriums_brain:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	for _, entity in ipairs(Isaac.GetRoomEntities()) do
		if entity.Type == EntityType.ENTITY_TEAR or entity.Type == EntityType.ENTITY_PROJECTILE then
			local tear_position = entity.Position
			local reverse_tear_velocity = Vector(-entity.Velocity.X, -entity.Velocity.Y)

			-- Find Tear Synergies
			if player:HasCollectible(CollectibleType.COLLECTIBLE_TECHNOLOGY) then
				player:FireTechLaser(tear_position,
									 LaserOffset.LASER_TECH1_OFFSET,
									 reverse_tear_velocity,
									 false,
									 false)
			elseif player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then
				player:FireTechXLaser(tear_position, reverse_tear_velocity, 1) -- radius
			elseif player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) then
				player:FireDelayedBrimstone(reverse_tear_velocity:GetAngleDegrees(), entity)
			elseif player:HasCollectible(CollectibleType.COLLECTIBLE_DR_FETUS) then
				player:FireBomb(tear_position, reverse_tear_velocity)
			else
				-- NOTE: Mom's Knife WILL NOT work
				player:FireTear(
					tear_position,          -- position
					reverse_tear_velocity,  -- velocity
					false,                  -- From API: CanBeEye?
					false,                  -- From API: NoTractorBeam
					false                   -- From API: CanTriggerStreakEnd
				)
			end

			-- Remove The Old Tear
			entity:Die()
		end
	end
end)

return deliriums_brain