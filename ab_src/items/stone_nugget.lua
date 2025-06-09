----------------------------------------------------------------------------
-- Item: Stone Nugget
-- Originally from Pack 2
-- Spawns a Stone Pooter that inchest towards enemies, dealing 3 contact damage
-- If the pooter gets a kill the item gets a recharge
-- Can be overcharged without The Battery
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")
local utils = include("ab_src.modules.utils")
local g = require("ab_src.modules.globals")

local stone_nugget = Item("Stone Nugget") ---@type Item
stone_nugget.Pooter = EntityConfig("Stone Nugget") ---@type EntityConfig

---@param pooter Entity
local function find_target(pooter)
    local min_distance = 999999
    local target = nil
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity.Type ~= 306 and entity:IsVulnerableEnemy() and entity:IsActiveEnemy(false) then
            local enemy = entity:ToNPC()
            if enemy then
                local dist = pooter.Position:Distance(enemy.Position)
                if dist < min_distance then
                    target = enemy
                    min_distance = dist
                end
            end
        end
    end
    return target
end

---@param player EntityPlayer
stone_nugget:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, player)
    local pooter = stone_nugget.Pooter:Spawn(player.Position, Vector(0, 0), player)
    pooter:GetData().room_idx = g.level:GetCurrentRoomIndex()
    return true
end)

---@param pooter Entity
stone_nugget.Pooter:AddCallback("ENTITY_UPDATE", function(pooter)
    local current_room_idx = g.level:GetCurrentRoomIndex()

    if pooter:GetData().room_idx ~= current_room_idx then
        pooter:Remove()
    end

    if utils.random(1, 100) == 1 then
        pooter.FlipX = not pooter.FlipX
    end

    local e_frame = pooter.FrameCount
    if e_frame % 2 == 0 then
        e_frame = 1.0 - math.cos(e_frame * math.pi * 0.5)
        local nearest_enemy = find_target(pooter)
        if nearest_enemy then
            local direction = (nearest_enemy.Position - pooter.Position):GetAngleDegrees()
            local move_direction = Vector.FromAngle(utils.random(direction - 35, direction + 35))
            pooter.Velocity = utils.lerp(pooter.Velocity, move_direction * (utils.random(50, 150) * 0.01), e_frame)
        end
    end
end)

---@param source EntityRef
---@param dmg integer
stone_nugget:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, target, dmg, _, source)
    if not source or not stone_nugget.Pooter:Matches(source.Entity) then
        return
    end

    if target.HitPoints - dmg <= 0 then
        local player = source.Entity.SpawnerEntity:ToPlayer()
        if not player then
            return
        end

        local slot = nil
        if player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) == stone_nugget.ID then
            slot = ActiveSlot.SLOT_PRIMARY
        elseif player:GetActiveItem(ActiveSlot.SLOT_SECONDARY) == stone_nugget.ID then
            slot = ActiveSlot.SLOT_SECONDARY
        end

        local charge = player:GetActiveCharge(slot)
        if charge < 2 then
            player:SetActiveCharge(charge + 1)
        end
    end
end)

return stone_nugget
