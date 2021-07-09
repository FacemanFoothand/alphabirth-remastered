----------------------------------------------------------------------------
-- Item: Divine Wrath
-- Originally from Pack 1
-- Ludovico-esque hush laser.
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")
local utils = include("ab_src.modules.utils")

local divine_wrath = Item("Divine Wrath")
local laser = EntityConfig("Divine Wrath")

utils.mixTables(g.defaultPlayerSaveData, {
	divine_wrath_previous_pos = nil
})

divine_wrath:AddCallback("ITEM_PICKUP", function(player)
	laser:Spawn(player.Position, Vector(0,0), player)
end)

divine_wrath:AddCallback("ITEM_REMOVE", function(player)
	for _, entity in ipairs(Isaac:GetRoomEntities()) do
		if laser:Matches(entity) and entity.Parent == player then
			entity:Remove()
		end
	end
end)

laser:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(familiar)
	familiar.GridCollisionClass = GridCollisionClass.COLLISION_NONE
end)

laser:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(familiar)
	local player = familiar.Player
	local save = g.getPlayerSave(player)
	local grid_position = g.room:GetGridIndex(familiar.Position)
	local grid_entity = g.room:GetGridEntity(grid_position)

	player.FireDelay = 1

	-- Grid entities it touches get hurt every sixth of a second / Excludes secret doors.
	if grid_entity then
		local is_door = grid_entity.Desc.Type == GridEntityType.GRID_DOOR
		local is_wall = grid_entity.Desc.Type == GridEntityType.GRID_WALL

		if not is_door and not is_wall then
			grid_entity:Destroy(true)
		end
	end

	if not g.room:IsPositionInRoom(familiar.Position, 0) then
		familiar.Position = save.divine_wrath_previous_pos
	end

	familiar.CollisionDamage = player.Damage * 1.5

	-- Destroy fireplaces.
	for _, entity in ipairs(Isaac:GetRoomEntities()) do
		if entity.Type == EntityType.ENTITY_FIREPLACE then
			if familiar.Position:Distance(entity.Position) < 30 then
				entity:TakeDamage(familiar.CollisionDamage, 0, EntityRef(player), 0)
			end
		elseif entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == 51 then
			if familiar.Position:Distance(entity.Position) < 30 then
				entity:ToPickup():TryOpenChest()
			end
		elseif entity.Type == EntityType.ENTITY_SLOT then
			if familiar.Position:Distance(entity.Position) < 30 then
				--Isaac.DebugString("Slot")
				entity:TakeDamage(familiar.CollisionDamage, DamageFlag.DAMAGE_EXPLOSION, EntityRef(player), 0)
			end
		end
	end

	local aim_direction = player:GetAimDirection()
	aim_direction = aim_direction * (player.ShotSpeed)
	if aim_direction:Length() == 0.0 then
		-- familiar.Velocity = Vector(0, 0)
	else
		familiar:AddVelocity(aim_direction)
	end

	save.divine_wrath_previous_pos = familiar.Position
end)

return divine_wrath