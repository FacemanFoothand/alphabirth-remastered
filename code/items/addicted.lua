----------------------------------------------------------------------------
-- Item: Addicted
-- Originally from Pack 1
-- Has a chance to swallow a random pill when damage is taken
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local ADDICTED = {
	ENABLED = true,
	NAME = "Addicted",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_addicted.anm2",
	AB_REF = nil,
	ITEM_REF = nil,
	VALID_EFFECTS = {
		PillEffect.PILLEFFECT_48HOUR_ENERGY,
		PillEffect.PILLEFFECT_ADDICTED,
		PillEffect.PILLEFFECT_AMNESIA,
		PillEffect.PILLEFFECT_BAD_GAS,
		PillEffect.PILLEFFECT_BALLS_OF_STEEL,
		PillEffect.PILLEFFECT_BOMBS_ARE_KEYS,
		PillEffect.PILLEFFECT_EXPLOSIVE_DIARRHEA,
		PillEffect.PILLEFFECT_FRIENDS_TILL_THE_END,
		PillEffect.PILLEFFECT_FULL_HEALTH,
		PillEffect.PILLEFFECT_GULP,
		PillEffect.PILLEFFECT_HEALTH_UP,
		PillEffect.PILLEFFECT_HORF,
		PillEffect.PILLEFFECT_I_FOUND_PILLS,
		PillEffect.PILLEFFECT_IM_DROWSY,
		PillEffect.PILLEFFECT_IM_EXCITED,
		PillEffect.PILLEFFECT_INFESTED_EXCLAMATION,
		PillEffect.PILLEFFECT_INFESTED_QUESTION,
		PillEffect.PILLEFFECT_LARGER,
		PillEffect.PILLEFFECT_LEMON_PARTY,
		PillEffect.PILLEFFECT_LUCK_DOWN,
		PillEffect.PILLEFFECT_LUCK_UP,
		PillEffect.PILLEFFECT_PRETTY_FLY,
		PillEffect.PILLEFFECT_RANGE_DOWN,
		PillEffect.PILLEFFECT_RANGE_UP,
		PillEffect.PILLEFFECT_SPEED_DOWN,
		PillEffect.PILLEFFECT_SPEED_UP,
		PillEffect.PILLEFFECT_TEARS_DOWN,
		PillEffect.PILLEFFECT_TEARS_UP,
		PillEffect.PILLEFFECT_TELEPILLS,
		PillEffect.PILLEFFECT_PARALYSIS,
		PillEffect.PILLEFFECT_SEE_FOREVER,
		PillEffect.PILLEFFECT_PHEROMONES,
		PillEffect.PILLEFFECT_WIZARD,
		PillEffect.PILLEFFECT_PERCS,
		PillEffect.PILLEFFECT_RELAX,
		PillEffect.PILLEFFECT_QUESTIONMARK,
		PillEffect.PILLEFFECT_SMALLER,
		PillEffect.PILLEFFECT_POWER,
		PillEffect.PILLEFFECT_RETRO_VISION,
		PillEffect.PILLEFFECT_X_LAX,
		PillEffect.PILLEFFECT_SOMETHINGS_WRONG,
		PillEffect.PILLEFFECT_SUNSHINE,
		PillEffect.PILLEFFECT_VURP
	}
}

function ADDICTED.setup(Alphabirth)
	ADDICTED.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.ADDICTED = Alphabirth.API_MOD:registerItem(ADDICTED.NAME, ADDICTED.COSTUME)
	ADDICTED.ITEM_REF = Alphabirth.ITEMS.PASSIVE.ADDICTED
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, ADDICTED.entityDamage)
end

function ADDICTED.entityDamage(entity, damage_amount, damage_flags, damage_source, invincibility_frames)
	if entity.Type == EntityType.ENTITY_PLAYER then
		local player = entity:ToPlayer()
		if player:HasCollectible(ADDICTED.ITEM_REF.id)
		and not ADDICTED.AB_REF.hasProtection(player, damage_flags, damage_source) then
			local pill_chance = random(1, 6)
			if pill_chance == 1 then
				local chosen_pill = ADDICTED.VALID_EFFECTS[random(1, #ADDICTED.VALID_EFFECTS)]
				player:UsePill(chosen_pill, PillColor.PILL_BLUE_BLUE)
			end
		end
	end
end

return ADDICTED