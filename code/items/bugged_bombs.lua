----------------------------------------------------------------------------
-- Item: Bugged Bombs
-- Originally from Pack 1
-- Bombs become Bugged Bombs, which have tear flags randomly applied to them.
----------------------------------------------------------------------------

local utils = include("code/utils")
local random = utils.random

local BUGGED_BOMBS = {
	ENABLED = true,
	NAME = "Bugged Bombs",
	TYPE = "Passive",
	AB_REF = nil,
	ITEM_REF = nil,
	BOMB_FLAGS = {
        "TEAR_BURN",
        "TEAR_SAD_BOMB",
        "TEAR_GLITTER_BOMB",
        "TEAR_BUTT_BOMB",
        "TEAR_STICKY",
        "TEAR_SPECTRAL",
        "TEAR_HOMING",
        "TEAR_POISON"
    }
}

function BUGGED_BOMBS.setup(Alphabirth)
	Alphabirth.LOCKS.BUGGED_BOMBS = Alphabirth.API_MOD:createUnlock("alphaBuggedBombs")
	BUGGED_BOMBS.AB_REF = Alphabirth
	Alphabirth.ITEMS.PASSIVE.BUGGED_BOMBS = Alphabirth.API_MOD:registerItem(BUGGED_BOMBS.NAME)
	BUGGED_BOMBS.ITEM_REF = Alphabirth.ITEMS.PASSIVE.BUGGED_BOMBS
    BUGGED_BOMBS.ITEM_REF:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, BUGGED_BOMBS.pickup)
	BUGGED_BOMBS.ITEM_REF:addLock(Alphabirth.LOCKS.BUGGED_BOMBS)
	Alphabirth.API_MOD:addCallback(AlphaAPI.Callbacks.ENTITY_DEATH, BUGGED_BOMBS.killHush, EntityType.ENTITY_HUSH)
	Alphabirth.API_MOD:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, BUGGED_BOMBS.bombAppear, EntityType.ENTITY_BOMBDROP)
    Alphabirth.API_MOD:addCallback(AlphaAPI.Callbacks.ENTITY_UPDATE, BUGGED_BOMBS.bombUpdate, EntityType.ENTITY_BOMBDROP)
end

function BUGGED_BOMBS.pickup(player)
	player:AddBombs(5)
end

function BUGGED_BOMBS.bombAppear(entity, data)
	local plist = utils.hasCollectible(BUGGED_BOMBS.ITEM_REF.id)
	if plist then
		for _, player in ipairs(plist) do
			if GetPtrHash(entity.Parent) == GetPtrHash(player) and entity.Variant ~= BombVariant.BOMB_SUPERTROLL and entity.Variant ~= BombVariant.BOMB_TROLL then
				local bomb_sprite = entity:GetSprite()
				if bomb_sprite:GetFilename() ~= "gfx/animations/effects/animation_effect_buggedbombs.anm2" then
					bomb_sprite:Load("gfx/animations/effects/animation_effect_buggedbombs.anm2", true)
					bomb_sprite:Play("Idle")
				end
			end
		end
	end
end

function BUGGED_BOMBS.bombUpdate(entity, data)
	local plist = utils.hasCollectible(BUGGED_BOMBS.ITEM_REF.id)
	if plist then
		for _, player in ipairs(plist) do
			if GetPtrHash(entity.Parent) == GetPtrHash(player) and entity.Variant ~= BombVariant.BOMB_SUPERTROLL and entity.Variant ~= BombVariant.BOMB_TROLL then
				local bomb = entity:ToBomb()
				if entity.FrameCount % 15 == 0 then
					bomb.Flags = bomb.Flags | TearFlags[BUGGED_BOMBS.BOMB_FLAGS[random(1, #BUGGED_BOMBS.BOMB_FLAGS)]]
				end
			end
		end
	end
end

function BUGGED_BOMBS.killHush()
	local player_type = AlphaAPI.GAME_STATE.PLAYERS[1]:GetPlayerType()
	local character_null = BUGGED_BOMBS.AB_REF.PLAYER_TYPES.NULL
	if character_null and player_type == character_null and not BUGGED_BOMBS.AB_REF.LOCKS.BUGGED_BOMBS:isUnlocked() then
		AlphaAPI.playOverlay(AlphaAPI.OverlayType.UNLOCK, "gfx/ui/achievement/achievement_buggedbombs.png")
		BUGGED_BOMBS.AB_REF.LOCKS.BUGGED_BOMBS:setUnlocked(true)
	end
end

return BUGGED_BOMBS