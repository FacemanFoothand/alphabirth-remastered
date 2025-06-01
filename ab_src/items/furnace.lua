----------------------------------------------------------------------------
-- Item: Furnace
-- Originally from Pack 1
-- Shoots fires in all directions on damage taken
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Furnace", "{{BleedingOut}} Upon taking damage {{Burning}} flames will shoot out of Isaac in all directions#{{Collectible289}} These are Red Candle flames"},
    ["pt_br"] = {"Fornalha", "{{BleedingOut}} Ao receber dano Isaac terá {{Burning}} chamas expulsadas ao seu redor#{{Collectible289}} São as chamas da Red Candle"},
}

local furnace = Item("Furnace", desc)

furnace:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(entity, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	local player = entity:ToPlayer()
	if not g.hasProtection(player, damage_flags, damage_source) then
		for _, direction in ipairs(utils.direction_list) do
			Isaac.Spawn(
				EntityType.ENTITY_EFFECT,
				EffectVariant.RED_CANDLE_FLAME,
				0,
				player.Position,
				direction:Normalized() * (10 * player.ShotSpeed),
				player
			)
		end
	end
end)

return furnace
