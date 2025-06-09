----------------------------------------------------------------------------
-- Item: Furnace
-- Originally from Pack 1
-- Shoots fires in all directions on damage taken
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local furnace = Item("Furnace") ---@type Item
furnace.desc = include("ab_src.integrations.eid").furnace

---@param player EntityPlayer
---@param damage_flags DamageFlag|integer
---@param damage_source EntityRef
furnace:AddCallback("PLAYER_TAKE_DAMAGE", function(player, _, damage_flags, damage_source)
    if not g.HasProtection(player, damage_flags, damage_source) then
        for _, direction in ipairs(utils.direction_list) do
            local fire = Isaac.Spawn(
                EntityType.ENTITY_EFFECT,
                EffectVariant.RED_CANDLE_FLAME,
                0,
                player.Position,
                direction:Normalized() * (10 * player.ShotSpeed),
                player
            )
			fire:ToEffect().CollisionDamage = 4 * player.Damage
        end
    end
end)

return furnace
