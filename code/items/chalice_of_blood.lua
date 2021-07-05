----------------------------------------------------------------------------
-- Item: Chalice of Blood
-- Originally from Pack 2
-- Spawns a chalice on the ground, enemies killed near it fill the chalice
-- When full, the next use of the item will grant a costume and large stat boost instead of spawning the chalice
----------------------------------------------------------------------------

local g = require("code.globals")
local Item = include("code.item")
local EntityConfig = include("code.entity")
local utils = include("code.utils")

local chaliceOfBlood = Item("Chalice of Blood", false, " Chalice of Blood ", "  Chalice of Blood  ", "   Chalice of Blood   ")
chaliceOfBlood.NullCostume = Isaac.GetCostumeIdByPath("gfx/animations/costumes/accessories/animation_costume_chaliceofblood.anm2")
chaliceOfBlood.Chalice = EntityConfig("Chalice of Blood")
chaliceOfBlood.SoulLimit = 15
chaliceOfBlood.ChaliceRange = 140
chaliceOfBlood.PlayerCreepTimer = 15

local function updateChaliceSprite(player, save)
    local id
    if save.chaliceSouls <= 5 then
		id = 1
	elseif save.chaliceSouls <= 10 then
        id = 2
	elseif save.chaliceSouls < 15 then
        id = 3
	else
        id = 4
	end

    chaliceOfBlood:SwitchItemID(player, id)
end

chaliceOfBlood:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    local save = g.getPlayerSave(player)
    if save.level.room.chaliceBuff then
        if flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * 2
        elseif flag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + 0.4
        end
    elseif save.hadChaliceBuff then
        save.hadChaliceBuff = nil
        player:TryRemoveNullCostume(chaliceOfBlood.NullCostume)
    end
end)

chaliceOfBlood:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
    local data = player:GetData()
    local save = g.getPlayerSave(player)
    if save.chaliceSouls < chaliceOfBlood.SoulLimit then
        local chalice = chaliceOfBlood.Chalice:Spawn(player.Position, nil, player)
        chalice.Parent = player
    else
        save.chaliceSouls = 0
        updateChaliceSprite(player, save)
        save.level.room.chaliceBuff = true
        save.hadChaliceBuff = true
        save.level.room.evaluateFlagsOnExit = save.level.room.evaluateFlagsOnExit | CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED)
        player:EvaluateItems()
        player:AddNullCostume(chaliceOfBlood.NullCostume)
    end

    return true
end)

chaliceOfBlood.Chalice:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(chalice)
    local data = chalice:GetData()
    data.CountedEnemies = data.CountedEnemies or {}

    local player = chalice.Parent:ToPlayer()
    local save = g.getPlayerSave(player)

    if g.game:GetFrameCount() % chaliceOfBlood.PlayerCreepTimer == 0 then
        local nearPlayers = Isaac.FindInRadius(chalice.Position, chaliceOfBlood.ChaliceRange, EntityPartition.PLAYER)
        for _, nearPlayer in ipairs(nearPlayers) do
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, player.Position, Vector.Zero, player)
        end
    end

    local nearEnemies = Isaac.FindInRadius(chalice.Position, chaliceOfBlood.ChaliceRange, EntityPartition.ENEMY)
    local gotSoul
    for _, enemy in ipairs(nearEnemies) do
        local hash = GetPtrHash(enemy)
        if not data.CountedEnemies[hash] and enemy:IsDead() and enemy:IsActiveEnemy(true) then
            data.CountedEnemies[hash] = true
            save.chaliceSouls = save.chaliceSouls + 1

            gotSoul = true

            g.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 0.8)
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 0, entity.Position, Vector.Zero, nil)
        end
    end

    if gotSoul then
        updateChaliceSprite(player, save)
    end

    if save.chaliceSouls >= chaliceOfBlood.SoulLimit then
        g.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 0.9)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, chalice.Position, Vector.Zero, nil)
        chalice:Remove()
    end

    if g.room:IsClear() then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, chalice.Position, Vector.Zero, nil)
        chalice:Remove()
    end
end)

--[[
ITEMS.ACTIVE.CHALICE_OF_BLOOD = api_mod:registerItem("Chalice of Blood")
ITEMS.ACTIVE.CHALICE_OF_BLOOD:addCallback(AlphaAPI.Callbacks.ITEM_UPDATE, Alphabirth.handleChaliceOfBlood)
ITEMS.ACTIVE.CHALICE_OF_BLOOD:addCallback(AlphaAPI.Callbacks.ITEM_USE, Alphabirth.triggerChaliceOfBlood)
ITEMS.ACTIVE.CHALICE_OF_BLOOD:addCallback(AlphaAPI.Callbacks.ITEM_CACHE, Alphabirth.applyChaliceOfBloodCache)

---------------------------------------
-- Chalice of Blood Logic
---------------------------------------
local chalice
local soul_limit = 15
function Alphabirth.applyChaliceOfBloodCache(player, cache_flag)
    if cache_flag == CacheFlag.CACHE_DAMAGE then
        player.Damage = player.Damage * api_mod.data.run.CHALICE_STATS.DAMAGE
    elseif cache_flag == CacheFlag.CACHE_SHOTSPEED then
        player.ShotSpeed = player.ShotSpeed + api_mod.data.run.CHALICE_STATS.SHOTSPEED
    end
end

function Alphabirth.triggerChaliceOfBlood()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local room = AlphaAPI.GAME_STATE.ROOM

    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
        return
    end

    if api_mod.data.run.chaliceSouls < soul_limit then

        if chalice ~= nil then
        chalice:Remove()
        end

        chalice = ENTITIES.CHALICE_OF_BLOOD:spawn(
            player.Position,
            Vector(0,0),
            player
        )
    else
        api_mod.data.run.CHALICE_STATS.DAMAGE = 2
        api_mod.data.run.CHALICE_STATS.SHOTSPEED = 0.4
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
        player:AddNullCostume(COSTUMES.CHALICE_OF_BLOOD_COSTUME)
        player:EvaluateItems()
        playSound(SoundEffect.SOUND_VAMP_GULP, 1, 0, false, 1)
        api_mod.data.run.chaliceSouls = 0
    end
    return true
end

function Alphabirth.handleChaliceOfBlood()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local room = AlphaAPI.GAME_STATE.ROOM

    -- Remove Chalice if room is clear
    if room:GetFrameCount() == 1 then
        player:TryRemoveNullCostume(COSTUMES.CHALICE_OF_BLOOD_COSTUME)
        api_mod.data.run.CHALICE_STATS.DAMAGE = 1
        api_mod.data.run.CHALICE_STATS.SHOTSPEED = 0
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:AddCacheFlags(CacheFlag.CACHE_SHOTSPEED)
        player:EvaluateItems()
    end

    if room:IsClear() and chalice ~= nil then
        Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.POOF01,
            0,            -- Entity Subtype
            chalice.Position,
            Vector(0, 0), -- Velocity
            nil
        )
        chalice:Remove()
        chalice = nil
    end

    if chalice ~= nil then
        for _, entity in ipairs(AlphaAPI.entities.all) do
            if entity.Type == EntityType.ENTITY_PLAYER and entity.Position:Distance(chalice.Position) <= 140 and AlphaAPI.GAME_STATE.GAME:GetFrameCount() % 15 == 0 then
                Isaac.Spawn(EntityType.ENTITY_EFFECT,EffectVariant.PLAYER_CREEP_RED,0,player.Position,Vector(0, 0),player)
            end

            local entity_is_close = entity.Position:Distance(chalice.Position) <= 140
            if entity:IsDead() and entity:ToNPC() and entity_is_close and not entity:IsBoss() then
                playSound(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 0.8)
                Isaac.Spawn(
                    EntityType.ENTITY_EFFECT,
                    EffectVariant.POOF02,
                    0,            -- Entity Subtype
                    entity.Position,
                    Vector(0, 0), -- Velocity
                    nil
                )
                api_mod.data.run.chaliceSouls = api_mod.data.run.chaliceSouls + 1
            end
        end
    end

    if api_mod.data.run.chaliceSouls >= soul_limit and chalice ~= nil then
        playSound(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 0.9)
        Isaac.Spawn(
            EntityType.ENTITY_EFFECT,
            EffectVariant.POOF01,
            0,            -- Entity Subtype
            chalice.Position,
            Vector(0, 0), -- Velocity
            nil
        )
        chalice:Remove()
        chalice = nil
    end
end
]]
