----------------------------------------------------------------------------
-- Item: Debug
-- Originally from Pack 1
-- Debug Item
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local Entity = include("ab_src.api.entity")
local utils = include("ab_src.modules.utils")

local debug = Item("Debug")
local glitched_pickup = Entity("Glitched Pickups")

debug:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	glitched_pickup:Spawn(player.Position, player.Velocity, player)
end)

return debug