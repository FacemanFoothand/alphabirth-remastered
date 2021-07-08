----------------------------------------------------------------------------
-- Item: Debug
-- Originally from Pack 1
-- Debug Item
----------------------------------------------------------------------------

local utils = include("code/utils")

local DEBUG = {
	ENABLED = true,
	NAME = "Debug",
	TYPE = "Active",
	AB_REF = nil,
	ITEM_REF = nil
}

function DEBUG.setup(Alphabirth)
	DEBUG.AB_REF = Alphabirth
	Alphabirth.ITEMS.ACTIVE.DEBUG = Alphabirth.API_MOD:registerItem(DEBUG.NAME)
	DEBUG.ITEM_REF = Alphabirth.ITEMS.ACTIVE.DEBUG
	DEBUG.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, DEBUG.trigger)
end

function DEBUG.trigger()
	local player = AlphaAPI.GAME_STATE.PLAYERS[1]
	DEBUG.AB_REF.ENTITIES.GLITCH_PICKUP:spawn(player.Position, player.Velocity, player)
end

return DEBUG