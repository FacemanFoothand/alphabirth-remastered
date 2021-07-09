----------------------------------------------------------------------------
-- Item: Mutant Fetus
-- Originally from Pack 1
-- Has a chance to spawn a bomb when you hit an enemy
----------------------------------------------------------------------------

-- [[ He'll yeah brother ]]

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local mutant_fetus = Item("Mutant Fetus")
mutant_fetus.charm_duration = 100
mutant_fetus.charm_chance = 100

g.mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(entity, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	local player = damage_source.Parent

	if AlphaAPI.hasFlag(damage_source, MUTANT_FETUS.AB_REF.ENTITY_FLAGS.MUTANT_TEAR)
	and entity:IsActiveEnemy(false) then
		player = player:ToPlayer()
		AlphaAPI.clearFlag(damage_source, MUTANT_FETUS.AB_REF.ENTITY_FLAGS.MUTANT_TEAR)
		local bomb_roll = random(1, 200)
		if bomb_roll == 1 then
			Isaac.Spawn(
				EntityType.ENTITY_BOMBDROP,
				BombVariant.BOMB_SUPERTROLL,
				0,
				entity.Position,
				utils.VECTOR_ZERO,
				player
			)
		else
			player = player:ToPlayer()
			player:FireBomb( entity.Position, utils.VECTOR_ZERO )
		end
	end
end)

g.mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(entity, data)
	local tear = entity:ToTear()
	if tear.SpawnerType == EntityType.ENTITY_PLAYER then
		local plist = utils.hasCollectible(MUTANT_FETUS.ITEM_REF.id)
		if plist then
			for _, player in ipairs(plist) do
				if GetPtrHash(tear.Parent) == GetPtrHash(player) and AlphaAPI.getLuckRNG(7, 3) and entity.Variant ~= TearVariant.CHAOS_CARD then
					AlphaAPI.addFlag(tear, MUTANT_FETUS.AB_REF.ENTITY_FLAGS.MUTANT_TEAR)
					local tear_sprite = entity:GetSprite()
					tear_sprite:Load("gfx/animations/effects/animation_tears_mutantfetus.anm2", true)
					tear_sprite:Play("Idle")
					tear_sprite:LoadGraphics()
				end
			end
		end
	end
end, EntityType.ENTITY_TEAR)

return mutant_fetus