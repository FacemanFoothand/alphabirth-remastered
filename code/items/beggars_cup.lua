----------------------------------------------------------------------------
-- Item: Beggar's Cup
-- Originally from Pack 1
-- Gives the player more luck the fewer consumables they have
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local BEGGARS_CUP = {
	ENABLED = true,
	NAME = "Beggar's Cup",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_beggarscup.anm2",
	AB_REF = nil,
	ITEM_REF = nil,
	LUCK_MODIFIER = 0,
	PREVIOUS_TOTAL = nil
}

function BEGGARS_CUP.setup(Alphabirth)
	BEGGARS_CUP.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.BEGGARS_CUP = Alphabirth.API_MOD:registerItem(BEGGARS_CUP.NAME, BEGGARS_CUP.COSTUME)
	BEGGARS_CUP.ITEM_REF = Alphabirth.ITEMS.PASSIVE.BEGGARS_CUP
	BEGGARS_CUP.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, BEGGARS_CUP.handle)
	BEGGARS_CUP.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, BEGGARS_CUP.evaluate)
end

function BEGGARS_CUP.handle(player)
	local coins = player:GetNumCoins()
	local total = coins / 10

	-- Only run if total has changed
	if total ~= BEGGARS_CUP.PREVIOUS_TOTA then

		BEGGARS_CUP.PREVIOUS_TOTAL = total
		local luck_threshold = 5
		local luck_minimum = 0

		BEGGARS_CUP.LUCK_MODIFIER = luck_threshold - total

		if BEGGARS_CUP.LUCK_MODIFIER < luck_minimum then
			BEGGARS_CUP.LUCK_MODIFIER = luck_minimum
		end

		player:AddCacheFlags(CacheFlag.CACHE_LUCK)
		player:EvaluateItems()
	end
end

function BEGGARS_CUP.evaluate(player, cache_flag)
	if(cache_flag == CacheFlag.CACHE_LUCK) then
		player.Luck = player.Luck + BEGGARS_CUP.LUCK_MODIFIER
	end
end

return BEGGARS_CUP