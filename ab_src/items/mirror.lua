----------------------------------------------------------------------------
-- Item: Mirror
-- Originally from Pack 2
-- Swaps Isaac's location with a random enemy in the room.
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local mirror = Item("Mirror") ---@type Item
mirror.desc = include("ab_src.integrations.eid").mirror

---@param player EntityPlayer
mirror:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
        return
    end

    local room = g.room
    local ents = Isaac.GetRoomEntities()
    g.sfx:Play(SoundEffect.SOUND_HELL_PORTAL1, 1, 0, false, 1)
    player:AnimateTeleport()
    if room:GetAliveEnemiesCount() > 0 then
        local possible_ents = {}
        for _, entity in pairs(ents) do
            if
                entity.Type ~= 306 -- Portals
                and entity.Type ~= 304 -- The Thing
                and entity.Type ~= EntityType.ENTITY_RAGE_CREEP
                and entity.Type ~= EntityType.ENTITY_BLIND_CREEP
                and entity.Type ~= EntityType.ENTITY_WALL_CREEP
                and entity:IsVulnerableEnemy()
                and entity:IsActiveEnemy()
                and entity.Velocity:Length() > 0.1
            then
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
        local teleport_pos = room:FindFreePickupSpawnPosition(
            room:GetDoorSlotPosition(utils.random(DoorSlot.LEFT0, DoorSlot.DOWN0)),
            1,
            true
        )
        player.Position = teleport_pos
    end
end)

return mirror
