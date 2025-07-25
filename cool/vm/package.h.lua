--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @alias PackageTable { [string]: (PackageTable | Struct) }

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
--- @param def Struct
function API.addToPackageStruct(def) end

--- @return PackageTable|nil
function API.getPackage(pkg) end
