----------------------------------------------------------------------------
-- Item: Entropy
-- Originally from Pack 3
----------------------------------------------------------------------------
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local entropy = Item("Entropy", false)

entropy:AddCallback(ModCallbacks.MC_POST_TEAR_INIT, function(entity)
    local data = entity:GetData()
    local player = entity:GetLastParent():ToPlayer()
    if not data.isEntropyTear and utils.getLuckRNG(player, 66, 5) then
        local angle = entity.Velocity:GetAngleDegrees()
        local length = entity.Velocity:Length()
        -- local oldTear = entity:ToTear()
        -- local flags = oldTear.TearFlags
        local variance = 10 
        -- local entropyTears = {oldTear}
        local tear = player:FireTear(player.Position, Vector.FromAngle(angle + utils.random(-variance,variance)):Resized(length), true, false, false)
        tear:GetData().isEntropyTear = true

        -- for _, flag in ipairs(splitFlags) do
        --     if flags & flag == flag then
        --         if AlphaAPI.getLuckRNG(66, 5) then
        --             local tear = player:FireTear(player.Position, Vector.FromAngle(angle + random(-variance,variance)):Resized(length), true, false, false)
        --             AlphaAPI.addFlag(tear, ENTITY_FLAGS.ENTROPY_TEAR)
        --             entropyTears[#entropyTears + 1] = tear
        --         end
        --     end
        -- end

        -- local tear = player:FireTear(player.Position, Vector.FromAngle(angle + random(-variance,variance)):Resized(length), true, false, false)
        -- entropyTears[#entropyTears + 1] = tear
        -- AlphaAPI.addFlag(tear, ENTITY_FLAGS.ENTROPY_TEAR)

        -- for _, tear in ipairs(entropyTears) do
        --     tear.TearFlags = tear.TearFlags & ~allSplitFlag
        -- end
    end
end)

entropy:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(player, flag)
    if flag == CacheFlag.CACHE_FIREDELAY then
        player.MaxFireDelay = player.MaxFireDelay - 3
    end
end)