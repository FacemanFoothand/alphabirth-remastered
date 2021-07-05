local utils = {}

-- Make sure to load this After Alpha API

-- Setup
utils.VECTOR_ZERO = Vector(0,0)
utils.RNG = RNG()
utils.RNG:SetSeed(Random(), 1)

-- Funcs
function utils.random(min, max) -- Re-implements math.random()
    if min ~= nil and max ~= nil then -- Min and max passed, integer [min,max]
        return math.floor(utils.RNG:RandomFloat() * (max - min + 1) + min)
    elseif min ~= nil then -- Only min passed, integer [0,min]
        return math.floor(utils.RNG:RandomFloat() * (min + 1))
    end
    return utils.RNG:RandomFloat() -- float [0,1)
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

return utils