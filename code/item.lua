local g = require("code.globals")
local utils = include("code.utils")
local mod = g.mod

utils.mixTables(g.defaultPlayerSaveData, {
    trinkets = {},
    collectibles = {}
})


local Item = utils.class("Item")
function Item:Init(name, isTrinket, ...)
    self.Name = name
    self.IsTrinket = isTrinket

    if not self.IsTrinket then
        self.ID = Isaac.GetItemIdByName(name)
        self.Config = g.itemConfig:GetCollectible(self.ID)
    else
        self.ID = Isaac.GetTrinketIdByName(name)
        self.Config = g.itemConfig:GetTrinket(self.ID)
    end

    local extraNames = {...}
    if #extraNames > 0 then
        self.IDList = {self.ID}
        for _, extraName in ipairs(extraNames) do
            if not self.IsTrinket then
                self.IDList[#self.IDList + 1] = Isaac.GetItemIdByName(extraName)
            else
                self.IDList[#self.IDList + 1] = Isaac.GetTrinketIdByName(extraName)
            end
        end
    end

    self.StringID = tostring(self.ID)
end

local function countItem(player, id, isTrinket, ignoreModifiers)
    if not isTrinket then
        return player:GetCollectibleNum(id, ignoreModifiers)
    else
        return player:GetTrinketMultiplier(id)
    end
end

function Item:PlayerCount(player, ignoreModifiers)
    local count = 0
    if self.IDList then
        for _, id in ipairs(self.IDList) do
            count = count + countItem(player, id, self.IsTrinket, ignoreModifiers)
        end

        return count
    else
        return countItem(player, self.ID, self.IsTrinket, ignoreModifiers)
    end
end

function Item:PlayerHas(player, ignoreModifiers)
    return self:PlayerCount(player, ignoreModifiers) > 0
end

function Item:AnyPlayerHas(ignoreModifiers)
    for _, player in ipairs(g.players) do
        if self:PlayerHas(player, ignoreModifiers) then
            return true
        end
    end
end

function Item:PlayersHolding(ignoreModifiers)
    local players = {}
    for _, player in ipairs(g.players) do
        if self:PlayerHas(player, ignoreModifiers) then
            players[#players + 1] = player
        end
    end

    return players
end

-- Callbacks which directly accept a particular item
Item.DirectCallbacks = {
    [ModCallbacks.MC_USE_ITEM] = true,
    [ModCallbacks.MC_PRE_USE_ITEM] = true
}

-- Callbacks which directly pass a particular player
Item.DirectPlayerCallbacks = {
    [ModCallbacks.MC_POST_PEFFECT_UPDATE] = true,
    [ModCallbacks.MC_PRE_PLAYER_COLLISION] = true,
    [ModCallbacks.MC_POST_PLAYER_RENDER] = true,
    [ModCallbacks.MC_EVALUATE_CACHE] = true,
    [ModCallbacks.MC_POST_PLAYER_INIT] = true
}

Item.SecondArgPlayerCallbacks = {
    [ModCallbacks.MC_USE_PILL] = true,
    [ModCallbacks.MC_USE_CARD] = true
}

Item.CustomCallbacks = {
    ITEM_PICKUP = true,
    ITEM_REMOVE = true,
    PLAYER_TAKE_DAMAGE = true
}

function Item:AddCallback(id, func, param)
    if Item.CustomCallbacks[id] then
        if id == "ITEM_PICKUP" or id == "ITEM_REMOVE" then
            mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
                local save = g.getPlayerSave(player)
                local count = self:PlayerCount(player, true)
                local checkTbl = (self.IsTrinket and save.trinkets) or save.collectibles

                if checkTbl[self.StringID] ~= count then
                    if checkTbl[self.StringID] then
                        if id == "ITEM_PICKUP" and count > checkTbl[self.StringID] then
                            func(player)
                        elseif id == "ITEM_REMOVE" and count < checkTbl[self.StringID] then
                            func(player)
                        end
                    end

                    checkTbl[self.StringID] = count
                end
            end, param)
        elseif id == "PLAYER_TAKE_DAMAGE" then
            mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, player, ...)
                player = player:ToPlayer()
                if self:PlayerHas(player) then
                    return func(...)
                end
            end, EntityType.ENTITY_PLAYER)
        end
    else
        if Item.DirectCallbacks[id] then
            param = self.IDList or self.ID
        end

        local params = param
        if type(param) ~= "table" then
            if param == nil then
                params = {false}
            else
                params = {param}
            end
        end

        for _, param in ipairs(params) do
            if param == false then
                param = nil
            end

            mod:AddCallback(id, function(_, ...)
                if Item.DirectCallbacks[id] then
                    return func(...)
                elseif Item.DirectPlayerCallbacks[id] or Item.SecondArgPlayerCallbacks[id] then
                    local args = {...}
                    local player
                    if Item.SecondArgPlayerCallbacks[id] then
                        player = args[2] and args[2]:ToPlayer()
                    else
                        player = args[1] and args[1]:ToPlayer()
                    end

                    if player then
                        if self:PlayerHas(player) then
                            return func(...)
                        end
                    end
                else
                    for _, player in ipairs(g.players) do
                        if self:PlayerHas(player) then
                            func(player, ...)
                        end
                    end
                end
            end, param)
        end
    end
end

function Item:AddSimpleFamiliar(familiarVariant, familiarSubType, capCount, ignoreBoxOfFriends)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if flag == CacheFlag.CACHE_FAMILIARS then
            local count = self:PlayerCount(player)
            if not ignoreBoxOfFriends then
                count = count * (player:GetEffects():GetCollectibleEffectNum(CollectibleType.COLLECTIBLE_BOX_OF_FRIENDS) + 1)
            end

            if capCount then
                count = math.min(count, capCount)
            end

            player:CheckFamiliar(familiarVariant, count, player:GetCollectibleRNG(self.ID), self.Config, familiarSubType)
        end
    end)
end

function Item:SwitchItemID(player, idIndex)
    local targetID = self.IDList[idIndex]
    for _, id in ipairs(self.IDList) do
        if id ~= targetID then
            while player:HasCollectible(id, true) do
                local activeSwitched = false
                for activeSlot = 0, 2 do
                    local active = player:GetActiveItem(activeSlot)
                    if active == id then
                        local charge = player:GetActiveCharge(activeSlot)
                        player:RemoveCollectible(id, true, activeSlot, false)
                        player:AddCollectible(targetID, charge, false, activeSlot)
                        activeSwitched = true
                    end
                end

                if not activeSwitched then
                    player:RemoveCollectible(id, true, nil, false)
                    player:AddCollectible(targetID, 0, false)
                end
            end
        end
    end
end

return Item
