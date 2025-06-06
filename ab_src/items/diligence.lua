----------------------------------------------------------------------------
-- Item: Diligence
-- Originally from Pack 1
-- Immunity to fire, spikes, and bombs. 20% chance to dodge all damage
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local diligence = Item("Diligence") ---@type Item
diligence.desc = include("ab_src.integrations.eid").diligence
diligence.dodge_chance = 0.2

---@param player EntityPlayer
---@param damage_flags DamageFlag|integer
---@param damage_source EntityRef
g.RegisterProtectionFunction(function(player, damage_flags, damage_source)
	if player:HasCollectible(diligence.ID) and (
		damage_flags & DamageFlag.DAMAGE_FIRE == DamageFlag.DAMAGE_FIRE
		or (damage_flags & DamageFlag.DAMAGE_SPIKES == DamageFlag.DAMAGE_SPIKES and g.room:GetType() ~= RoomType.ROOM_SACRIFICE)
		or damage_flags & DamageFlag.DAMAGE_EXPLOSION == DamageFlag.DAMAGE_EXPLOSION
		or damage_flags & DamageFlag.DAMAGE_TNT == DamageFlag.DAMAGE_TNT
		or damage_flags & DamageFlag.DAMAGE_POOP == DamageFlag.DAMAGE_POOP
		or damage_flags & DamageFlag.DAMAGE_CHEST == DamageFlag.DAMAGE_CHEST
		or damage_source.Type == EntityType.ENTITY_FIREPLACE
        or utils.random() < diligence.dodge_chance
	) then
		return true
	end
end)

---@param player EntityPlayer
---@param damage_flags DamageFlag|integer
---@param damage_source EntityRef
diligence:AddCallback("PLAYER_TAKE_DAMAGE", function(player, _, damage_flags, damage_source)
	return not g.HasProtection(player, damage_flags, damage_source)
end)

return diligence
