local utils = {}

-- Make sure to load this After Alpha API

-- Setup
utils.VECTOR_ZERO = Vector(0,0)
utils.RNG = RNG()
utils.RNG:SetSeed(Random(), 1)

utils.direction_list = {
	Vector(-1, 0),  -- West
	Vector(0, 1),   -- North
	Vector(1, 0),   -- East
	Vector(0, -1),  -- South
	Vector(1, 1),   -- North East
	Vector(1, -1),  -- South East
	Vector(-1, 1),  -- North West
	Vector(-1, -1)  -- South West
}

-- Funcs
function utils.random(min, max) -- Re-implements math.random()
    if min ~= nil and max ~= nil then -- Min and max passed, integer [min,max]
        return math.floor(utils.RNG:RandomFloat() * (max - min + 1) + min)
    elseif min ~= nil then -- Only min passed, integer [0,min]
        return math.floor(utils.RNG:RandomFloat() * (min + 1))
    end
    return utils.RNG:RandomFloat() -- float [0,1)
end

function utils.isItemInList(list, item)
	for _, value in ipairs(list) do
		if value == item then
			return true
		end
	end	
	return false
end

function utils.getLuckRNG(player, chance, factor)
	return utils.RNG:RandomInt(100)  + (player.Luck * factor) + chance >= 100
end

function utils.isOfType(entity, eType)
	if entity.Variant == eType.variant and entity.SubType == eType.subtype then
		return true
	end
	return false
end

function utils.getVectorFromDirection(direction)
    if direction == Direction.NO_DIRECTION then
        return utils.VECTOR_ZERO
    end
    return Vector.FromAngle(-180 + direction * 90)
end

function utils.compareEntities(entity1, entity2)
    return entity1.Index == entity2.Index, entity1.InitSeed == entity2.InitSeed
end

function utils.radToDeg (rad)
	return ((rad * 180) / math.pi)
end

function utils.degToRad (deg)
	return ((deg * math.pi) / 180)
end

function utils.findClosestEnemy(entity)
    local entities = AlphaAPI.entities.enemies
    local maxDistance = 999999
    local closestEntity
    for _, e in ipairs(entities) do
        if (entity.Position - e.Position):Length() <= maxDistance and not
                utils.compareEntities(entity, e) and not
                e:HasEntityFlags(EntityFlag.FLAG_CHARM) and not
                e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
            closestEntity = e
            maxDistance = (entity.Position - e.Position):Length()
        end
    end

    if closestEntity then
        return closestEntity
    end

    return nil
end

function utils.chooseRandomTarget()
    local entities = AlphaAPI.entities.enemies
    local valid_entities = {}

    for _, entity in ipairs(entities) do
        if entity:ToNPC() and entity.Type ~= 306 then
            valid_entities[#valid_entities + 1] = entity
        end
    end

    if #valid_entities > 0 then
        local index = 1
        if #valid_entities > 1 then
            index = utils.random(#valid_entities)
        end
        return valid_entities[index]
    end
    return nil
end

function utils.playSound(sfx, vol, delay, loop, pitch) --SFX: SoundEffect.SOUND_SPIDER_COUGH vol: float delay: integer loop:boolean pitch: float
    local player = AlphaAPI.GAME_STATE.PLAYERS[1]
    local sound_entity = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, player.Position, Vector(0,0), nil):ToNPC()
    sound_entity:PlaySound(sfx, vol, delay, loop, pitch)
    sound_entity:Remove()
end

function utils.colorRawData(color)
    return color.R, color.G, color.B, color.A, color.RO, color.GO, color.BO
end

function utils.directionToDegree(direction)
    if direction >= 0 then
        if direction == Direction.LEFT then
            direction = 4
        end
        direction = direction - 1
        return direction*90
    end
    return 0
end

function utils.degreeToDirection(angle)
    while angle / 360 > 1 do
        angle = angle - 360
    end
    if angle > 269 then
        return angle/90 - 3
    end
    return angle/90 + 1
end

 function utils.directionToRad(direction)
    return utils.directionToDegree(direction) * math.pi / 180
end

function utils.radToDirection(angle)
    while angle > math.pi * 2 do
        angle = angle - math.pi * 2
    end
    if angle > (math.pi * 3) / 2 then
        return angle/(math.pi / 2) - 3
    end
    return angle/(math.pi / 2) + 1
end

function utils.atan2(a,b)
    return utils.degToRad(Vector(a, b):GetAngleDegrees())
end

function utils.hasCollectible(itemID)
	local players = AlphaAPI.GAME_STATE.PLAYERS
	local playersThatHaveIt = {}
	for _, player in ipairs(players) do
		if player:HasCollectible(itemID) then
			playersThatHaveIt[#playersThatHaveIt+1] = player
		end
	end
	if #playersThatHaveIt == 0 then
		return nil
	end
	return playersThatHaveIt
end

utils.class = {}
local classInit
function classInit(tbl, ...)
    local inst = {}
    setmetatable(inst, tbl)
    tbl.__index = tbl
    tbl.__call = classInit

    if inst.Init then
        inst:Init(...)
    end

    if inst.PostInit then
        inst:PostInit(...)
    end

    return inst
end

function utils.class:Init(Type)
    self.Type = Type
end

setmetatable(utils.class, {
    __call = classInit
})

function utils.getUniquePlayerIdentifier(player) -- CollectibleRNG seed is a number that is consistent across player type changing, save and continue, and new players being added.
    local data = player:GetData()
    if not data.uniqueIdentifier then
        data.uniqueIdentifier = tostring(player:GetCollectibleRNG(1):GetSeed())
    end

    return data.uniqueIdentifier
end

function utils.mixTables(tbl1, tbl2) -- Updates first table with the values in the second table, merging sub-tables of the same name together
    local mixedIndices = {}
    for i, v in ipairs(tbl2) do
        mixedIndices[i] = true
        tbl1[#tbl1 + 1] = v
    end

    for k, v in pairs(tbl2) do
        if not mixedIndices[k] then
            if tbl1[k] and type(tbl1[k]) == "table" and type(v) == "table" then
                tbl1[k] = utils.mixTables(tbl1[k], v)
            else
                tbl1[k] = v
            end
        end
    end

    return tbl1
end

function utils.deepCopy(tbl, mergeInto) -- Deep copies a table. Can alternatively only deep copy values that are incompatible or missing.
    local outTable = mergeInto or {}
    for k, v in pairs(tbl) do
        if not outTable[k] or type(outTable[k]) ~= type(v) then
            if type(v) == "table" then
                outTable[k] = utils.deepCopy(v)
            else
                outTable[k] = v
            end
        end
    end

    return outTable
end

function utils.lerp(first,second,percent)
	return (first + (second - first)*percent)
end

function utils.getAngleDifference(a1, a2)
    local sub = a1 - a2
    return (sub + 180) % 360 - 180
end

function utils.lerpAngleDegrees(aStart, aEnd, percent)
    return aStart + utils.getAngleDifference(aEnd, aStart) * percent
end

return utils
