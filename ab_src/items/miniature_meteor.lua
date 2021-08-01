----------------------------------------------------------------------------
-- Item: Miniature Meteor
-- Originally from Pack 3
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local miniatureMeteor = Item("Miniature Meteor", false)

miniatureMeteor:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, function(entity)
    local data = entity:GetData()
    local player = entity:GetLastParent():ToPlayer()
    if utils.getLuckRNG(player, 10, 3) then
        data.isMeteor = true
        local tearSprite = entity:GetSprite()
        tearSprite:Load("../../content/gfx/animations/effects/animation_tears_miniaturemeteor.anm2", true)
        local spriteIndex = math.floor((player:GetData().miniatureMeteorBonus / 2) + 1)
        if spriteIndex > 6 then
            spriteIndex = 6
        end
        tearSprite:Play("Stone"..spriteIndex.."Move")
        tearSprite:LoadGraphics()
        if player:GetData().miniatureMeteorBonus then
            entity.CollisionDamage = entity.CollisionDamage + (player:GetData().miniatureMeteorBonus * 0.5)
        end
    end
end)


miniatureMeteor:AddCallback("ITEM_PICKUP", function(player)
	if not player:GetData().miniatureMeteorBonus then
        player:GetData().miniatureMeteorBonus = 0
    end
end)

-------------------
-- Miniature Meteor
-------------------

-- function Alphabirth.miniatureMeteorDamage(entity, amount, damage_flag, source, invincibility_frames)
--     if AlphaAPI.hasFlag(source.Entity, ENTITY_FLAGS.METEOR_SHOT) and random() < 0.4 then
--         Isaac.Spawn(ENTITIES.METEOR_SHARD.id, ENTITIES.METEOR_SHARD.variant, 0, entity.Position, Vector(0,0), AlphaAPI.GAME_STATE.PLAYERS[1])
--     end
-- end

-- function Alphabirth.meteorShardPickup()
--     SFX_MANAGER:Play(SoundEffect.SOUND_SCAMPER, 1, 0, false, 1)
--     api_mod.data.run.miniatureMeteorBonus = api_mod.data.run.miniatureMeteorBonus + 1
--     return true
-- end
    -- ITEMS.PASSIVE.MINIATURE_METEOR = api_mod:registerItem("Miniature Meteor", "gfx/animations/costumes/accessories/animation_costume_miniaturemeteor.anm2")
    -- ITEMS.PASSIVE.MINIATURE_METEOR:addCallback(AlphaAPI.Callbacks.ENTITY_DAMAGE, Alphabirth.miniatureMeteorDamage)
    -- ITEMS.PASSIVE.MINIATURE_METEOR:addCallback(AlphaAPI.Callbacks.ENTITY_APPEAR, Alphabirth.miniatureMeteorAppear, EntityType.ENTITY_TEAR)
    -- ITEMS.PASSIVE.MINIATURE_METEOR:addCallback(AlphaAPI.Callbacks.ITEM_PICKUP, Alphabirth.onMeteorPickup)