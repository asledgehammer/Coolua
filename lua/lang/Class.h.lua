--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class ClassDefinition: ClassStructDefinition
local ClassDefinition = {};

--- @param def ClassStructDefinition
function ClassDefinition.new(def) end

--- @return Class
function ClassDefinition:create() end

--- @class Class: Object
--- @field pkg string
--- @field name string
--- @field definition ClassStructDefinition
---
--- @generic T: ObjectDefinition
local Class = {};

--- @param other Class<ObjectDefinition>
---
--- @return boolean isAssignable
function Class:isAssignableFromType(other) end

--- @return ClassStructDefinition
function Class:getDefinition() end
