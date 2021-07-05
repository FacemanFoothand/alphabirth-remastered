----------------------------------------------------------------------------
-- Item: White Candle
-- Originally from Pack 1
-- Increase Angel Room/Soul heart chance. Chance to activate Holy Light on damage taken
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local white_candle = {
	ENABLED = true,
	NAME = "White Candle",
	TYPE = "Passive",
	COSTUME = "gfx/animations/costumes/accessories/animation_costume_whitecandle.anm2",
	AB_REF = nil,
	ITEM_REF = nil
}

function white_candle.setup(Alphabirth)
	white_candle.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.WHITE_CANDLE = Alphabirth.API_MOD:registerItem(white_candle.NAME, white_candle.COSTUME)
	white_candle.ITEM_REF = Alphabirth.ITEMS.PASSIVE.WHITE_CANDLE
	Alphabirth.MOD:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, white_candle.postNewRoom)
end

function white_candle.postNewRoom()
	local level = AlphaAPI.GAME_STATE.LEVEL
	local room = AlphaAPI.GAME_STATE.ROOM

	local plist = utils.hasCollectible(white_candle.ITEM_REF.id)
	if plist then
		if room:IsFirstVisit() and level:GetCurrentRoomIndex() ~= level:GetStartingRoomIndex() then
			level:AddAngelRoomChance(0.1)
		end
	end
end

return white_candle