----------------------------------------------------------------------------
-- Item: Infested Baby
-- Originally from Pack 2
-- Familiar that spawns spiders (Rotten baby but Spiders)
----------------------------------------------------------------------------
local EntityConfig = include("ab_src.api.entity")
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")

local infested_baby = Item("Infested Baby", false) ---@type Item
infested_baby.Baby = EntityConfig("Infested Baby") ---@type EntityConfig
infested_baby.return_to_idle_cooldown = 8
infested_baby.shoot_animation_cooldown = 4

---@param familiar EntityFamiliar
local function spawn_spider(familiar)
    g.sfx:Play(SoundEffect.SOUND_WHEEZY_COUGH, 0.5, 0, false, 0.8)
    return Isaac.Spawn(
        EntityType.ENTITY_FAMILIAR,
        FamiliarVariant.BLUE_SPIDER,
        0,
        familiar.Position,
        Vector(0,0),
        nil
    )
end

---@param sprite Sprite
---@param fire_direction Direction
---@param up_animation string
---@param down_animation string
---@param side_animation string
local function animate_follower_cardinals(sprite, fire_direction, up_animation, down_animation, side_animation)
    if (fire_direction == Direction.UP and not sprite:IsPlaying(up_animation)) then
        sprite:Play(up_animation, true)
    elseif fire_direction == Direction.DOWN and not sprite:IsPlaying(down_animation) then
        sprite:Play(down_animation, true)
    elseif fire_direction == Direction.LEFT and (not sprite:IsPlaying(side_animation) or sprite.FlipX == false) then
        sprite:Play(side_animation, true)
        sprite.FlipX = true
    elseif fire_direction == Direction.RIGHT and (not sprite:IsPlaying(side_animation) or sprite.FlipX == true) then
        sprite:Play(side_animation, true)
        sprite.FlipX = false
    end
end

---@param familiar EntityFamiliar
infested_baby.Baby:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function(familiar)
    local data = familiar:GetData()
    local player = familiar:ToFamiliar().Player
    local sprite = familiar:GetSprite()
    familiar:FollowParent()

    if not data.has_shot then
        data.has_shot = false
    end

    local fire_direction = player:GetFireDirection()
    if not data.has_shot then
        if fire_direction ~= Direction.NO_DIRECTION then
            if not data.child then
                data.child = spawn_spider(familiar)
                data.has_shot = true
                return
            elseif data.child:IsDead() then
                data.child = spawn_spider(familiar)
                data.has_shot = true
                return
            end
            animate_follower_cardinals(sprite, fire_direction, "FloatUp", "FloatDown", "FloatSide")
        else
            if not sprite:IsPlaying("FloatDown") then
                if not data.return_to_idle_cooldown then
                    data.return_to_idle_cooldown = infested_baby.return_to_idle_cooldown
                else
                    if data.return_to_idle_cooldown < 1 then
                        data.return_to_idle_cooldown = infested_baby.return_to_idle_cooldown
                        sprite:Play("FloatDown", true)
                    else
                        data.return_to_idle_cooldown = data.return_to_idle_cooldown - 1
                    end
                end
            end
        end
    else
        animate_follower_cardinals(sprite, fire_direction, "FloatShootUp", "FloatShootDown", "FloatShootSide")
        if not data.shoot_animation_cooldown then
            data.shoot_animation_cooldown = infested_baby.shoot_animation_cooldown
        else
            if data.shoot_animation_cooldown < 1 then
                data.shoot_animation_cooldown = infested_baby.shoot_animation_cooldown
                data.has_shot = false
            else
                data.shoot_animation_cooldown = data.shoot_animation_cooldown - 1
            end
        end
    end
end)

---@param familiar EntityFamiliar
infested_baby.Baby:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, function(familiar)
    familiar:AddToFollowers()
end)

infested_baby:AddSimpleFamiliar(infested_baby.Baby.Variant, infested_baby.Baby.SubType, nil, false)

return infested_baby
