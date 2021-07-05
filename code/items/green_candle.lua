----------------------------------------------------------------------------
-- Item: Green Candle
-- Originally from Pack 1
-- Fire a monstro's lung-esque volley of tears
----------------------------------------------------------------------------

local utils = include("code/utils")

local GREEN_CANDLE = {
	ENABLED = true,
	NAME = "Green Candle",
	TYPE = "Active",
	AB_REF = nil,
	ITEM_REF = nil,

	HOLDING_GREEN_CANDLE = false,
	POISON_RANGE = 120,
	POSION_DURATION = 120,
}

function GREEN_CANDLE.setup(Alphabirth)
	GREEN_CANDLE.AB_REF = Alphabirth
	Alphabirth.ITEMS.ACTIVE.GREEN_CANDLE = Alphabirth.API_MOD:registerItem(GREEN_CANDLE.NAME)
	GREEN_CANDLE.ITEM_REF = Alphabirth.ITEMS.ACTIVE.GREEN_CANDLE
	GREEN_CANDLE.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, GREEN_CANDLE.trigger)
	GREEN_CANDLE.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, GREEN_CANDLE.update)
end

function GREEN_CANDLE.trigger()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	player:AnimateCollectible(GREEN_CANDLE.ITEM_REF.id, "LiftItem", "PlayerPickup")
	GREEN_CANDLE.HOLDING_GREEN_CANDLE = true
end

function GREEN_CANDLE.update()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	if GREEN_CANDLE.HOLDING_GREEN_CANDLE then
		local direction = player:GetFireDirection()
		local direction_vector = utils.getVectorFromDirection(direction)

		if direction_vector ~= utils.VECTOR_ZERO then
			local firevelocity = (direction_vector * player.ShotSpeed) * 28
			GREEN_CANDLE.AB_REF.ENTITIES.GREEN_CANDLE:spawn(
				player.Position,
				firevelocity,
				player
			)

			player:AnimateCollectible(GREEN_CANDLE.ITEM_REF.id, "HideItem", "PlayerPickup")
			GREEN_CANDLE.HOLDING_GREEN_CANDLE = false
		end
	end

	-- Poison effect
	for i,entity in ipairs(AlphaAPI.entities.all) do
		if entity.Variant == GREEN_CANDLE.AB_REF.ENTITIES.GREEN_CANDLE.variant and entity.SubType == GREEN_CANDLE.AB_REF.ENTITIES.GREEN_CANDLE.subtype then
			for _, enemy in ipairs(AlphaAPI.entities.enemies) do
				local distance_to_enemy = entity.Position:Distance(enemy.Position)
				if distance_to_enemy < GREEN_CANDLE.POISON_RANGE then
					enemy:AddPoison(
						EntityRef(player),
						GREEN_CANDLE.POSION_DURATION,
						player.Damage
					)
				end
			end
		end
	end
end

return GREEN_CANDLE