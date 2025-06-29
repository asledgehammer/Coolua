--- @meta

--- @class LVMSuperModule: LVMModule
local API = {};

--- MiddleSuper instances are created formatted the ClassInstance, not ClassDefinition. This simplifies calls providing
--- the instance as the first argument.
---
--- @param cd LVMClassDefinition
--- @param o ClassInstance
---
--- @return SuperTable
function API.createSuperTable(cd, o) end
