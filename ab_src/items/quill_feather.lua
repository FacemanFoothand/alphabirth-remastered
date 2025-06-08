----------------------------------------------------------------------------
-- Item: Quill Feather
-- Originally from Pack 2
-- Piercing Tears that split when reaching a target
----------------------------------------------------------------------------
local utils = require("ab_src.modules.utils")
local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")

local quill_feather = Item("Quill Feather") ---@type Item
quill_feather.TearFlag = Flag("quill_feather_shot") ---@type Flag
quill_feather.IgnoreFlag = Flag("quill_feather_shot_child") ---@type Flag
quill_feather.number_of_tears = 8
quill_feather.angle = 30

local firing = false

---@param tear EntityTear
quill_feather:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(player, tear)
    if GetPtrHash(tear.Parent) ~= GetPtrHash(player) then
        return
    end

    if firing then
        firing = false
        return
    end

    tear.Color = Color(0, 0, 0, 1, 0, 0, 0)
    quill_feather.TearFlag:Apply(tear)
    tear:ChangeVariant(TearVariant.CUPID_BLUE)
    tear.TearFlags = tear.TearFlags | TearFlags.TEAR_PIERCING
end)

---@param source EntityRef
quill_feather:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, _, _, _, source)
    if quill_feather.TearFlag:EntityHas(source.Entity) and not quill_feather.IgnoreFlag:EntityHas(source.Entity) then
        local player = source.Entity.Parent:ToPlayer()
        if not player then return end
        for _ = 1, quill_feather.number_of_tears do
            local direction_vector = source.Entity.Velocity
            local random_angle =
                math.rad(utils.random(-math.floor(quill_feather.angle), math.floor(quill_feather.angle)))
            local cos_angle = math.cos(random_angle)
            local sin_angle = math.sin(random_angle)
            local shot_direction = Vector(
                cos_angle * direction_vector.X - sin_angle * direction_vector.Y,
                sin_angle * direction_vector.X + cos_angle * direction_vector.Y
            )

            local shot_vector = shot_direction * ((utils.random() * 0.4 + 0.8) * player.ShotSpeed)
            firing = true
            local new_tear = player:FireTear(source.Position, shot_vector, false, false, true)
            quill_feather.IgnoreFlag:Apply(new_tear)
            new_tear.Height = -20
            new_tear.TearFlags = new_tear.TearFlags | TearFlags.TEAR_PIERCING
            new_tear:ChangeVariant(TearVariant.CUPID_BLUE)
            new_tear.Color = Color(0, 0, 0, 1, 0, 0, 0)
        end
    end
end)

return quill_feather
