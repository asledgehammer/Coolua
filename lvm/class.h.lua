--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class LVMClassModule: LVMModule
local API = {};

--- @param path string
---
--- @return LVMClassDefinition|nil
function API.forNameDef(path) end

--- @param path string
---
--- @return Class|nil
function API.forName(path) end

--- Defined for all classes so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
function API.equals(a, b) end

--- @param defParams LVMClassDefinitionParameter
--- 
--- @return LVMClassDefinition
function API.newClass(defParams) end
