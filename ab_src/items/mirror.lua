----------------------------------------------------------------------------
-- Item: Mirror
-- Originally from Pack 2
-- Swaps Isaac's location with a random enemy in the room.
----------------------------------------------------------------------------

local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local desc = {
    ["en_us"] = {"Mirror", "Swaps Isaac's position with a random enemy in the room#If there are no enemies Isaac will teleport to a random free spot"},
    ["pt_br"] = {"Espelho", "Troca as posições de Isaac com um inimigo no quarto#Se não tiverem inimigos no quarto Isaac será teleportado à uma posição livre"},
}

local mirror = Item("Mirror", desc)

mirror:AddCallback(ModCallbacks.MC_USE_ITEM, function(id, rng, player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
        return
    end

    local room = g.room
    local ents = Isaac.GetRoomEntities()
    SFXManager():Play(SoundEffect.SOUND_HELL_PORTAL1, 1, 0, false, 1)
    player:AnimateTeleport()
    if room:GetAliveEnemiesCount() > 0 then
        local possible_ents = {}
        for _, entity in pairs(ents) do
            if entity.Type ~= 306 and -- Portals
            entity.Type ~= 304 and -- The Thing
            entity.Type ~= EntityType.ENTITY_RAGE_CREEP and
            entity.Type ~= EntityType.ENTITY_BLIND_CREEP and
            entity.Type ~= EntityType.ENTITY_WALL_CREEP and
            entity:IsVulnerableEnemy() and entity:IsActiveEnemy() and
            entity.Velocity:Length() > 0.1 then
                possible_ents[#possible_ents + 1] = entity
            end
        end

        local chosen = math.max(utils.random(#possible_ents), 1)
        local the_one = possible_ents[chosen]
        local player_pos = player.Position
        local entity_pos = the_one.Position
        player.Position = entity_pos
        the_one.Position = player_pos
    else
        local teleport_pos = room:FindFreePickupSpawnPosition(room:GetDoorSlotPosition(utils.random(DoorSlot.LEFT0, DoorSlot.DOWN0)), 1, true)
        player.Position = teleport_pos
    end
end)

return mirror
