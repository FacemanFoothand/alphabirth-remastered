local utils = include("ab_src.modules.utils")
local EntityConfig = include("ab_src.api.entity")
local PickupConfig = utils.class(EntityConfig)

--- @enum PickupCallbacks
PickupConfig.Callbacks = {
    PICKUP_PICKUP = true,
}

--- @class PickupConfig
--- @field name string
--- @field subtype integer|nil
--- @field drop_sound integer|SoundEffect?
--- @field drop_callback function?
--- @field collect_sound integer|SoundEffect?
--- @field collision_class EntityCollisionClass?
--- @field radius2 integer
--- @field [string] any
function PickupConfig:Init(name, subtype)
    EntityConfig.Init(self, name, subtype)
    self.drop_sound = nil
    self.drop_callback = false
    self.collect_sound = nil
    self.collision_class = EntityCollisionClass.ENTCOLL_ALL
    self.radius2 = 24*24
end

---@param sound_id SoundEffect|integer
function PickupConfig:SetCollectSound(sound_id)
    self.collect_sound = sound_id
end

---@param r integer
function PickupConfig:SetRadius(r)
    self.radius2 = r*r
end

---@param coll_class EntityCollisionClass
function PickupConfig:SetCollisionClass(coll_class)
    self.collision_class = coll_class
end

---@param sound_id integer|SoundEffect
function PickupConfig:SetDropSound(sound_id)
    self.drop_sound = sound_id
    if not self.drop_callback then
        self.drop_callback = true
        EntityConfig.AddCallback(self, ModCallbacks.MC_POST_PICKUP_UPDATE, function(entity)
            if not entity:GetData()["ab_init_snd_pckp"] then
                local sprite = entity:GetSprite()
                if (not entity:IsDead()) and
                    sprite:IsPlaying("Appear") and
                    sprite:IsEventTriggered("DropSound") then
                    if self.drop_sound then
                        SFXManager():Play(self.drop_sound, 1, 0, false, 1)
                    end
                end
                entity:GetData()["ab_init_snd_pckp"] = true
            end
        end)
    end
end

function PickupConfig:AddCallback(enum, fn, a, b, c, d, e, f, g)
    if enum == PickupConfig.Callbacks.PICKUP_PICKUP then
        EntityConfig.AddCallback(self, ModCallbacks.MC_POST_PICKUP_UPDATE, function(entity)
            if not entity:GetData()["ab_init_pckp"] then
                entity.EntityCollisionClass = self.collision_class
                entity:GetData()["ab_init_pckp"] = true
            end

            local gl = require("ab_src.modules.globals")
            for _, player in ipairs(gl.players) do
                if (not entity:IsDead()) and
                    player:CanPickupItem() and
                    (not entity:GetSprite():IsPlaying("Appear")) and
                    (player.Position - entity.Position):LengthSquared() < self.radius2 then
                    local ret = fn(player, entity)
                    if ret then
                        if self.collect_sound then
                            SFXManager():Play(self.collect_sound, 1, 0, false, 1)
                        end
                        entity:GetSprite():Play("Collect", true)
                        entity:Die()
                    end
                end
            end
        end)
    else
        EntityConfig.AddCallback(self, enum, fn, a, b, c, d, e, f, g)
    end
end

return PickupConfig
