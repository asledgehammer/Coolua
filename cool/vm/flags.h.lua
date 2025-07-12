--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class VMFlagsModule: VMModule
--- @field canSetAudit boolean This private switch flag helps set readonly structs as audited.
--- @field ignorePushPopContext boolean This private switch flag helps mute the stack. (For initializing VM)
--- @field bypassFieldSet boolean Used to internally assign values.
--- @field internal number If the value is non-zero, the code is considered inside the VM. Used for bypassing checks.
local API = {};
