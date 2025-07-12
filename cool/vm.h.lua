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
--- @field DEFINITIONS table<string, StructDefinition> Key = `StructDefinition.path`
--- @field CLASSES table<string, Class> Key = `StructDefinition.path`
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
--- @field meta VMMetaModule
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
local VM = {};

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves the definition struct.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return ClassStructDefinition|nil The VM class definition struct. If no definition exists with the path then nil is returned.
function VM.forNameDef(path) end

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves (or builds) a Class object.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return Class|nil classObj The class object. If no definition exists with the path then nil is returned.
function VM.forName(path) end

--- @param path string
---
--- @return StructDefinition|StructReference
function VM.import(path) end
