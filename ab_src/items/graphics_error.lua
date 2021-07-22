----------------------------------------------------------------------------
-- Item: Graphics Error
-- Originally from Pack 1
-- Enemies have a chance to spawn a GB Bug familiar upon death for the current room.
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local graphics_error = Item("Graphics Error")

graphics_error:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(player, entity, damage_amount, damage_flags, damage_source, invincibility_frames, entity_type)
	if entity:IsVulnerableEnemy() and GetPtrHash(player) == GetPtrHash(damage_source.Entity.Parent) then
		local npc = entity:ToNPC()
		if npc.HitPoints - damage_amount <= 0 then
			--player:GetEffects():AddCollectibleEffect(CollectibleType.COLLECTIBLE_GB_BUG, true)
		end
	end
end)

return graphics_error