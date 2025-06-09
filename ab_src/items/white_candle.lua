----------------------------------------------------------------------------
-- Item: White Candle
-- Originally from Pack 1
-- Increase Angel Room/Soul heart chance. Chance to activate Holy Light on damage taken
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local white_candle = Item("White Candle") ---@type Item
white_candle.desc = include("ab_src.integrations.eid").white_candle

white_candle:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
    local level = g.level
    local room = g.room
    if room:IsFirstVisit() and level:GetCurrentRoomIndex() ~= level:GetStartingRoomIndex() then
        level:AddAngelRoomChance(0.1)
    end
end)

---@param player EntityPlayer
---@param damage_flags DamageFlag|integer
---@param damage_source EntityRef
white_candle:AddCallback("PLAYER_TAKE_DAMAGE", function(player, _, damage_flags, damage_source)
    if not g.HasProtection(player, damage_flags, damage_source) then
        local num_lasers = utils.random(2, 8)
        for _ = 1, num_lasers do
            local entities = Isaac:GetRoomEntities()
            local chance_to_hit = utils.random(1, 2)
            if chance_to_hit == 1 and #entities then
                local vulnerable_entities = {}
                for _, entity in ipairs(entities) do
                    if entity:IsVulnerableEnemy() then
                        vulnerable_entities[#vulnerable_entities + 1] = entity
                    end
                end

                if #vulnerable_entities then
                    local entity = nil
                    if #vulnerable_entities ~= 1 then
                        entity = vulnerable_entities[utils.random(1, #vulnerable_entities)]
                    else
                        entity = vulnerable_entities[1]
                    end

                    local position_to_hit = entity.Position
                    Isaac.Spawn(
                        EntityType.ENTITY_EFFECT,
                        EffectVariant.CRACK_THE_SKY,
                        0, -- Subtype
                        position_to_hit,
                        Vector.Zero, -- Velocity
                        player -- Spawner
                    )
                end
            else
                Isaac.Spawn(
                    EntityType.ENTITY_EFFECT,
                    EffectVariant.CRACK_THE_SKY,
                    0, -- Subtype
                    g.room:GetRandomPosition(0),
                    Vector.Zero, -- Velocity
                    player -- Spawner
                )
            end
        end
    end
end)

return white_candle
