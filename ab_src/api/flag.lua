local g = require("ab_src.modules.globals")
local utils = include("ab_src.modules.utils")
local mod = g.mod

local Flag = utils.class("Flag")

local function getEntityFromRef(entityref)
	if entityref == nil then return end
	if not entityref.GetData then
		if entityref.Entity then entityref = entityref.Entity end
		if entityref.SubType and not entityref.GetData then
			local entityLookUp = AlphaAPI.entities.keyed[entityref.Type][entityref.Index]
			if entityLookUp then
				return entityLookUp
			end
		elseif entityref.GetData then
			return entityref
		end
	else
		return entityref
	end

	return nil
end


function Flag:Init(name)
	self.name = name
end

function Flag:Apply(entity)
	entity = getEntityFromRef(entity)
	if entity then
		local data = entity:GetData()
		if data.__ab_flags then
			data.__ab_flags[self.name] = true
		else
			data.__ab_flags = {}
			data.__ab_flags[self.name] = true
		end
	end
end

function Flag:Clear(entity)
	entity = getEntityFromRef(entity)

	if entity then
		local data = entity:GetData()
		if data.__ab_flags then
			data.__ab_flags[self.name] = nil
		end
	end
end

function Flag:EntityHas(entity)
	entity = getEntityFromRef(entity)

	if entity then
		local data = entity:GetData()
		if data.__ab_flags then
			if data.__ab_flags[self.name] then
				return true
			end
		end
	end
	return false
end

return Flag