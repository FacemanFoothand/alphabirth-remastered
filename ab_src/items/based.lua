----------------------------------------------------------------------------
-- Item: Debuggy
-- Originally from Pack 1
-- Debug Item
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local debuggy = Item("Debuggy")

debuggy:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
    print(player)
end)

return debuggy