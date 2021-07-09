----------------------------------------------------------------------------
-- Item: White Candle
-- Originally from Pack 1
-- Increase Angel Room/Soul heart chance. Chance to activate Holy Light on damage taken
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local white_candle = Item("White Candle")

white_candle:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(player)
	local level = g.level
	local room = g.room

	if room:IsFirstVisit() and level:GetCurrentRoomIndex() ~= level:GetStartingRoomIndex() then
		level:AddAngelRoomChance(0.1)
	end
end)

white_candle:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(entity, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	local player = entity:ToPlayer()
	if not g.hasProtection(player, damage_flags, damage_source) then
		local num_lasers = utils.random(2, 8)
		for i = 1, num_lasers do
			local entities = Isaac:GetRoomEntities()
			local chance_to_hit = utils.random(1, 2)
			if chance_to_hit == 1 and #entities then
				local vulnerable_entities = {}
				for _, entity in ipairs(entities) do
					if entity:IsVulnerableEnemy() then
						vulnerable_entities[#vulnerable_entities + 1] = entity
					end
				end

				if #vulnerable_entities then
					local entity = nil
					if #vulnerable_entities ~= 1 then
						entity = vulnerable_entities[utils.random(1, #vulnerable_entities)]
					else
						entity = vulnerable_entities[1]
					end

					local position_to_hit = entity.Position
					Isaac.Spawn(
						EntityType.ENTITY_EFFECT,
						EffectVariant.CRACK_THE_SKY,
						0,              	-- Subtype
						position_to_hit,
						utils.VECTOR_ZERO,	-- Velocity
						player          	-- Spawner
					)
				end
			else
				Isaac.Spawn(
					EntityType.ENTITY_EFFECT,
					EffectVariant.CRACK_THE_SKY,
					0,              	-- Subtype
					AlphaAPI.GAME_STATE.ROOM:GetRandomPosition(0),
					utils.VECTOR_ZERO,	-- Velocity
					player          	-- Spawner
				)
			end
		end
	end
end)

return white_candle