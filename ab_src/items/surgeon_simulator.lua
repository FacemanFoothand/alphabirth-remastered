----------------------------------------------------------------------------
-- Item: Surgeon Simulator
-- Originally from Pack 2
-- Removes a red heart from Isaac's heart containers and puts it on the floor.
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")

local surgeon_simulator = Item("Surgeon Simulator") ---@type Item
surgeon_simulator.desc = include("ab_src.integrations.eid").surgeon_simulator

---@param player EntityPlayer
surgeon_simulator:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
        return
    end

    local spawn_pos = g.room:FindFreePickupSpawnPosition(player.Position, 1, true)
    if player:GetHearts() > 1 then
        player:AddHearts(-1)
        Isaac.Spawn(5, 10, 2, spawn_pos, Vector(0, 0), player)
        return true
    end
end)

return surgeon_simulator
