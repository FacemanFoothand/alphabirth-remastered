----------------------------------------------------------------------------
-- Item: Debuggy
-- Originally from Pack 1
-- Debug Item
----------------------------------------------------------------------------

local g = require("code.globals")
local Item = include("code.item")
local utils = include("code.utils")

local debuggy = Item("Debuggy")
debuggy.enabled = true

debuggy:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
    print(player)
end)

return debuggy