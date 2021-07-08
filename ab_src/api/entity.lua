local g = require("ab_src.modules.globals")
local utils = include("ab_src.modules.utils")
local mod = g.mod

local EntityConfig = utils.class("EntityConfig")
function EntityConfig:Init(name, subtype)
    self.Name = name

    self.ID = Isaac.GetEntityTypeByName(name)
    self.Variant = Isaac.GetEntityVariantByName(name)
    self.SubType = subtype

    self.StringID = tostring(self.ID)
end

function EntityConfig:Spawn(position, velocity, spawnerEntity)
    return Isaac.Spawn(
        self.ID,
        self.Variant or 0,
        self.SubType or 0,
        position,
        velocity or Vector.Zero,
        spawnerEntity
    )
end

function EntityConfig:Matches(entity)
    return self.ID == entity.Type
            and (not self.Variant or self.Variant == entity.Variant)
            and (not self.SubType or self.SubType == entity.SubType)
end

EntityConfig.TypeParamCallbacks = {
    [ModCallbacks.MC_NPC_UPDATE] = true,
    [ModCallbacks.MC_PRE_NPC_UPDATE] = true,
    [ModCallbacks.MC_POST_NPC_RENDER] = true,
    [ModCallbacks.MC_PRE_NPC_COLLISION] = true,
    [ModCallbacks.MC_POST_NPC_DEATH] = true,
    [ModCallbacks.MC_POST_ENTITY_KILL] = true,
    [ModCallbacks.MC_POST_ENTITY_REMOVE] = true,
    [ModCallbacks.MC_ENTITY_TAKE_DMG] = true,
}

EntityConfig.VariantParamCallbacks = {
    [ModCallbacks.MC_POST_EFFECT_UPDATE] = true,
    [ModCallbacks.MC_POST_EFFECT_INIT] = true,
    [ModCallbacks.MC_POST_EFFECT_RENDER] = true,

    [ModCallbacks.MC_FAMILIAR_UPDATE] = true,
    [ModCallbacks.MC_FAMILIAR_INIT] = true,
    [ModCallbacks.MC_POST_FAMILIAR_RENDER] = true,
    [ModCallbacks.MC_PRE_FAMILIAR_COLLISION] = true,

    [ModCallbacks.MC_POST_PICKUP_UPDATE] = true,
    [ModCallbacks.MC_POST_PICKUP_INIT] = true,
    [ModCallbacks.MC_POST_PICKUP_RENDER] = true,
    [ModCallbacks.MC_PRE_PICKUP_COLLISION] = true,

    [ModCallbacks.MC_POST_BOMB_UPDATE] = true,
    [ModCallbacks.MC_POST_BOMB_INIT] = true,
    [ModCallbacks.MC_POST_BOMB_RENDER] = true,
    [ModCallbacks.MC_PRE_BOMB_COLLISION] = true,

    [ModCallbacks.MC_POST_TEAR_UPDATE] = true,
    [ModCallbacks.MC_POST_TEAR_INIT] = true,
    [ModCallbacks.MC_POST_TEAR_RENDER] = true,
    [ModCallbacks.MC_PRE_TEAR_COLLISION] = true,

    [ModCallbacks.MC_POST_PROJECTILE_UPDATE] = true,
    [ModCallbacks.MC_POST_PROJECTILE_INIT] = true,
    [ModCallbacks.MC_POST_PROJECTILE_RENDER] = true,
    [ModCallbacks.MC_PRE_PROJECTILE_COLLISION] = true,

    [ModCallbacks.MC_POST_LASER_UPDATE] = true,
    [ModCallbacks.MC_POST_LASER_INIT] = true,
    [ModCallbacks.MC_POST_LASER_RENDER] = true,
}

function EntityConfig:AddCallback(id, func, param)
    if EntityConfig.TypeParamCallbacks[id] then
        param = self.ID
    elseif EntityConfig.VariantParamCallbacks[id] then
        param = self.Variant
    end

    mod:AddCallback(id, function(_, entity, ...)
        if self:Matches(entity) then
            return func(entity, ...)
        end
    end, param)
end

return EntityConfig
