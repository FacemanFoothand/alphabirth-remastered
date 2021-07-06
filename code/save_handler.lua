local g = require("code.globals")
local utils = require("code.utils")
local json = require("json")
local mod = g.mod

g.defaultSaveData = {
    run = {
        level = {
            room = {

            }
        },
        players = {}
    }
}

g.defaultPlayerSaveData = {
    level = {
        room = {
            evaluateFlagsOnExit = 0
        }
    }
}

g.saveData = {}

local saveDataLoaded = false

local function LoadSaveData()
    if not saveDataLoaded then
        if Isaac.HasModData(mod) then
            g.saveData = json.decode(Isaac.LoadModData(mod))
        else
            g.saveData = {}
        end

        g.saveData = utils.deepCopy(g.defaultSaveData, g.saveData)
    end
end

local function SaveSaveData()
    Isaac.SaveModData(g.mod, json.encode(g.saveData))
end

function g.getPlayerSave(player)
    local playerID = utils.getUniquePlayerIdentifier(player)
    if not g.saveData.run.players[playerID] then
        g.saveData.run.players[playerID] = utils.deepCopy(g.defaultPlayerSaveData, {})
    end

    return g.saveData.run.players[playerID]
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
    LoadSaveData()
    if not continued then
        g.saveData.run = utils.deepCopy(g.defaultSaveData.run)
    end
end)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, shouldSave)
	if shouldSave then
		SaveSaveData()
	end
end)

local saveOnUpdate
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
    saveOnUpdate = true
    if saveDataLoaded then
        g.saveData.run.level = utils.deepCopy(g.defaultSaveData.run.level)

        for _, player in ipairs(g.players) do
            local playerSave = g.getPlayerSave(player)
            playerSave.level = utils.deepCopy(g.defaultPlayerSaveData.level)
        end
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    if saveDataLoaded then
        g.saveData.run.level.room = utils.deepCopy(g.defaultSaveData.run.level.room)

        for _, player in ipairs(g.players) do
            local playerSave = g.getPlayerSave(player)
            if playerSave.level.room.evaluateFlagsOnExit ~= 0 then
                player:AddCacheFlags(playerSave.level.room.evaluateFlagsOnExit)
                player:EvaluateItems()
            end

            playerSave.level.room = utils.deepCopy(g.defaultPlayerSaveData.level.room)
        end
    end
end)

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if saveOnUpdate then
        saveOnUpdate = nil
        SaveSaveData()
    end
end)
