--- @meta

--- @class LVMPackageModule: LVMModule
local API = {};

--- Constructs a _G package struct. (Used to call from global scope)
---
--- @return table PackageStruct
function API.newPackageStruct() end

--- Adds a Class to the _G package struct tree. (Used to call from global scope)
---
--- @param def LVMClassDefinition
function API.addToPackageStruct(def) end
