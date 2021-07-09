----------------------------------------------------------------------------
-- Item: Black Pepper
-- Originally from Pack 1
-- Fire a monstro's lung-esque volley of tears
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local black_pepper = Item("Black Pepper")

utils.mixTables(g.defaultPlayerSaveData, {
	holding_black_pepper = false
})

black_pepper:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	local save = g.getPlayerSave(player)
	player:AnimateCollectible(black_pepper.ID, "LiftItem", "PlayerPickup")
	save.holding_black_pepper = true
end)

black_pepper:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
	local save = g.getPlayerSave(player)
	if save.holding_black_pepper then
		local direction = player:GetFireDirection()
		local direction_vector = utils.getVectorFromDirection(direction)

		if direction_vector ~= utils.VECTOR_ZERO then
			for tears = 1, 15 do
				-- Get random angle per tear
				local angle = 15
				local random_angle = math.rad(utils.random(-math.floor(angle), math.floor(angle)))

				-- Convert angle to a vector per tear
				local angular_vector = Vector.Zero
				angular_vector.X = math.cos(random_angle) * direction_vector.X -
						math.sin(random_angle) * direction_vector.Y
				angular_vector.Y = math.sin(random_angle) * direction_vector.X -
						math.cos(random_angle) * direction_vector.Y

				-- Get random shot speed per tear
				local random_mag = utils.random(5, 15)
				local shot_speed = Vector(angular_vector.X * random_mag, angular_vector.Y * random_mag)

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

			player:AnimateCollectible(black_pepper.ID, "HideItem", "PlayerPickup")
			save.holding_black_pepper = false
		end
	end
end)

return black_pepper