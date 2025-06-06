----------------------------------------------------------------------------
-- Item: Miniature Meteor
-- Originally from Pack 3
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local utils = include("ab_src.modules.utils")
local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")
local PickupConfig = include("ab_src.api.pickup")

local miniature_meteor = Item("Miniature Meteor") ---@type Item
miniature_meteor.desc = include("ab_src.integrations.eid").miniature_meteor
miniature_meteor.TearFlag = Flag("meteor_tear") ---@type Flag
miniature_meteor.Shard = PickupConfig("Meteor Shard") ---@type PickupConfig
miniature_meteor.Shard:SetCollectSound(SoundEffect.SOUND_SCAMPER)
miniature_meteor.Shard:SetDropSound(SoundEffect.SOUND_SCYTHE_BREAK)

utils.mixTables(g.defaultPlayerSaveData, {
    miniature_meteor_bonus = 0,
})

---@param player EntityPlayer
---@param tear EntityTear
miniature_meteor:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(player, tear)
    local save = g.getPlayerSave(player)
    if utils.getLuckRNG(player, 10, 3) then
        miniature_meteor.TearFlag:Apply(tear)
        local tear_sprite = tear:GetSprite()
        tear_sprite:Load("gfx/animations/effects/animation_tears_miniaturemeteor.anm2", true)
        local sprite_index = math.min(math.floor((save.miniature_meteor_bonus / 6) + 1), 6)
        tear_sprite:Play("Stone" .. sprite_index .. "Move")
        tear.CollisionDamage = tear.CollisionDamage + (save.miniature_meteor_bonus * 0.5)
    end
end)

---@param player EntityPlayer
---@param target Entity
---@param _ any
---@param source EntityRef
miniature_meteor:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(player, target, _, _, source)
    if miniature_meteor.TearFlag:EntityHas(source.Entity) and utils.random(0, 4) == 1 then
        miniature_meteor.Shard:Spawn(target.Position, Vector.Zero, player)
    end
end)

---@param player EntityPlayer
miniature_meteor.Shard:AddCallback(PickupConfig.Callbacks.PICKUP_PICKUP, function(player, _)
    local save = g.getPlayerSave(player)
    save.miniature_meteor_bonus = save.miniature_meteor_bonus + 1
    return true
end)

return miniature_meteor
