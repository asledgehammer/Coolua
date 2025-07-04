--- @meta

-- MARK: - Module

--- @class LVMModule
---
--- @field __type__ 'LVMModule'
local LVMModule = {};

--- @param lvm LVM
function LVMModule.setLVM(lvm) end

-- MARK: - LVM

--- @class LVM
---
--- @field __type__ 'LVM'
---
--- * Constants
--- @field ROOT_PATH string The root path of the running source code.
--- @field DEFINITIONS table<string, StructDefinition> Key = `StructDefinition.path`
--- @field CLASSES table<string, Class> Key = `StructDefinition.path`
--- 
--- @field moduleCount number
--- 
--- * Modules
--- @field debug LVMDebugModule
--- @field enum LVMEnumModule
--- @field flags LVMFlagsModule
--- @field constants LVMConstantsModule
--- @field print LVMPrintModule
--- @field type LVMTypeModule
--- @field scope LVMScopeModule
--- @field audit LVMAuditModule
--- @field package LVMPackageModule
--- @field generic LVMGenericModule
--- @field meta LVMMetaModule
--- @field stack LVMStackModule
--- @field super LVMSuperModule
--- @field field LVMFieldModule
--- @field executable LVMExecutableModule
--- @field class LVMClassModule
--- @field struct LVMStructModule
--- @field interface LVMInterfaceModule
--- 
--- * Helper functions
--- @field isInside fun(): boolean
--- @field isOutside fun(): boolean
--- @field stepIn fun()
--- @field stepOut fun()
local LVM = {};

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves the definition struct.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return ClassStructDefinition|nil The LVM class definition struct. If no definition exists with the path then nil is returned.
function LVM.forNameDef(path) end

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves (or builds) a Class object.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return Class|nil classObj The class object. If no definition exists with the path then nil is returned.
function LVM.forName(path) end
