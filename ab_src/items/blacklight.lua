----------------------------------------------------------------------------
-- Item: Blacklight
-- Originally from Pack 2
-- Mass room damage but turns the screen darker each use
----------------------------------------------------------------------------
local g = require("ab_src.modules.globals")
local Item = include("ab_src.api.item")
local utils = include("ab_src.modules.utils")

local blacklight = Item("Blacklight") ---@type Item
blacklight.desc = include("ab_src.integrations.eid").blacklight
blacklight.max_uses = 20

utils.mixTables(g.defaultSaveData, {
    run = {
        blacklight_uses = 0,
        darken_cooldown = 0,
    },
})

---@param player EntityPlayer
blacklight:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_VOID) then
        return
    end

    local room = g.room ---@type Room
    if g.saveData.run.blacklight_uses < blacklight.max_uses and not room:IsClear() then
        g.saveData.run.blacklight_uses = g.saveData.run.blacklight_uses + 1
        g.saveData.run.darken_cooldown = 0
        for _, entity in ipairs(Isaac.GetRoomEntities()) do
            if entity:IsActiveEnemy(false) and entity:IsVulnerableEnemy() then
                entity:TakeDamage(40, 0, EntityRef(player), 30)
            end
        end

        return true
    end
end)

g.mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
    if g.saveData.run.blacklight_uses and g.saveData.run.darken_cooldown then
        if g.saveData.run.blacklight_uses > 0 and g.saveData.run.darken_cooldown == 0 then
            g.game:Darken(3 - (g.saveData.run.blacklight_uses / (blacklight.max_uses / 2)), 200)
            g.saveData.run.darken_cooldown = 195
        end
        if g.saveData.run.darken_cooldown > 0 then
            g.saveData.run.darken_cooldown = g.saveData.run.darken_cooldown - 1
        end
    end
end)

return blacklight
