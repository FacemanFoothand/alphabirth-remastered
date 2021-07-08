----------------------------------------------------------------------------
-- Item: Furnace
-- Originally from Pack 1
-- Shoots fires in all directions on damage taken
----------------------------------------------------------------------------

local utils = include("code/utils")

local FURNACE = {
	ENABLED = true,
	NAME = "Furnace",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_furnace.anm2",
	AB_REF = nil,
	ITEM_REF = nil,
}

function FURNACE.setup(Alphabirth)
	FURNACE.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.FURNACE = Alphabirth.API_MOD:registerItem(FURNACE.NAME, FURNACE.COSTUME)
	FURNACE.ITEM_REF = Alphabirth.ITEMS.PASSIVE.FURNACE
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, FURNACE.entityDamage)
end

function FURNACE.entityDamage(entity, damage_amount, damage_flags, damage_source, invincibility_frames)
	if entity.Type == EntityType.ENTITY_PLAYER then
		local player = entity:ToPlayer()

		if player:HasCollectible(FURNACE.ITEM_REF.ITEMS.PASSIVE.FURNACE.id)
		and not FURNACE.AB_REF.hasProtection(player, damage_flags, damage_source) then
			for _, direction in ipairs(utils.direction_list) do
				Isaac.Spawn(
					EntityType.ENTITY_EFFECT,
					EffectVariant.RED_CANDLE_FLAME,
					0,
					player.Position,
					direction * (10 * player.ShotSpeed),
					player
				)
			end
		end
	end
end

return FURNACE