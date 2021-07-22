----------------------------------------------------------------------------
-- Item: Talisman of Absorption
-- Originally from Pack 1
-- Lasers heal Isaac.
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local talisman_of_absorption = Item("Talisman of Absorption")

talisman_of_absorption:AddCallback("PLAYER_TAKE_DAMAGE", function(player, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	print(damage_flags)
	if (damage_flags & DamageFlag.DAMAGE_LASER == DamageFlag.DAMAGE_LASER) then
		player:AddHearts(2)
		return false
	end
end)

return talisman_of_absorption