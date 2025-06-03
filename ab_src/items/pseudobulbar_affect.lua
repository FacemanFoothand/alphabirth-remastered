----------------------------------------------------------------------------
-- Item: Pseudobulbar Affect
-- Originally from Pack 1
-- Tears shoot out in the direction Isaac moves.
----------------------------------------------------------------------------

local Item = include("ab_src.api.item")

local desc = {
    ["en_us"] = {"Pseudobulbar Affect", "Tears shoot out in Isaac's movement direction"},
    ["pt_br"] = {"Afeto Pseudobulbar", "Lágrimas serão atiradas na direção de movimento do Isaac"},
}

local pseudobulbar_affect = Item("Pseudobulbar Affect", desc)

pseudobulbar_affect:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(player, player_type)
	local direction = player:GetMovementVector():Normalized()
	local data = player:GetData()
	if not data.pseudoCharge then
		data.pseudoCharge = 0
	end

	if(direction:Length() ~= 0.0) then
		data.pseudoCharge = data.pseudoCharge + 1
		if (data.pseudoCharge % (player.MaxFireDelay) == 0) then
			data.pseudoCharge = 0
			local shot_velocity = player:GetTearMovementInheritance(direction) * (4 * player.ShotSpeed)
			player:FireTear(player.Position, shot_velocity, false, false, false)
		end
	else
		data.pseudoCharge = 0
	end
end)

return pseudobulbar_affect
