local g = require("ab_src.modules.globals")

-- Forward declaration for easy lookup
g.game = Game()
g.sfx = SFXManager()
g.music = MusicManager()
g.item_config = Isaac.GetItemConfig()
g.level = nil
g.room = nil
g.players = nil
g.protection_funcs = {}

function g.RegisterProtectionFunction(func)
    g.protection_funcs[#g.protection_funcs+1] = func
end

function g.HasProtection(player, damage_flags, damage_source)
    for _, func in pairs(g.protection_funcs) do
        if func(player, damage_flags, damage_source) then
            return true
        end
    end
    return false
end

local function refresh_global_objects()
	g.room = g.game:GetRoom()
	g.level = g.game:GetLevel()

    local players = {}
	for i = 1, g.game:GetNumPlayers() do
		players[i] = Isaac.GetPlayer(i - 1)
	end

	g.players = players
end

if Isaac.GetPlayer() then
	refresh_global_objects()
end

g.mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function()
	refresh_global_objects()
end)

g.mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, function()
	refresh_global_objects()
end, EntityType.ENTITY_PLAYER)

g.mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    refresh_global_objects()
end)
