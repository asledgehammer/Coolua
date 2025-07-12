--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class VMTypeModule: VMModule
local API = {};

--- @param value any
--- @param typeOrTypes string[]|string
--- 
--- @return boolean
function API.isAssignableFromType(value, typeOrTypes) end

--- @param from any[]
--- @param to any[]
---
--- @return boolean
function API.anyCanCastToTypes(from, to) end

--- @param from string
--- @param to string
---
--- @return boolean
function API.canCast(from, to) end

--- @param value any
---
--- @return type|string
function API.getType(value) end
