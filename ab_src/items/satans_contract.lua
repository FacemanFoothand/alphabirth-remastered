----------------------------------------------------------------------------
-- Item: Satan's Contract
-- Originally from Pack 1
-- Doubles the player's damage and damage taken
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local satans_contract = Item("Satan's Contract")

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

satans_contract:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(entity, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	local player = entity:ToPlayer()
	if player:HasCollectible(satans_contract.ID)
	and not g.hasProtection(player, damage_flags, damage_source) then
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
