----------------------------------------------------------------------------
-- Item: Humility
-- Originally from Pack 1
-- Marks a random enemy in the room that takes increased damage
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")
local utils = include("ab_src.modules.utils")

local humility = Item("Humility")
local double_damage_flag = Flag("humility_double_damage")
humility.interval = 10
humility.chance = 10

utils.mixTables(g.defaultPlayerSaveData, {
	humility_target = nil
})

humility:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
	local save = g.getPlayerSave(player)
	local valid_entities = nil
	local humility_active = false
	local should_find_target = true

	for _, entity in ipairs(Isaac:GetRoomEntities()) do
		if entity:IsActiveEnemy(false) then
			if double_damage_flag:EntityHas(entity) then
				should_find_target = false
				break
			end

			local enemy = entity:ToNPC()
			if enemy then
				if not enemy:IsBoss() then
					valid_entities = valid_entities or {}
					valid_entities[#valid_entities + 1] = entity
				end
			end
		end
	end

	if should_find_target == true and
		valid_entities ~= nil and
		#valid_entities > 0 and
		g.game:GetFrameCount() % humility.interval == 0 and
		utils.random( 1, math.max( 1, humility.chance - player.Luck ) ) <= 1
	then
		local target_entity_index = 1
		if #valid_entities > 1 then
			target_entity_index = utils.random(#valid_entities)
		end

		local target_entity = valid_entities[target_entity_index]
		save.humility_target = target_entity
		double_damage_flag:Apply(target_entity)
	end
end)

humility:AddCallback(ModCallbacks.MC_POST_RENDER, function(player, player_type)
	if not humility.sprite then
		humility.sprite = Sprite()
		humility.sprite:Load("gfx/animations/effects/animation_effect_humility.anm2", true)
		humility.sprite:LoadGraphics()
	end
	local save = g.getPlayerSave(player)
	if save.humility_target then
		if save.humility_target:IsDead() then
			save.humility_target = nil
			return
		end
		humility.sprite:Play("Humility")
		humility.sprite.Offset = save.humility_target:GetSprite().Offset - Vector(0, save.humility_target.Size * (save.humility_target.SizeMulti.Y * 3))
		humility.sprite:RenderLayer(0, g.room:WorldToScreenPosition(save.humility_target.Position))
	end
end)

humility:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(player, entity, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	if double_damage_flag:EntityHas(entity) then
		entity.HitPoints = entity.HitPoints - damage_amount
	end
end)

return humility