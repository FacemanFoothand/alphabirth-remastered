----------------------------------------------------------------------------
-- Item: Mutant Fetus
-- Originally from Pack 1
-- Has a chance to spawn a bomb when you hit an enemy
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local MUTANT_FETUS = {
	ENABLED = true,
	NAME = "Mutant Fetus",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_mutantfetus.anm2",
	AB_REF = nil,
	ITEM_REF = nil,

	CHARM_DURATION = 100,
	CHARM_CHANCE = 100
}

function MUTANT_FETUS.setup(Alphabirth)
	MUTANT_FETUS.AB_REF = Alphabirth
	Alphabirth.ENTITY_FLAGS.MUTANT_TEAR = AlphaAPI.createFlag()
	Alphabirth.ITEMS.PASSIVE.MUTANT_FETUS = Alphabirth.API_MOD:registerItem(MUTANT_FETUS.NAME, MUTANT_FETUS.COSTUME)
	MUTANT_FETUS.ITEM_REF = Alphabirth.ITEMS.PASSIVE.MUTANT_FETUS
    Alphabirth.API_MOD:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, MUTANT_FETUS.tearAppear, EntityType.ENTITY_TEAR)
	Alphabirth.MOD:AddCallback(ModCallbacks.TEAR_APP, MUTANT_FETUS.entityTakeDamage)
end

function MUTANT_FETUS.tearAppear(entity)
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
end

function MUTANT_FETUS.entityTakeDamage(entity, damage_amount, damage_flags, damage_source, invincibility_frames)
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
end

return MUTANT_FETUS