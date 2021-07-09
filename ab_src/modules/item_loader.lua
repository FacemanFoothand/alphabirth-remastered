--
--  Item Loader Module
--

local itemLoader = {}
itemLoader.loadedItems = {}
local files = {
	"ab_src.items.addicted",
	"ab_src.items.black_pepper",
	"ab_src.items.beggars_cup",
	"ab_src.items.bugged_bombs",
	"ab_src.items.chalice_of_blood",
	"ab_src.items.charity",
	"ab_src.items.chastity",
	"ab_src.items.cologne",
	"ab_src.items.cool_bean",
	"ab_src.items.debug",
	"ab_src.items.deliriums_brain",
	"ab_src.items.furnace",
	"ab_src.items.green_candle",
	"ab_src.items.isaacs_apple",
	"ab_src.items.lifeline",
	"ab_src.items.satans_contract",
	"ab_src.items.tearleporter",
	"ab_src.items.temperance",
	"ab_src.items.trash_bag",
	"ab_src.items.white_candle",
	"ab_src.items.mirror",
	"ab_src.items.candle_kit",
	"ab_src.items.diligence",
	"ab_src.items.divine_wrath",
}

function itemLoader.loadAll(Alphabirth)
    for _, file in ipairs(files) do
		print("Loading item: "..file)
        local mod = include(file)
		itemLoader.loadedItems[#itemLoader.loadedItems + 1] = mod
    end
end

return itemLoader