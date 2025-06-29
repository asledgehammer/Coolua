--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class LVMAuditModule: LVMModule
local API = {};

--- @param paramDef ParameterDefinition
function API.auditParameter(paramDef) end

--- @param genDef GenericTypeDefinition
function API.auditGenericType(genDef) end

--- Checks final fields in a class for uninitialization. This is for post-constructor analysis and audits.
---
--- @param classDef LVMClassDefinition
--- @param o ClassInstance
function API.auditFinalFields(classDef, o) end

--- @param consDef ConstructorDefinition
function API.auditConstructor(consDef) end
