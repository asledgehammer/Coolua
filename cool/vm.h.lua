--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Module

--- @class VMModule
---
--- @field __type__ 'VMModule'
local VMModule = {};

--- @param vm VM
function VMModule.setVM(vm) end

-- MARK: - VM

--- @class VM
---
--- @field __type__ 'VM'
---
--- * Constants
--- @field ROOT_PATH string The root path of the running source code.
--- @field DEFINITIONS table<string, Struct> Key = `Struct.path`
--- @field CLASSES table<string, Class> Key = `Struct.path`
--- @field PACKAGES table<string, Package> Key = `Struct.path`
---
--- @field moduleCount number
---
--- * Modules
--- @field debug VMDebugModule
--- @field enum VMEnumModule
--- @field flags VMFlagsModule
--- @field constants VMConstantsModule
--- @field print VMPrintModule
--- @field type VMTypeModule
--- @field scope VMScopeModule
--- @field audit VMAuditModule
--- @field package VMPackageModule
--- @field generic VMGenericModule
--- @field stack VMStackModule
--- @field super VMSuperModule
--- @field field VMFieldModule
--- @field executable VMExecutableModule
--- @field class VMClassModule
--- @field struct VMStructModule
--- @field interface VMInterfaceModule
---
--- * Helper functions
--- @field isInside fun(): boolean
--- @field isOutside fun(): boolean
--- @field stepIn fun()
--- @field stepOut fun()
local vm = {};

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves the definition struct.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return ClassStruct|nil The VM class definition struct. If no definition exists with the path then nil is returned.
function vm.forNameDef(path) end

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves (or builds) a Class object.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return Class|nil classObj The class object. If no definition exists with the path then nil is returned.
function vm.forName(path) end

--- @generic T: Struct|StructReference
--- @param path string
---
--- @return T
function vm.import(path) end

--- @param path string
---
--- @return Package
function vm.getPackage(path) end
