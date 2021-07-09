----------------------------------------------------------------------------
-- Item: Cool Bean
-- Originally from Pack 1
-- Freezes nearby enemies
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")
local utils = include("ab_src.modules.utils")

local cool_bean = Item("Cool Bean")
local ice_fart = EntityConfig("Ice Fart")
cool_bean.freeze_range = 160
cool_bean.freeze_duration = 150

cool_bean:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	for _, entity in ipairs(Isaac.GetRoomEntities()) do
		if entity:IsActiveEnemy() then
			local distance_to_enemy = player.Position:Distance(entity.Position)
			if distance_to_enemy < cool_bean.freeze_range then
				entity:AddFreeze(EntityRef(player), cool_bean.freeze_duration)
			end
		end
	end

	Isaac.Spawn(ice_fart.ID,
				ice_fart.Variant,  	-- Variant
				0,                          					-- Subtype
				player.Position,
				utils.VECTOR_ZERO,          					-- Velocity
				player)                    				 		-- Spawner
	g.sfx:Play(SoundEffect.SOUND_FART,1.0,0,false,1.0)
end)

return cool_bean