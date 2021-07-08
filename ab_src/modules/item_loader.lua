--
--  Item Loader Module
--

local itemLoader = {}
itemLoader.loadedItems = {}
local files = {
    "ab_src.items.based",
	"ab_src.items.addicted",
	"ab_src.items.black_pepper",
	"ab_src.items.beggars_cup",
	"ab_src.items.bugged_bombs",
	"ab_src.items.chalice_of_blood",
}

function itemLoader.loadAll(Alphabirth)
    for _, file in ipairs(files) do
		print("Loading item: "..file)
        local mod = include(file)
		itemLoader.loadedItems[#itemLoader.loadedItems + 1] = mod
    end
end

return itemLoader