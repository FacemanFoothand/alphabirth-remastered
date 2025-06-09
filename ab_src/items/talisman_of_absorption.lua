----------------------------------------------------------------------------
-- Item: Talisman of Absorption
-- Originally from Pack 1
-- Lasers heal Isaac.
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local g = require("ab_src.modules.globals")

local talisman_of_absorption = Item("Talisman of Absorption") ---@type Item
talisman_of_absorption.desc = include("ab_src.integrations.eid").talisman_of_absorption

---@param player EntityPlayer
---@param damage_flags DamageFlag|integer
g.RegisterProtectionFunction(function(player, damage_flags, _)
    if player:HasCollectible(talisman_of_absorption.ID) and (
        damage_flags & DamageFlag.DAMAGE_LASER == DamageFlag.DAMAGE_LASER
    ) then
        player:AddHearts(1)
        player:TakeDamage(1, DamageFlag.DAMAGE_FAKE, EntityRef(player), 90)
        return true
    end
end)

---@param player EntityPlayer
---@param damage_flags DamageFlag
talisman_of_absorption:AddCallback("PLAYER_TAKE_DAMAGE", function(player, _, damage_flags, damage_source)
	return not g.HasProtection(player, damage_flags, damage_source)
end)

return talisman_of_absorption
