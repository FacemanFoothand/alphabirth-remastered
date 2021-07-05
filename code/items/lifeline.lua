----------------------------------------------------------------------------
-- Item: Lifeline
-- Originally from Pack 1
-- Has a chance to either fill all red hearts or remove a red heart container
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local lifeline = {
	ENABLED = true,
	NAME = "Lifeline",
	TYPE = "Active",
	AB_REF = nil,
	ITEM_REF = nil
}

function lifeline.setup(Alphabirth)
	lifeline.AB_REF = Alphabirth
	Alphabirth.ITEMS.ACTIVE.LIFELINE = Alphabirth.API_MOD:registerItem(lifeline.NAME)
	lifeline.ITEM_REF = Alphabirth.ITEMS.ACTIVE.LIFELINE
	lifeline.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, lifeline.trigger)
end

function lifeline.trigger()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	local health_roll = random(1, 5)
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
end

return lifeline