--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class LVMClassModule: LVMModule
local API = {};

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves the definition struct.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return LVMClassDefinition|nil The LVM class definition struct. If no definition exists with the path then nil is returned.
function API.forNameDef(path) end

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves (or builds) a Class object.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return Class|nil classObj The class object. If no definition exists with the path then nil is returned.
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

--- @param defParams LVMChildClassDefinitionParameter
--- @param enclosingClass LVMClassDefinition
---
--- @return LVMClassDefinition
function API.newClass(defParams, enclosingClass) end
