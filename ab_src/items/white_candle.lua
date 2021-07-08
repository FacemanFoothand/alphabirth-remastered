----------------------------------------------------------------------------
-- Item: White Candle
-- Originally from Pack 1
-- Increase Angel Room/Soul heart chance. Chance to activate Holy Light on damage taken
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local WHITE_CANDLE = {
	ENABLED = true,
	NAME = "White Candle",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_whitecandle.anm2",
	AB_REF = nil,
	ITEM_REF = nil
}

function WHITE_CANDLE.setup(Alphabirth)
	WHITE_CANDLE.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.WHITE_CANDLE = Alphabirth.API_MOD:registerItem(WHITE_CANDLE.NAME, WHITE_CANDLE.COSTUME)
	WHITE_CANDLE.ITEM_REF = Alphabirth.ITEMS.PASSIVE.WHITE_CANDLE
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, WHITE_CANDLE.postNewRoom)
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, WHITE_CANDLE.entityDamage)
end

function WHITE_CANDLE.postNewRoom()
	local level = AlphaAPI.GAME_STATE.LEVEL
	local room = AlphaAPI.GAME_STATE.ROOM

	local plist = utils.hasCollectible(WHITE_CANDLE.ITEM_REF.id)
	if plist then
		if room:IsFirstVisit() and level:GetCurrentRoomIndex() ~= level:GetStartingRoomIndex() then
			level:AddAngelRoomChance(0.1)
		end
	end
end

function WHITE_CANDLE.entityDamage(entity, damage_amount, damage_flags, damage_source, invincibility_frames)
	if entity.Type == EntityType.ENTITY_PLAYER then
		local player = entity:ToPlayer()
		if player:HasCollectible(WHITE_CANDLE.ITEM_REF.id)
		and not WHITE_CANDLE.AB_REF.hasProtection(player, damage_flags, damage_source) then
			local num_lasers = random(2, 8)
			for i = 1, num_lasers do
				local entities = AlphaAPI.entities.all
				local chance_to_hit = random(1, 2)
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
							entity = vulnerable_entities[random(1, #vulnerable_entities)]
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
	end
end

return WHITE_CANDLE