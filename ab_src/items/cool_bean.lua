----------------------------------------------------------------------------
-- Item: Cool Bean
-- Originally from Pack 1
-- Freezes nearby enemies
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")

local cool_bean = Item("Cool Bean") ---@type Item
cool_bean.desc = include("ab_src.integrations.eid").cool_bean
cool_bean.IceFart = EntityConfig("Ice Fart") ---@type EntityConfig
cool_bean.IceFart.freeze_range = 160
cool_bean.IceFart.freeze_duration = 150

---@param player EntityPlayer
cool_bean:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, player)
	for _, entity in ipairs(Isaac.GetRoomEntities()) do
		if entity:IsActiveEnemy() then
			local distance_to_enemy = player.Position:Distance(entity.Position)
			if distance_to_enemy < cool_bean.IceFart.freeze_range then
                entity:AddFreeze(EntityRef(player), cool_bean.IceFart.freeze_duration)
                entity:AddEntityFlags(EntityFlag.FLAG_ICE)
                entity:TakeDamage(30, 0, EntityRef(player), 0)
			end
		end
	end

	Isaac.Spawn(cool_bean.IceFart.ID,
				cool_bean.IceFart.Variant,
				0,
				player.Position,
				Vector.Zero,
				player)
	g.sfx:Play(SoundEffect.SOUND_FART,1.0,0,false,1.0)
end)

return cool_bean
