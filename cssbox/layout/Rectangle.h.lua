--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class RectangleDefinition: DimensionDefinition
local RectangleDefinition = {};

function RectangleDefinition.new() end

--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- 
--- @return Rectangle
function RectangleDefinition.new(x, y, width, height) end

--- @class Rectangle: Dimension
--- @field x number
--- @field y number
local Rectangle = {};

--- @return number x
function Rectangle:getX() end

--- @return number y
function Rectangle:getY() end
