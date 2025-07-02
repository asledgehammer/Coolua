--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class ClassDefinition: LVMClassDefinition
local ClassDefinition = {};

--- @param def LVMClassDefinition
function ClassDefinition.new(def) end

--- @return Class
function ClassDefinition:create() end

--- @class Class: Object
--- @field pkg string
--- @field name string
--- @field definition ClassDefinition
---
--- @generic T: ObjectDefinition
local Class = {};

--- @param other Class<ObjectDefinition>
---
--- @return boolean isAssignable
function Class:isAssignableFromType(other) end

--- @return LVMClassDefinition
function Class:getDefinition() end
