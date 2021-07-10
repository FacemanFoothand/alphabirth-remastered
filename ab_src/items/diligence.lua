----------------------------------------------------------------------------
-- Item: Diligence
-- Originally from Pack 1
-- Immunity to fire, spikes, and bombs. 20% chance to dodge all damage
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local diligence = Item("Diligence")

diligence:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(entity, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	local ignore_damage = utils.random(1, 5)
	if ignore_damage == 1 then
		print("GAMERS")
		return false
	end

	if g.hasProtection(damage_flags, damage_source) then
		return false
	end
end)

return diligence