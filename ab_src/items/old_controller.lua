----------------------------------------------------------------------------
-- Item: Old Controller
-- Originally from Pack 1
-- Upon death, respawns Isaac as a random starting character with random items.
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Old Controller", "{{ArrowUp}} +1 Life#Upon taking mortal damage revives Isaac as a {{Collectible"..CollectibleType.COLLECTIBLE_CLICKER.."}} random character with {{Collectible"..CollectibleType.COLLECTIBLE_D4.."}} random items"},
    ["pt_br"] = {"Controle Velho", "{{ArrowUp}} +1 Vida#Ao receber dano mortal revive Isaac como um {{Collectible"..CollectibleType.COLLECTIBLE_CLICKER.."}} personagem randomizado com {{Collectible"..CollectibleType.COLLECTIBLE_D4.."}} itens randomizados"},
}

local old_controller = Item("Old Controller", desc)

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
