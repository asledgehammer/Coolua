--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class DimensionDefinition: ObjectDefinition
local DimensionDefinition = {};

--- @param width number
--- @param height number
---
--- @return Dimension
function DimensionDefinition.new(width, height) end

--- @class Dimension: Object
--- @field width number
--- @field height number
local Dimension = {};

--- @return number width
function Dimension:getWidth() end

--- @return number height
function Dimension:getHeight() end
