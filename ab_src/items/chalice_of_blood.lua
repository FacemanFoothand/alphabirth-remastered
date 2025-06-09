----------------------------------------------------------------------------
-- Item: Chalice of Blood
-- Originally from Pack 2
-- Spawns a chalice on the ground, enemies killed near it fill the chalice
-- When full, the next use of the item will grant a costume and large stat boost instead of spawning the chalice
----------------------------------------------------------------------------
local EntityConfig = include("ab_src.api.entity")
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local chalice_of_blood = Item("Chalice of Blood", false, " Chalice of Blood ", "  Chalice of Blood  ", "   Chalice of Blood   ") ---@type Item
chalice_of_blood.desc = include("ab_src.integrations.eid").chalice_of_blood
chalice_of_blood.costume = Isaac.GetCostumeIdByPath("gfx/animations/costumes/accessories/animation_costume_chaliceofblood.anm2")
chalice_of_blood.Chalice = EntityConfig("Chalice of Blood") ---@type EntityConfig
chalice_of_blood.soul_limit = 15
chalice_of_blood.chalice_range = 140
chalice_of_blood.player_creep_timer = 15

utils.mixTables(g.defaultPlayerSaveData, {
    chalice_souls = 0,
    had_chalice_buff = false,
    level = {
        room = {
            chalice_buff = false
        }
    }
})

---@param player EntityPlayer
local function update_chalice_sprite(player, save)
    local id
    if save.chalice_souls <= 5 then
		id = 1
	elseif save.chalice_souls <= 10 then
        id = 2
	elseif save.chalice_souls < 15 then
        id = 3
	else
        id = 4
	end

    chalice_of_blood:SwitchItemID(player, id)
end

---@param player EntityPlayer
---@param flag CacheFlag
chalice_of_blood:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    local save = g.getPlayerSave(player)
    if save.level.room.chalice_buff then
        if flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * 2
        elseif flag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + 0.4
        end
    elseif save.had_chalice_buff then
        save.had_chalice_buff = nil
        player:TryRemoveNullCostume(chalice_of_blood.costume)
    end
end)

---@param player EntityPlayer
chalice_of_blood:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, player)
    local save = g.getPlayerSave(player)
    if save.chalice_souls < chalice_of_blood.soul_limit then
        local chalice = chalice_of_blood.Chalice:Spawn(player.Position, nil, player)
        chalice.Parent = player
    else
        save.chalice_souls = 0
        update_chalice_sprite(player, save)
        save.level.room.chalice_buff = true
        save.had_chalice_buff = true
        save.level.room.evaluateFlagsOnExit = save.level.room.evaluateFlagsOnExit | CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED
        ---@diagnostic disable-next-line: param-type-mismatch
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SHOTSPEED)
        player:EvaluateItems()
        player:AddNullCostume(chalice_of_blood.costume)
    end

    return true
end)

---@param chalice Entity
chalice_of_blood.Chalice:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(chalice)
    local data = chalice:GetData()
    data.CountedEnemies = data.CountedEnemies or {}
    local player = chalice.Parent:ToPlayer() or {} ---@type EntityPlayer
    local save = g.getPlayerSave(player)

    if g.game:GetFrameCount() % chalice_of_blood.player_creep_timer == 0 then
        local near_players = Isaac.FindInRadius(chalice.Position, chalice_of_blood.chalice_range, EntityPartition.PLAYER)
        for _, near_player in ipairs(near_players) do
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_RED, 0, near_player.Position, Vector.Zero, player)
        end
    end

    local near_enemies = Isaac.FindInRadius(chalice.Position, chalice_of_blood.chalice_range, EntityPartition.ENEMY)
    local got_soul
    for _, enemy in ipairs(near_enemies) do
        local hash = GetPtrHash(enemy)
        if not data.CountedEnemies[hash] and enemy:IsDead() and enemy:IsActiveEnemy(true) then
            data.CountedEnemies[hash] = true
            save.chalice_souls = save.chalice_souls + 1

            got_soul = true

            g.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 0.8)
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF02, 0, enemy.Position, Vector.Zero, nil)
        end
    end

    if got_soul then
        update_chalice_sprite(player, save)
    end

    if save.chalice_souls >= chalice_of_blood.soul_limit then
        g.sfx:Play(SoundEffect.SOUND_SUMMONSOUND, 0.5, 0, false, 0.9)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, chalice.Position, Vector.Zero, nil)
        chalice:Remove()
    end

    if g.room:IsClear() then
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, chalice.Position, Vector.Zero, nil)
        chalice:Remove()
    end
end)

return chalice_of_blood
