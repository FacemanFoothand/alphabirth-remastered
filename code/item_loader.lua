--
--  Item Loader Module
--

local itemLoader = {}
itemLoader.loadedItems = {}
local files = {
    "code.items.based",
}

function itemLoader.loadAll(Alphabirth)
    for _, file in ipairs(files) do
        local mod = include(file)
        if mod.ENABLED then
            mod.setup(Alphabirth)
            itemLoader.loadedItems[#itemLoader.loadedItems + 1] = mod
        end
    end
end

return itemLoader