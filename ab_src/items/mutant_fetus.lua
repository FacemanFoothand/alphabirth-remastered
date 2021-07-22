----------------------------------------------------------------------------
-- Item: Mutant Fetus
-- Originally from Pack 1
-- Has a chance to spawn a bomb when you hit an enemy
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")
local utils = include("ab_src.modules.utils")

local mutant_fetus = Item("Mutant Fetus")
local tear_flag = Flag("mutant_fetus_tear")
mutant_fetus.charm_duration = 100
mutant_fetus.charm_chance = 100

mutant_fetus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(player, entity, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	if tear_flag:EntityHas(damage_source) and entity:IsActiveEnemy(false) then
		tear_flag:Clear(damage_source)
		local bomb_roll = utils.random(1, 200)
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

mutant_fetus:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, function(player, tear)
	if tear.Variant ~= TearVariant.CHAOS_CARD and utils.getLuckRNG(player, 7, 3) then
		tear_flag:Apply(tear)
		local tear_sprite = tear:GetSprite()
		tear_sprite:Load("gfx/animations/effects/animation_tears_mutantfetus.anm2", true)
		tear_sprite:Play("Idle")
		tear_sprite:LoadGraphics()
	end
end)

return mutant_fetus