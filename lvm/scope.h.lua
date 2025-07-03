--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @alias ClassScope 'private'|'protected'|'package'|'public'

-- MARK: - Module

--- @class LVMScopeModule: LVMModule
local API = {};

--- @param class StructDefinition The class called.
--- @param callInfo CallInfo
---
--- @return ClassScope
function API.getScopeForCall(class, callInfo) end

--- @param expected ClassScope
--- @param given ClassScope
---
--- @return boolean evaluation
function API.canAccessScope(expected, given) end

--- Grabs the most immediate path outside the LVM.
---
--- @return integer level, string relativePath
function API.getRelativePath() end
