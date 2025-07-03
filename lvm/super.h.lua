--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class LVMSuperModule: LVMModule
local API = {};

--- MiddleSuper instances are created formatted the ClassInstance, not `Superable`. This simplifies calls providing
--- the instance as the first argument.
---
--- @param cd ClassStructDefinition
--- @param o ClassInstance
---
--- @return SuperTable
function API.createSuperTable(cd, o) end
