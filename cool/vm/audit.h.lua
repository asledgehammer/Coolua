--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @class VMAuditModule: VMModule
local API = {};

--- @param paramDef ParameterStruct
--- @param i integer
--- @param errHeader string
function API.auditParameter(paramDef, i, errHeader) end

--- @param parameters ParameterStruct[]?
--- @param errHeader string
---
--- @return ParameterStruct[]
function API.auditParameters(parameters, errHeader) end

--- @param name string
--- @param errHeader string
---
--- @return string
function API.auditMethodParamName(name, errHeader) end

--- @param structScope ClassScope
--- @param propertyScope ClassScope|nil
---
--- @return ClassScope
function API.auditStructPropertyScope(structScope, propertyScope, errHeader) end

--- @param returnTypes any[]|any
--- @param errHeader string
---
--- @return string[]
function API.auditMethodReturnsProperty(returnTypes, errHeader) end

--- @param rd ClassStruct
--- @param ed EntryStruct
function API.auditEntry(rd, ed) end

--- @param cd ClassStruct
--- @param fd FieldStruct
function API.auditField(cd, fd) end

--- Checks final fields in a class for uninitialization. This is for post-constructor analysis and audits.
---
--- @param classDef ClassStruct
--- @param o ClassInstance
function API.auditFinalFields(classDef, o) end

--- @param consDef ConstructorStruct
function API.auditConstructor(consDef) end

--- @param name any
--- @param errHeader any
function API.auditName(name, errHeader) end
