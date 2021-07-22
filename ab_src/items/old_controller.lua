----------------------------------------------------------------------------
-- Item: Old Controller
-- Originally from Pack 1
-- Upon death, respawns Isaac as a random starting character with random items.
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local old_controller = Item("Old Controller")

utils.mixTables(g.defaultPlayerSaveData, {
	run = {
		old_controller_respanwns = 0
	}
})

old_controller:AddCallback("ITEM_PICKUP", function(player)
	local save = g.getPlayerSave(player)
	save.run.old_controller_respanwns = save.run.old_controller_respanwns + 1
end)

old_controller:AddCallback(ModCallbacks.MC_POST_UPDATE, function(player)
	local save = g.getPlayerSave(player)
	if player:IsDead() then
		if save.run.old_controller_respanwns > 0 then
			save.run.old_controller_respanwns = save.run.old_controller_respanwns - 1
			player:Revive()
			g.level:ChangeRoom(g.level:GetPreviousRoomIndex())
			player:UseActiveItem(CollectibleType.COLLECTIBLE_CLICKER, false, true, true, false)
			player:UseActiveItem(CollectibleType.COLLECTIBLE_D4, false, true, true, false)
			player:AddSoulHearts(2)
		end
	end
end)

return old_controller