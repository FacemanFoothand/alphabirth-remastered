local g = require("ab_src.modules.globals")
local utils = include("ab_src.modules.utils")

local Pathfinder = utils.class("Pathfinder")
function Pathfinder:Init(entity, speed, updateInterval, collisionDistance)
    self.Entity = entity
    self.Speed = speed
    self.UpdateInterval = updateInterval
    self.CollisionDistance = collisionDistance
end

local GridTileType = {
    FREE = 0,
    OBSTACLE = 1,
    INVALID = 2
}

local function heuristicWeight(room, start, target)
    return (room:GetGridPosition(start) - room:GetGridPosition(target)):LengthSquared()
end

local function getPathToTarget(start, target)
    local room = g.room
    local startIdx = room:GetGridIndex(start)
    local targetIdx = room:GetGridIndex(target)
    local grid = {}
    for i=1, room:GetGridSize() do
        local col = room:GetGridCollision(i)
        if col == 0 then
            grid[i] = GridTileType.FREE
        else
            grid[i] = GridTileType.OBSTACLE
        end
    end
    local w = room:GetGridWidth()
    local success = false
    local closedSet = {}
    local openSet = {}
    openSet[1] = startIdx
    local cameFrom = {}
    local gScore = {}
    for i=1, #grid do
        gScore[i] = 99999999
    end
    gScore[startIdx] = 0
    local fScore = {}
    for i=1, #grid do
        fScore[i] = 99999999
    end
    fScore[startIdx] = heuristicWeight(room, startIdx, targetIdx)
    while #openSet > 0 do
        local current
        local current_openSetIndex
        local best_fScore = 99999999
        for i=1, #openSet do
            if fScore[openSet[i]] < best_fScore then
                current = openSet[i]
                current_openSetIndex = i
                best_fScore = fScore[openSet[i]]
            end
        end
        if current == targetIdx then
            success = true
            break
        end
        table.remove(openSet, current_openSetIndex)
        closedSet[current] = true
        local neighbors = {
            {idx=current-1, cost=1},
            {idx=current+1, cost=1},
            {idx=current-w, cost=1},
            {idx=current+w, cost=1},
        }
        for _,neigh in pairs(neighbors) do
            local n = neigh.idx
            if (grid[n] == GridTileType.FREE or n == targetIdx) and (closedSet[n] ~= true) then
                local tentative_gScore = gScore[current] + 1
                local in_openSet = false
                for i=1, #openSet do
                    if openSet[i] == n then
                        in_openSet = true
                        break
                    end
                end
                if (not in_openSet) or tentative_gScore < gScore[n] then
                    openSet[#openSet+1] = n
                    cameFrom[n] = current
                    gScore[n] = tentative_gScore
                    fScore[n] = gScore[n] + heuristicWeight(room, n, targetIdx)
                end
            end
        end
    end
    if success then
        local path = {}
        local count = 1
        local current = targetIdx
        while cameFrom[current] do
            current = cameFrom[current]
            count = count + 1
        end
        local current = targetIdx
        if grid[targetIdx] ~= GridTileType.FREE then
            count = count - 1
            current = cameFrom[targetIdx]
        end
        while current do
            path[count] = current
            count = count - 1
            current = cameFrom[current]
        end
        return path
    else
        return nil
    end
end

function Pathfinder:aStarPathing(target, onTargetCollisionFn)
    self.Target = target
    if target:Distance(self.Entity.Position) <= self.CollisionDistance and onTargetCollisionFn then
        onTargetCollisionFn()
    end

    if self.Entity.FrameCount % self.UpdateInterval == 0 then
        self.Path = nil
    end

    if not self.Path then
        self.Path = getPathToTarget(self.Entity.Position, target)
        self.Entity:GetData().pathidx = 1
    else
        local velocity = g.room:GetGridPosition(self.Path[self.Entity:GetData().pathidx]) - self.Entity.Position
        if velocity:Length() < 32 then
            self.Entity:GetData().pathidx = self.Entity:GetData().pathidx + 1
            if not self.Path[self.Entity:GetData().pathidx] then
                self.Entity:GetData().TargetVelocity = Vector(0,0)
                self.Path = nil
            end
        end
        self.Entity:GetData().TargetVelocity = velocity:Normalized() * 2
    end
    self.Entity.Velocity = self.Entity.Velocity * 0.9 + self.Entity:GetData().TargetVelocity * self.Speed
end

return Pathfinder