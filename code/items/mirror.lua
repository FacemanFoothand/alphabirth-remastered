--
-- Item: Mirror
--

local utils = include("code/utils")
local random = utils.random

local item = {
    ENABLED = true,
    NAME = "Mirror", -- Metadata, can be useful for stuff in the mod
    TYPE = "Active"
}

function item.setup(Alphabirth)
    Alphabirth.ITEMS.ACTIVE.MIRROR = Alphabirth.API_MOD:registerItem(item.NAME)
    Alphabirth.ITEMS.ACTIVE.MIRROR:addCallback(AlphaAPI.Callbacks.ITEM_USE, item.triggerMirror)
end

function item.triggerMirror()
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local room = AlphaAPI.GAME_STATE.ROOM
    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
        return
    end

    -- Get room entities.
    local ents = AlphaAPI.entities.enemies

    -- Get number of entities, and generate a random number between 1 and the number of entities.
    local num_ents = #ents

    local rand_key = random(num_ents)

    -- Make sure the entity is an enemy, not a fire, and not a portal.
    -- Switch Isaac's position with the entity's position.
    -- Animate the teleportation.
    -- Further randomize the selection.
    if room:GetAliveEnemiesCount() > 0 then
        for rand_key, entity in pairs(ents) do
            if entity.Type ~= 306 and -- Portals
                    entity.Type ~= 304 and -- The Thing
                    entity.Type ~= EntityType.ENTITY_RAGE_CREEP and
                    entity.Type ~= EntityType.ENTITY_BLIND_CREEP and
                    entity.Type ~= EntityType.ENTITY_WALL_CREEP and
                    entity.Velocity:Length() > 0.1 then
                local player_pos = player.Position
                local entity_pos = entity.Position

                player.Position = entity_pos
                entity.Position = player_pos

                player:AnimateTeleport()

                rand_key = random(1, num_ents)
            end
        end
    else
        local teleport_pos = room:FindFreePickupSpawnPosition(room:GetDoorSlotPosition(random(DoorSlot.LEFT0, DoorSlot.DOWN0)), 1, true)
        player.Position = teleport_pos
        player:AnimateTeleport()
    end
end

return item