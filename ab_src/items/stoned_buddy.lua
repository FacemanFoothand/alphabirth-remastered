----------------------------------------------------------------------------
-- Item: Stoned Buddy
-- Originally from Pack 1
-- Spawns a familiar that persues the nearest enemy, pushing them away and blocking tears
----------------------------------------------------------------------------
local utils = require("ab_src.modules.utils")
local Item = include("ab_src.api.item")
local EntityConfig = include("ab_src.api.entity")
local Pathfinder = include("ab_src.api.pathfinder")

local stoned_buddy = Item("Stoned Buddy") ---@type Item
stoned_buddy.desc = include("ab_src.integrations.eid").stoned_buddy
stoned_buddy.Familiar = EntityConfig("Stoned Buddy") ---@type EntityConfig
stoned_buddy.Familiar.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ENEMIES
stoned_buddy.Familiar.GridCollisionClass = GridCollisionClass.COLLISION_WALL

local function find_target(familiar)
    local player = familiar.Player
    local min_distance = 999999
    local target = nil
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity.Type ~= 306 and entity:IsVulnerableEnemy() and entity:IsActiveEnemy(false) then
            local enemy = entity:ToNPC()
            if enemy and not enemy:IsBoss() then
                local dist = player.Position:Distance(enemy.Position)
                if dist < min_distance then
                    target = enemy
                    min_distance = dist
                end
            end
        end
    end
    return target
end

---@param familiar EntityFamiliar
stoned_buddy.Familiar:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(familiar)
    familiar:AddToFollowers()
end)

---@param familiar EntityFamiliar
stoned_buddy.Familiar:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(familiar)
    local data = familiar:GetData()
    local player = familiar.Player
    if player:GetCollectibleNum(stoned_buddy.ID) < 1 then
        familiar:Remove()
    end
    if not data.pathfinder then
        data.pathfinder = Pathfinder(familiar, 0.4, 25, 24)
    end
    if not data.stoned_target then
        familiar:FollowParent()
        data.stoned_target = find_target(familiar)
    else
        if data.stoned_target:IsDead() or not data.stoned_target.Position or not data.pathfinder then
            data.stoned_target = nil
            familiar:AddToFollowers()
            return true
        end

        data.pathfinder:aStarPathing(data.stoned_target.Position, function()
            familiar:FollowPosition(data.stoned_target.Position)
            data.stoned_target:AddFear(EntityRef(familiar), 1)
        end)
    end

    utils.animate_entity_cardinals(familiar, "WalkUp", "WalkDown", "WalkRight", "WalkLeft", "Idle", false, 0.2)
end)

stoned_buddy:AddSimpleFamiliar(stoned_buddy.Familiar.Variant, stoned_buddy.Familiar.SubType, nil, false)

return stoned_buddy
