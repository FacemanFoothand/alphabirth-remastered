----------------------------------------------------------------------------
-- Item: Cologne
-- Originally from Pack 1
-- Chance to charm nearby enemies
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local COLOGNE = {
	ENABLED = true,
	NAME = "Cologne",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_cologne.anm2",
	AB_REF = nil,
	ITEM_REF = nil,

	CHARM_DURATION = 100,
	CHARM_CHANCE = 100
}

function COLOGNE.setup(Alphabirth)
	COLOGNE.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.COLOGNE = Alphabirth.API_MOD:registerItem(COLOGNE.NAME, COLOGNE.COSTUME)
	COLOGNE.ITEM_REF = Alphabirth.ITEMS.PASSIVE.COLOGNE
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, COLOGNE.entityDamage)
end

function COLOGNE.handle(player)
	local max_charm_distance = 120 * math.max( player.SpriteScale.X, player.SpriteScale.Y )
	for _, entity in ipairs(AlphaAPI.entities.all) do
		if player.Position:Distance(entity.Position) < max_charm_distance
		and entity:IsVulnerableEnemy() then
			local charm_roll = random(1, COLOGNE.CHARM_CHANCE)
			if charm_roll == 1 then
				entity:AddCharmed(EntityRef(player), COLOGNE.CHARM_DURATION)
			end
		end
	end
end

function COLOGNE.evaluate(player, cache_flag)
		if cache_flag == CacheFlag.CACHE_TEARCOLOR then
			player.TearColor = Color(
                                    0.867, 0.627, 0.867,    -- RGB
									1,                      -- Alpha
									0, 0, 0                 -- RGB Offset
                                )
		end
end

return COLOGNE