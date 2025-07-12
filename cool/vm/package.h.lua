--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @alias PackageTable { [string]: (PackageTable | StructDefinition) }

--- @class VMPackageModule: VMModule
--- @field packages PackageTable
local API = {};

--- Constructs a _G package struct. (Used to call from global scope)
---
--- @param path string
---
--- @return table PackageStruct
function API.newPackageStruct(path) end

--- Adds a Class to the _G package struct tree. (Used to call from global scope)
---
--- @param def StructDefinition
function API.addToPackageStruct(def) end
