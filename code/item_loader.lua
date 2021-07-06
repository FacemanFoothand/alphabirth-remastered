--
--  Item Loader Module
--

local itemLoader = {}
itemLoader.loadedItems = {}
local files = {
    "code.items.based",
	"code.items.addicted",
	"code.items.chalice_of_blood",
}

function itemLoader.loadAll(Alphabirth)
    for _, file in ipairs(files) do
        local mod = include(file)
        if mod.enabled then
            itemLoader.loadedItems[#itemLoader.loadedItems + 1] = mod
        end
    end
end

return itemLoader