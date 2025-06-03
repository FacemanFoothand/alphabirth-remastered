----------------------------------------------------------------------------
-- Item: Addicted
-- Originally from Pack 1
-- Has a chance to swallow a random pill when damage is taken
----------------------------------------------------------------------------

local valid_effects = {
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
	PillEffect.PILLEFFECT_VURP,
}

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Addicted", "#{{Pill}} Upon being damaged Isaac has a chance to activate a random pill effect#{{Luck}} Static 1/6 chance"},
    ["pt_br"] = {"Viciado", "#{{Pill}} Ao receber dano, Isaac terá uma chance de ativar um efeito de pílula{{Luck}} Chance estática de 1/6"},
}

local addicted = Item("Addicted", desc)

addicted:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(entity, _, damage_flags, damage_source, _)
    local player = entity:ToPlayer()
    if not g.HasProtection(player, damage_flags, damage_source) then
        local pill_chance = utils.random(1, 6)
        if pill_chance == 1 then
            local chosen_pill = valid_effects[utils.random(1, #valid_effects)]
            player:UsePill(chosen_pill, PillColor.PILL_BLUE_BLUE)
        end
    end
end, EntityType.ENTITY_PLAYER)


return addicted
