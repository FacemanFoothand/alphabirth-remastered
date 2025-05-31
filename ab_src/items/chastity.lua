----------------------------------------------------------------------------
-- Item: Chastity
-- Originally from Pack 1
-- Stats up if you haven't gone to the DEVIL room this run
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Chastity", "{{ArrowUp}} +1.5x Damage Multiplier#{{ArrowUp}} +0.4 Shot Speed#{{ArrowUp}} +0.2 Speed#{{ArrowUp}} +5 Range#{{DevilRoom}} All effects are lost if Isaac enters a devil room, even via a {{RedChest}} red chest"},
    ["pt_br"] = {"Castidade", "{{ArrowUp}} +1.5x Multiplicador de Dano#{{ArrowUp}} +0.4 Velocidade de Lágrima#{{ArrowUp}} +0.2 Velocidade#{{ArrowUp}} +5 Distância#{{DevilRoom}} Todos os efeitos são desfeitos se Isaac entrar em um quarto demoniaco, mesmo se for por um {{RedChest}} baú vermelho"},
}

local chastity = Item("Chastity", desc)

utils.mixTables(g.defaultSaveData, {
	run = {
		seenDevil = false
	}
})

g.mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function(player)
	local room = g.room

	if room:GetType() == RoomType.ROOM_DEVIL then
		g.saveData.run.seenDevil = true

		for _, player in ipairs(g.players) do
			if chastity:PlayerHas(player) then
				player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
				player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
				player:AddCacheFlags(CacheFlag.CACHE_RANGE)
				player:AddCacheFlags(CacheFlag.CACHE_SPEED)
				player:EvaluateItems()
			end
		end
	end
end)

chastity:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, cache_flag)
	if not g.saveData.run.seenDevil then
		if cache_flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = (player.Damage + 1.5) * 1.5
		elseif cache_flag == CacheFlag.CACHE_SHOTSPEED then
			player.ShotSpeed = player.ShotSpeed + 0.4
		elseif cache_flag == CacheFlag.CACHE_RANGE then
			player.TearHeight = player.TearHeight - 5
		elseif cache_flag == CacheFlag.CACHE_SPEED then
			player.MoveSpeed = player.MoveSpeed + 0.2
		end
	end
end)

return chastity
