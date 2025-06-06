----------------------------------------------------------------------------
-- Item: Talisman of Absorption
-- Originally from Pack 1
-- Lasers heal Isaac.
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")

local talisman_of_absorption = Item("Talisman of Absorption") ---@type Item
talisman_of_absorption.desc = include("ab_src.integrations.eid").talisman_of_absorption

---@param player EntityPlayer
---@param damage_flags DamageFlag
talisman_of_absorption:AddCallback("PLAYER_TAKE_DAMAGE", function(player, _, damage_flags)
	if (damage_flags & DamageFlag.DAMAGE_LASER == DamageFlag.DAMAGE_LASER) then
		player:AddHearts(2)
		return false
	end
end)

return talisman_of_absorption
