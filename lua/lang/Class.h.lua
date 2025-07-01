--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class ClassDefinition: LVMClassDefinition
local ClassDefinition = {};

--- @param def ClassDefinition
function ClassDefinition.new(def) end

--- @return Class
function ClassDefinition:create() end

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
