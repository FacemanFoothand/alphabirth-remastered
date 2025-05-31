----------------------------------------------------------------------------
-- Item: Debug
-- Originally from Pack 1
-- Debug Item
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local Entity = include("ab_src.api.entity")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Debug", "Spawns a glitched pickup.#{{UltraSecretRoom}} Glitched pickups cycle between pickup types."},
    ["pt_br"] = {"Debug", "Cria um pickup bugado.#{{UltraSecretRoom}} Pickups bugados ciclam entre tipos diferentes."},
}

local debug = Item("Debug", desc)
local glitched_pickup = Entity("Glitched Pickups")

debug:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
	glitched_pickup:Spawn(player.Position, player.Velocity, player)
end)

return debug
