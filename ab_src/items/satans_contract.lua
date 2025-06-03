----------------------------------------------------------------------------
-- Item: Satan's Contract
-- Originally from Pack 1
-- Doubles the player's damage and damage taken
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Satan's Contract", "{{ArrowUp}} Isaac deals dobule damage#{{ArrowDown}} Isaac takes double damage"},
    ["pt_br"] = {"Contrato do Satã", "{{ArrowUp}} Isaac dá o dobro de Dano#{{ArrowDown}} Isaac leva o dobro de dano"},
}

local satans_contract = Item("Satan's Contract", desc)

satans_contract:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	if cache_flag == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage * 2
	elseif cache_flag == CacheFlag.CACHE_FLYING then
		player.CanFly = true
	elseif cache_flag == CacheFlag.CACHE_TEARCOLOR then
		player.TearColor = Color(
			0.698, 0.113, 0.113,    -- RGB
			1,                      -- Alpha
			0, 0, 0                 -- RGB Offset
	   )
	end
end)

satans_contract:AddCallback("PLAYER_TAKE_DAMAGE", function(player, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	if not g.HasProtection(player, damage_flags, damage_source) then
		for i = 1, damage_amount do
			if player:GetSoulHearts() > 0 then
				player:AddSoulHearts(-1)
			else
				player:AddHearts(-1)
			end
		end

		if player:GetHearts() == 0 and player:GetSoulHearts() == 0 then
			player:Die()
		end
	end
end)

return satans_contract
