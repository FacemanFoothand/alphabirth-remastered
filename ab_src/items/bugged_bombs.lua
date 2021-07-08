----------------------------------------------------------------------------
-- Item: Bugged Bombs
-- Originally from Pack 1
-- Bombs become Bugged Bombs, which have tear flags randomly applied to them.
----------------------------------------------------------------------------

local BOMB_FLAGS = {
	"TEAR_BURN",
	"TEAR_SAD_BOMB",
	"TEAR_GLITTER_BOMB",
	"TEAR_BUTT_BOMB",
	"TEAR_STICKY",
	"TEAR_SPECTRAL",
	"TEAR_HOMING",
	"TEAR_POISON"
}

local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")
local bugged_bombs = Item("Bugged Bombs")

bugged_bombs:AddCallback("ITEM_PICKUP", function(player)
	player:AddBombs(5)
end)

bugged_bombs:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(player, bomb, bomb_variant)
	if bomb_variant ~= BombVariant.BOMB_SUPERTROLL and bomb_variant ~= BombVariant.BOMB_TROLL then
		local bomb_sprite = bomb:GetSprite()
		if bomb_sprite:GetFilename() ~= "gfx/animations/effects/animation_effect_buggedbombs.anm2" then
			bomb_sprite:Load("gfx/animations/effects/animation_effect_buggedbombs.anm2", true)
			bomb_sprite:Play("Idle")
		end
	end
end)

bugged_bombs:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(player, bomb, bomb_variant)
	if bomb_variant ~= BombVariant.BOMB_SUPERTROLL and bomb.Variant ~= BombVariant.BOMB_TROLL then
		if bomb.FrameCount % 15 == 0 then
			bomb.Flags = bomb.Flags | TearFlags[BOMB_FLAGS[utils.random(1, #BOMB_FLAGS)]]
		end
	end
end)

return bugged_bombs
