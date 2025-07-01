--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class LVMParamModule: LVMModule
local API = {};

--- @param paramsA ParameterDefinition[]
--- @param paramsB ParameterDefinition[]
---
--- @return boolean
function API.areCompatable(paramsA, paramsB) end

--- @param arg string
--- 
--- @return string[] argTypes
function API.getVarargTypes(arg) end

--- @param arg string
--- 
--- @return boolean isVararg
function API.isVararg(arg) end
