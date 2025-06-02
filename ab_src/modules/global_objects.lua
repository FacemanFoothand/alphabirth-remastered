local g = require("ab_src.modules.globals")

-- Forward declaration for easy lookup
g.game = Game()
g.sfx = SFXManager()
g.music = MusicManager()
g.itemConfig = Isaac.GetItemConfig()
g.level = nil
g.room = nil
g.players = nil

local function refreshGlobalObjects()
	g.room = g.game:GetRoom()
	g.level = g.game:GetLevel()

    local players = {}
	for i = 1, g.game:GetNumPlayers() do
		players[i] = Isaac.GetPlayer(i - 1)
	end

	g.players = players
end

if Isaac.GetPlayer() then
	refreshGlobalObjects()
end

g.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function()
	refreshGlobalObjects()
end)

g.mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function()
	refreshGlobalObjects()
end, EntityType.ENTITY_PLAYER)

g.mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    refreshGlobalObjects()
end)
