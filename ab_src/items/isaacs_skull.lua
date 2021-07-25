----------------------------------------------------------------------------
-- Item: Isaac's Skull
-- Originally from Pack 3
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local isaacsSkull = Item("Isaac's Skull")

isaacsSkull:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
    local data = player:GetData()
    if not data.godheads then
        data.godheads = 0
    end

    if not data.brimstones then
        data.brimstones = 0
    end

    if rng:RandomInt(2) == 1 then
        player:AddCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE, 0, false)
        data.brimstones = data.brimstones + 1
    else
        player:AddCollectible(CollectibleType.COLLECTIBLE_GODHEAD, 0, false)
        data.godheads = data.godheads + 1
    end

    return true
end)

g.mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    local playersThatHaveIt = utils.hasCollectible(isaacsSkull.ID)
    for _, player in ipairs(playersThatHaveIt) do
        local data = player:GetData()
		if data.godheads or data.brimstones then
            for i = 1, data.godheads do
                player:RemoveCollectible(CollectibleType.COLLECTIBLE_GODHEAD)
            end
    
            for i = 1, data.brimstones do
                player:RemoveCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE)
            end
    
            data.godheads = 0
            data.brimstones = 0
        end
	end
end)