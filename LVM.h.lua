--- @meta

-- MARK: - Module

--- @class LVMModule
---
--- @field __type__ 'LVMModule'
local LVMModule = {};

--- @param lvm LVM
function LVMModule.setLVM(lvm) end

-- MARK: - LVM

--- @class (exact) LVM
---
--- @field __type__ 'LVM'
---
--- * Constants
--- @field ROOT_PATH string The root path of the running source code.
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
--- @field parameter LVMParameterModule
--- @field constructor LVMConstructorModule
--- @field method LVMMethodModule
--- @field class LVMClassModule
--- @field struct LVMStructModule
--- 
--- * Helper functions
--- @field isInside fun(): boolean
--- @field isOutside fun(): boolean
--- @field stepIn fun()
--- @field stepOut fun()
