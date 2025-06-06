----------------------------------------------------------------------------
-- Item: Mutant Fetus
-- Originally from Pack 1
-- Has a chance to spawn a bomb when you hit an enemy
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local Flag = include("ab_src.api.flag")
local utils = include("ab_src.modules.utils")

local mutant_fetus = Item("Mutant Fetus") ---@type Item
mutant_fetus.desc = include("ab_src.integrations.eid").mutant_fetus
mutant_fetus.TearFlag = Flag("mutant_fetus_tear") ---@type Flag

---@param player EntityPlayer
---@param entity Entity
---@param damage_source EntityRef
mutant_fetus:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(player, entity, _, _, damage_source)
    if mutant_fetus.TearFlag:EntityHas(damage_source) and entity:IsActiveEnemy(false) then
        mutant_fetus.TearFlag:Clear(damage_source)
        local bomb_roll = utils.random(1, 200)
        if bomb_roll == 1 then
            Isaac.Spawn(
                ---@diagnostic disable-next-line: undefined-field
                EntityType.ENTITY_BOMBDROP,
                BombVariant.BOMB_SUPERTROLL,
                0,
                entity.Position,
                Vector.Zero,
                player
            )
        else
            player:FireBomb(entity.Position, Vector.Zero)
        end
    end
end)

---@param player EntityPlayer
---@param tear EntityTear
mutant_fetus:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, function(player, tear)
    if tear.Variant ~= TearVariant.CHAOS_CARD and utils.getLuckRNG(player, 7, 3) then
        mutant_fetus.TearFlag:Apply(tear)
        local tear_sprite = tear:GetSprite()
        tear_sprite:Load("gfx/animations/effects/animation_tears_mutantfetus.anm2", true)
        tear_sprite:Play("Idle")
        tear_sprite:LoadGraphics()
    end
end)

return mutant_fetus
