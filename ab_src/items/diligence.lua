----------------------------------------------------------------------------
-- Item: Diligence
-- Originally from Pack 1
-- Immunity to fire, spikes, and bombs. 20% chance to dodge all damage
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Diligence", "Immunity to {{Burning}} fire, {{RedPoop}} Red Poop, {{SacrificeRoom}} spikes, {{SpikedChest}} Spiked Chests and {{Bomb}} explosive damage#20% chance to ignore any damage taken#{{SacrificeRoom}} Spikes in Sacrifice Rooms still deal damage"},
    ["pt_br"] = {"Diligência", "Imunidade a {{Burning}} fogo, {{RedPoop}} Cocô Vermelho, {{SacrificeRoom}} estacas, {{Spiked}} Baús Armadilha e {{Bomb}} dano explosivo#20% de chance de ignorar qualquer dano recebido#{{SacrificeRoom}} Estacas em Quartos de Sarifício ainda dão dano"},
}

local diligence = Item("Diligence", desc)
diligence.dodge_chance = 0.2

g.RegisterProtectionFunction(function(player, damage_flags, damage_source)
	if player:HasCollectible(diligence.ID) and (
		damage_flags & DamageFlag.DAMAGE_FIRE == DamageFlag.DAMAGE_FIRE
		or (damage_flags & DamageFlag.DAMAGE_SPIKES == DamageFlag.DAMAGE_SPIKES and g.room:GetType() ~= RoomType.ROOM_SACRIFICE)
		or damage_flags & DamageFlag.DAMAGE_EXPLOSION == DamageFlag.DAMAGE_EXPLOSION
		or damage_flags & DamageFlag.DAMAGE_TNT == DamageFlag.DAMAGE_TNT
		or damage_flags & DamageFlag.DAMAGE_POOP == DamageFlag.DAMAGE_POOP
		or damage_flags & DamageFlag.DAMAGE_CHEST == DamageFlag.DAMAGE_CHEST
		or damage_source.Type == EntityType.ENTITY_FIREPLACE
        or utils.random(0, 100) / 100.0 < diligence.dodge_chance
	) then
		return true
	end
end)

diligence:AddCallback("PLAYER_TAKE_DAMAGE", function(player, _, damage_flags, damage_source, _, _)
	return not g.HasProtection(player, damage_flags, damage_source)
end)

return diligence
