----------------------------------------------------------------------------
-- Item: Lifeline
-- Originally from Pack 1
-- Has a chance to either fill all red hearts or remove a red heart container
----------------------------------------------------------------------------

local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local lifeline = Item("Lifeline")

lifeline:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	local health_roll = utils.random(1, 5)
	local animate = false
	if health_roll == 1 then
		-- Only take effect if the player has two or more red heart containers
		if player:GetMaxHearts() >= 4 then
			player:AddMaxHearts(-2, false) -- Remove one full red heart container
			player:AnimateSad()
		end
	else
		player:SetFullHearts() -- Fill all red heart containers
		animate = true
	end
	return animate
end)

return lifeline
