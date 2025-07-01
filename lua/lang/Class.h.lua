--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class ClassDefinition: LVMClassDefinition
local ClassDefinition = {};

--- @param package string
--- @param name string
--- @param def ClassDefinition
function ClassDefinition.new(package, name, def) end

--- @class Class: Object
--- @field package string
--- @field name string
--- @field def ClassDefinition
--- 
--- @generic T: ObjectDefinition
local Class = {};

--- @param other Class<ObjectDefinition>
--- 
--- @return boolean isAssignable
function Class:isAssignableFromType(other) end