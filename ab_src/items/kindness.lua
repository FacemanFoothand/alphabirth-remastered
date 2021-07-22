----------------------------------------------------------------------------
-- Item: Kindness
-- Originally from Pack 1
-- Randomly charms enemies. Chance to spawn hearts on killing charmed enemies
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")
local utils = include("ab_src.modules.utils")

local kindness = Item("Kindness")
kindness.chance = 20 -- 1 out of 100
kindness.charm_duration = 100
kindness.last_charm_frame = 0
kindness.application_interval = 10

kindness:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
	local valid_entities = nil
	local should_find_target = false
	local game_frame = g.game:GetFrameCount()
	if game_frame - kindness.last_charm_frame >= kindness.charm_duration and
		game_frame % kindness.application_interval == 0 and
		utils.random( 1, math.max( 1, kindness.chance - player.Luck ) ) <= 1 then
		should_find_target = true
	end

	for _, entity in ipairs(Isaac:GetRoomEntities()) do
		if entity:IsVulnerableEnemy() and entity:HasEntityFlags(EntityFlag.FLAG_CHARM) and entity:HasMortalDamage() and not entity:IsDead() then
			Isaac.Spawn(
				EntityType.ENTITY_PICKUP,
				PickupVariant.PICKUP_HEART,
				HeartSubType.HEART_HALF,
				entity.Position,
				entity.Velocity,
				entity
			)
		end
		if should_find_target and entity:IsVulnerableEnemy() then
			valid_entities = valid_entities or {}
			valid_entities[#valid_entities + 1] = entity
		end
	end

	if valid_entities ~= nil and should_find_target and #valid_entities > 0 then
		valid_entities[utils.random(#valid_entities)]:AddCharmed(EntityRef(player), 100)
		kindness.last_charm_frame = game_frame
	end
end)

return kindness