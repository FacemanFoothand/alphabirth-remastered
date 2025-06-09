----------------------------------------------------------------------------
-- Item: Possessed Shot
-- Originally from Pack 2
-- Isaac has a chance to fire a tear that possesses enemies
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")
local utils = include("ab_src.modules.utils")
local g = require("ab_src.modules.globals")

local possessed_shot = Item("Possessed Shot") ---@type Item
possessed_shot.TearFlag = Flag("possessed_shot") ---@type Flag
possessed_shot.blacklist = {
    EntityType.ENTITY_MASK,
    EntityType.ENTITY_HEART,
}

local firing = false

---@param tear EntityTear
possessed_shot:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(player, tear)
    if GetPtrHash(tear.Parent) ~= GetPtrHash(player) then
        return
    end

    if firing then
        firing = false
        return
    end

    if utils.getLuckRNG(player, 6, 2) then
        tear.Color = Color(1, 1, 0.8, 0.7, 0, 0, 0)
        possessed_shot.TearFlag:Apply(tear)
    end
end)

---@param target Entity
---@param source EntityRef
possessed_shot:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, target, _, _, source)
    if
        possessed_shot.TearFlag:EntityHas(source.Entity)
        and target:IsVulnerableEnemy()
        and not g.room:IsClear()
        and not target:ToNPC():IsBoss()
        and not utils.tableContains(possessed_shot.blacklist, target.Type)
    then
        local entities_to_apply = utils.findAllRelatives(target)
        for _, entity in ipairs(entities_to_apply) do
            entity:AddEntityFlags(EntityFlag.FLAG_FRIENDLY)
            entity:AddEntityFlags(EntityFlag.FLAG_CHARM)
            entity:GetData()["prev_color"] = entity.Color
            entity.Color = Color(0.8, 1, 0.8, 0.4, 0, 0, 0)
            entity:GetData()["possessed"] = 300
            entity:GetData()["possessed_source"] = GetPtrHash(source.Entity.Parent:ToPlayer())
        end
    end
end)

---@param source Entity
local function find_target(source)
    local min_distance = 999999
    local target = nil
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity.Type ~= 306 and entity:IsVulnerableEnemy() and entity:IsActiveEnemy(false) then
            local enemy = entity:ToNPC()
            if enemy and GetPtrHash(source) ~= GetPtrHash(enemy) then
                local dist = source.Position:Distance(enemy.Position)
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
possessed_shot:AddCallback(ModCallbacks.MC_POST_UPDATE, function(player)
    for _, e in ipairs(Isaac.GetRoomEntities()) do
        local data = e:GetData()
        if data.possessed and data.possessed > 0 and data.possessed_source == GetPtrHash(player) then
            if e.FrameCount % (player.MaxFireDelay * 6) == 0 then
                local target = find_target(e)
                if target then
                    local d = (target.Position - e.Position):Normalized()
                    local length = player.ShotSpeed * 8.0 + e.Velocity:Length()
                    firing = true
                    player:FireTear(e.Position, d:Resized(length), false, true, false)
                end
            end

            if not g.room:IsClear() then
                data.possessed = data.possessed - 1
            end

            if data.possessed <= 0 then
                e:ClearEntityFlags(EntityFlag.FLAG_FRIENDLY)
                e:ClearEntityFlags(EntityFlag.FLAG_CHARM)
                if e:GetData().prev_color then
                    e.Color = e:GetData().prev_color
                end
            end
        end
    end
end)

return possessed_shot
