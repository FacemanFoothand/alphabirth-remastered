----------------------------------------------------------------------------
-- Item: Black Pepper
-- Originally from Pack 1
-- Fire a monstro's lung-esque volley of tears
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local black_pepper = {
	ENABLED = true,
	NAME = "Black Pepper",
	TYPE = "Active",
	AB_REF = nil,
	HOLDING_BLACK_PEPPER = false,
	ITEM_REF = nil
}

function black_pepper.setup(Alphabirth)
	black_pepper.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.BLACK_PEPPER = Alphabirth.API_MOD:registerItem(black_pepper.NAME)
	black_pepper.ITEM_REF = Alphabirth.ITEMS.PASSIVE.BLACK_PEPPER
	black_pepper.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, black_pepper.trigger)
	black_pepper.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, black_pepper.update)
end

function black_pepper.trigger()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	player:AnimateCollectible(black_pepper.ITEM_REF.id, "LiftItem", "PlayerPickup")
	black_pepper.HOLDING_BLACK_PEPPER = true
end

function black_pepper.update()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	if black_pepper.HOLDING_BLACK_PEPPER then
		local direction = player:GetFireDirection()
		local direction_vector = utils.getVectorFromDirection(direction)

		if direction_vector ~= utils.VECTOR_ZERO then
			for tears = 1, 15 do
				-- Get random angle per tear
				local angle = 15
				local random_angle = math.rad(random(-math.floor(angle), math.floor(angle)))

				-- Convert angle to a vector per tear
				local angular_vector = utils.VECTOR_ZERO
				angular_vector.X = math.cos(random_angle) * direction_vector.X -
						math.sin(random_angle) * direction_vector.Y
				angular_vector.Y = math.sin(random_angle) * direction_vector.X -
						math.cos(random_angle) * direction_vector.Y

				-- Get random shot speed per tear
				local randomMag = random(5, 15)
				local shot_speed = Vector(angular_vector.X * randomMag, angular_vector.Y * randomMag)

				-- Fire Tear
				local tear = player:FireTear(
					player.Position,    -- position
					shot_speed,         -- velocity
					false,              -- From API: CanBeEye?
					false,              -- From API: NoTractorBeam
					false               -- From API: CanTriggerStreakEnd
				)
				tear:ChangeVariant(26)
				tear.TearFlags = tear.TearFlags | TearFlags.TEAR_BOOGER
			end

			player:AnimateCollectible(black_pepper.ITEM_REF.id, "HideItem", "PlayerPickup")
			black_pepper.HOLDING_BLACK_PEPPER = false
		end
	end
end

return black_pepper