----------------------------------------------------------------------------
-- Item: Miniature Meteor
-- Originally from Pack 3
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local utils = include("ab_src.modules.utils")
local Item = include("ab_src.api.item")
local PickupConfig = include("ab_src.api.pickup")

local desc = {
    ["en_us"] = {"Miniature Meteor", "Chance to fire meteor tears#Meteor tears deal extra damage depending on the size of the meteor#Upon damaging an enemy with a meteor tear here is a 1 in 4 chance to create a Meteor Shard#Meteor Shards make meteor tears bigger#Every shard adds 0.5 Damage to meteor tears#{{Luck}} 50% chance to shoot a meteor tear at 13 Luck"},
    ["pt_br"] = {"Meteoro Miniatura", "Chance de atirar lágrimas meteoro#Lágrimas meteoro dão dano extra dependendo do tamanho do meteoro#Ao causar dano a um inimigo há uma chance em 1/4 de criar um fragmento de meteoro#Coletar fragmentos fazem as lágrimas meteoro maiores#Cada fragmento adiciona 0.5 de Dano por lágrima meteoro#{{Luck}} 50% de chance de atirar uma lágrima meteoro com 13 Sorte"},
}

local miniature_meteor = Item("Miniature Meteor", desc)
miniature_meteor.Shard = PickupConfig("Meteor Shard")

utils.mixTables(g.defaultPlayerSaveData, {
	miniature_meteor_bonus = 0
})

miniature_meteor:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(player, tear)
    local save = g.getPlayerSave(player)
    local data = tear:GetData()
    if utils.getLuckRNG(player, 10, 3) then
        data.is_meteor = true
        local tear_sprite = tear:GetSprite()
        tear_sprite:Load("gfx/animations/effects/animation_tears_miniaturemeteor.anm2", true)
        local sprite_index = math.floor((save.miniature_meteor_bonus / 6) + 1)
        if sprite_index > 6 then
            sprite_index = 6
        end
        tear_sprite:LoadGraphics()
        tear_sprite:Play("Stone"..sprite_index.."Move")
        if save.miniature_meteor_bonus then
            tear.CollisionDamage = tear.CollisionDamage + (save.miniature_meteor_bonus * 0.5)
        end
    end
end)

miniature_meteor:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (player, target, _, _, source)
    if source.Entity:GetData().is_meteor and utils.random(0, 4) == 1 then
        miniature_meteor.Shard:Spawn(target.Position, utils.VECTOR_ZERO, player)
    end
end)

miniature_meteor.Shard:AddCallback(PickupConfig.Callbacks.PICKUP_PICKUP, function(player, entity)
    local save = g.getPlayerSave(player)
    SFXManager():Play(SoundEffect.SOUND_SCAMPER, 1, 0, false, 1)
    save.miniature_meteor_bonus = save.miniature_meteor_bonus + 1
    return true
end)
