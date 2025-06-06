----------------------------------------------------------------------------
-- Item: Bugged Bombs
-- Originally from Pack 1
-- Bombs become Bugged Bombs, which have tear flags randomly applied to them.
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local BombFlags = {
	"TEAR_BURN",
	"TEAR_SAD_BOMB",
	"TEAR_GLITTER_BOMB",
	"TEAR_BUTT_BOMB",
	"TEAR_STICKY",
	"TEAR_SPECTRAL",
	"TEAR_HOMING",
	"TEAR_POISON",
    "TEAR_SCATTER_BOMB",
    "TEAR_CROSS_BOMB",
    "TEAR_BLOOD_BOMB",
    "TEAR_BRIMSTONE_BOMB",
    "TEAR_GHOST_BOMB",
}

local desc = {
    ["en_us"] = {"Bugged Bombs", "#{{Bomb}} +5 Bombs#{{UltraSecretRoom}} Isaac's bombs explode with random bomb effects"},
    ["pt_br"] = {"Bombas Bugadas", "#{{Bomb}} +5 Bombas#{{UltraSecretRoom}} As bombas de Isaac explodem com efeitos randomizados"},
}

local bugged_bombs = Item("Bugged Bombs")
bugged_bombs.desc = desc

bugged_bombs:AddCallback("ITEM_PICKUP", function(player)
	player:AddBombs(5)
end)

bugged_bombs:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(_, bomb, bomb_variant)
	if bomb_variant ~= BombVariant.BOMB_SUPERTROLL and bomb_variant ~= BombVariant.BOMB_TROLL then
		local bomb_sprite = bomb:GetSprite()
		if bomb_sprite:GetFilename() ~= "gfx/animations/effects/animation_effect_buggedbombs.anm2" then
			bomb_sprite:Load("gfx/animations/effects/animation_effect_buggedbombs.anm2", true)
			bomb_sprite:Play("Idle")
		end
	end
end)

bugged_bombs:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb, bomb_variant)
	if bomb_variant ~= BombVariant.BOMB_SUPERTROLL and bomb.Variant ~= BombVariant.BOMB_TROLL then
		if bomb.FrameCount % 15 == 0 then
			bomb.Flags = bomb.Flags | TearFlags[BombFlags[utils.random(1, #BombFlags)]]
		end
	end
end)

return bugged_bombs
