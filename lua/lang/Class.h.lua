--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class ClassDefinition: ClassStruct
local ClassDefinition = {};

--- @param def ClassStruct|InterfaceStructDefinition|EnumStructDefinition
function ClassDefinition.new(def) end

--- @return Class
function ClassDefinition:create() end

--- @class Class: Object
--- @field pkg string
--- @field name string
--- @field definition ClassStruct|InterfaceStructDefinition|EnumStructDefinition
---
--- @generic T: ObjectDefinition
local Class = {};

--- @param other Class<ObjectDefinition>
---
--- @return boolean isAssignable
function Class:isAssignableFromType(other) end

--- @return ClassStruct|InterfaceStructDefinition|EnumStructDefinition
function Class:getDefinition() end

--- @return boolean
function Class:isInterface() end

--- @return boolean
function Class:isEnum() end
