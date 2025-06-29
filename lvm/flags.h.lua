--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class LVMFlagsModule: LVMModule
--- @field canSetAudit boolean This private switch flag helps set readonly structs as audited.
--- @field ignorePushPopContext boolean This private switch flag helps mute the stack. (For initializing LVM)
--- @field bypassFieldSet boolean Used to internally assign values.
--- @field canGetSuper boolean This private switch flag helps shadow attempts to get super outside the class framework.
--- @field canSetSuper boolean This private switch flag helps shadow attempts to set super outside the class framework.
--- @field allowPackageStructModifications boolean This private switch flag helps shadow assignments and construction of global package struct references.
local API = {};
