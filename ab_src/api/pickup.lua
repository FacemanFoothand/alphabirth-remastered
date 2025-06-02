local utils = include("ab_src.modules.utils")
local EntityConfig = include("ab_src.api.entity")
local PickupConfig = utils.class(EntityConfig)

PickupConfig.Callbacks = {
    PICKUP_PICKUP,
}

function PickupConfig:Init(name, subtype)
    EntityConfig.Init(self, name, subtype)
    self.dropSound = nil
    self.dropCallback = false
    self.collectSound = nil
    self.collisionClass = EntityCollisionClass.ENTCOLL_ALL
    self.radius2 = 24*24
end

function PickupConfig:SetDropSound(soundId)
    self.dropSound = soundId
    if not self.dropCallback then
        self.dropCallback = true
        EntityConfig.AddCallback(
            self,
            AlphaAPI.Callbacks.ENTITY_UPDATE,
            function(entity, data)
                local sprite = entity:GetSprite()
                if (not entity:IsDead()) and
                sprite:IsPlaying("Appear") and
                sprite:IsEventTriggered("DropSound") then
                    if self.dropSound then
                        SFXManager():Play(self.dropSound, 1, 0, false, 1)
                    end
                end
            end
        )
    end
end

function PickupConfig:SetCollectSound(soundId)
    self.collectSound = soundId
end

function PickupConfig:SetRadius(r)
    self.radius2 = r*r
end

function PickupConfig:SetCollisionClass(coll_class)
    self.collisionClass = coll_class
end

function PickupConfig:AddCallback(enum, fn, a, b, c, d, e, f, g)
    if enum == PickupConfig.Callbacks.PICKUP_PICKUP then
        EntityConfig.AddCallback(
            self,
            ModCallbacks.MC_POST_PICKUP_UPDATE,
            function(entity)
                local player = AlphaAPI.GAME_STATE.PLAYERS[1]
                if not entity:GetData()["ab_init"] then
                    entity.EntityCollisionClass = self.collisionClass
                    entity:GetData()["ab_init"] = true
                end
                if (not entity:IsDead()) and
                player:CanPickupItem() and
                (not entity:GetSprite():IsPlaying("Appear")) and
                (player.Position - entity.Position):LengthSquared() < self.radius2 then
                    local ret = fn(player, entity)
                    if ret then
                        if self.collectSound then
                            SFXManager():Play(self.collectSound, 1, 0, false, 1)
                        end
                        entity:GetSprite():Play("Collect", true)
                        entity:Die()
                    end
                end
            end
        )
    else
        EntityConfig.AddCallback(self, enum, fn, a, b, c, d, e, f, g)
    end
end

return PickupConfig
