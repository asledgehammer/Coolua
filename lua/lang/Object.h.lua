--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class ObjectDefinition: LVMClassDefinition
local ObjectDefinition = {};

--- Empty constructor
function ObjectDefinition.new() end

--- @class Object: ClassInstance
local Object = {};

--- @return Class class The class of the object.
function Object:getClass() end

--- @return boolean result Returns true if the instance is either directly of the class or a super-class.
function Object:instanceOf(classDef) end

--- @param other any
--- 
--- @return boolean isEqualToOther
function Object:equals(other) end

--- @return string text
function Object:toString() end
