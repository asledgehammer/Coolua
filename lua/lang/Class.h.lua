--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class ClassDefinition: ObjectDefinition
local ClassDefinition = {};

--- @param def Struct
function ClassDefinition.new(def) end

--- @return Class
function ClassDefinition:create() end

--- @class Class: Object
--- @field pkg string
--- @field name string
--- @field struct Struct
---
--- @generic T: ObjectDefinition
local Class = {};

--- @param other Class<ObjectDefinition>
---
--- @return boolean isAssignable
function Class:isAssignableFromType(other) end

--- @return Struct
function Class:getStruct() end

--- @return boolean
function Class:isInterface() end
