----------------------------------------------------------------------------
-- Item: Debug
-- Originally from Pack 1
-- Debug Item
----------------------------------------------------------------------------

local utils = include("code/utils")

local DEBUG = {
	ENABLED = true,
	NAME = "Debuggy",
	TYPE = "Active",
	AB_REF = nil,
	ITEM_REF = nil
}

function DEBUG.setup(Alphabirth)
	DEBUG.AB_REF = Alphabirth
	DEBUG.ITEM_REF = Alphabirth.API_MOD:registerItem(DEBUG.NAME)
	DEBUG.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_USE, DEBUG.trigger)
end

function DEBUG.trigger()
	AlphaAPI.log("HELLO?")
end

return DEBUG