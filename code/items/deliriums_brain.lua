----------------------------------------------------------------------------
-- Item: Delirium's Brain
-- Originally from Pack 1
-- Reverse trajectory of all tears and damages enemies
----------------------------------------------------------------------------

local utils = include("code/utils")

local DELIRIUMS_BRAIN = {
	ENABLED = true,
	NAME = "Delirium's Brain",
	TYPE = "Active",
	AB_REF = nil,
	ITEM_REF = nil
}

function DELIRIUMS_BRAIN.setup(Alphabirth)
	DELIRIUMS_BRAIN.AB_REF = Alphabirth
	Alphabirth.ITEMS.ACTIVE.DELIRIUMS_BRAIN = Alphabirth.API_MOD:registerItem(DELIRIUMS_BRAIN.NAME)
	DELIRIUMS_BRAIN.ITEM_REF = Alphabirth.ITEMS.ACTIVE.DELIRIUMS_BRAIN
	DELIRIUMS_BRAIN.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, DELIRIUMS_BRAIN.trigger)
end

function DELIRIUMS_BRAIN.trigger()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	for _, entity in ipairs(AlphaAPI.entities.all) do
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
end

return DELIRIUMS_BRAIN