--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Struct

--- @alias ClassScope 'private'|'protected'|'package'|'public'

--- @alias DetailedCallInfo CallInfo|{file:string, folder:string}

-- MARK: - Module

--- @class VMScopeModule: VMModule
local API = {};

--- @param class Struct The class called.
--- @param callInfo DetailedCallInfo
--- @param callStruct Struct? (Optional) For calls within struct construction.
---
--- @return ClassScope
function API.getScopeForCall(class, callInfo, callStruct) end

--- @param expected ClassScope
--- @param given ClassScope
---
--- @return boolean evaluation
function API.canAccessScope(expected, given) end

--- Grabs the most immediate path outside the VM.
---
--- @return integer level, string relativePath
function API.getRelativePath() end

--- Grabs the most immediate path outside the VM.
---
--- @return integer level, string relativePath, string folder
function API.getRelativeFile() end

--- @return DetailedCallInfo
function API.getRelativeCall() end
