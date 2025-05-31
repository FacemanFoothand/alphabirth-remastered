----------------------------------------------------------------------------
-- Item: Diligence
-- Originally from Pack 1
-- Immunity to fire, spikes, and bombs. 20% chance to dodge all damage
----------------------------------------------------------------------------

local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Diligence", "Immunity to {{Burning}} fire, {{RedPoop}} Red Poop, {{SacrificeRoom}} spikes, {{SpikedChest}} Spiked Chests and {{Bomb}} explosive damage#20% chance to ignore any damage taken#{{SacrificeRoom}} Spikes in Sacrifice Rooms still deal damage"},
    ["pt_br"] = {"Diligência", "Imunidade a {{Burning}} fogo, {{RedPoop}} Cocô Vermelho, {{SacrificeRoom}} estacas, {{Spiked}} Baús Armadilha e {{Bomb}} dano explosivo#20% de chance de ignorar qualquer dano recebido#{{SacrificeRoom}} Estacas em Quartos de Sarifício ainda dão dano"},
}

local diligence = Item("Diligence", desc)

local function hasDiligenceProtection(damage_flags, damage_source)
	if (
		damage_flags & DamageFlag.DAMAGE_FIRE == DamageFlag.DAMAGE_FIRE
		or (damage_flags & DamageFlag.DAMAGE_SPIKES == DamageFlag.DAMAGE_SPIKES and AlphaAPI.GAME_STATE.ROOM:GetType() ~= RoomType.ROOM_SACRIFICE)
		or damage_flags & DamageFlag.DAMAGE_EXPLOSION == DamageFlag.DAMAGE_EXPLOSION
		or damage_flags & DamageFlag.DAMAGE_TNT == DamageFlag.DAMAGE_TNT
		or damage_flags & DamageFlag.DAMAGE_POOP == DamageFlag.DAMAGE_POOP
		or damage_flags & DamageFlag.DAMAGE_CHEST == DamageFlag.DAMAGE_CHEST
		or damage_source.Type == EntityType.ENTITY_FIREPLACE
	) then
		return true
	end
end

diligence:AddCallback("PLAYER_TAKE_DAMAGE", function(player, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	local ignore_damage = utils.random(1, 5)
	if ignore_damage == 1 then
		return false
	end

	if hasDiligenceProtection(damage_flags, damage_source) then
		return false
	end
end)

return diligence
