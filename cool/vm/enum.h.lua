--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class EnumStructParameter: StructParameter
local EnumStructParameter = {};

--- @class EnumStruct: Struct
local EnumStruct = {};

--- @param definition FieldStructInput
---
--- @return FieldStruct
function EnumStruct:addField(definition) end

--- Attempts to resolve a FieldStruct in the EnumStruct. If the field isn't declared for the class level,
--- the super-class(es) are checked.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function EnumStruct:getField(name) end

--- Attempts to resolve a FieldStruct in the EnumStruct. If the field isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return FieldStruct? FieldStruct
function EnumStruct:getDeclaredField(name) end

--- @param ConstructorStruct ConstructorStructParameter
---
--- @return ConstructorStruct
function EnumStruct:addConstructor(ConstructorStruct) end

--- @param args any[]
---
--- @return ConstructorStruct|nil ConstructorStruct
function EnumStruct:getConstructor(args) end

--- @param args any[]
---
--- @return ConstructorStruct|nil ConstructorStruct
function EnumStruct:getDeclaredConstructor(args) end

--- @param definition MethodStructInput
--- @param func function?
---
--- @return MethodStruct
function EnumStruct:addMethod(definition, func) end

--- Attempts to resolve a MethodStruct in the EnumStruct. If the method isn't declared for the class
--- level, the super-class(es) are checked.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function EnumStruct:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function EnumStruct:getMethod(name, args) end

--- Attempts to resolve a MethodStruct in the EnumStruct. If the method isn't defined in the class, `nil`
--- is returned.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function EnumStruct:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function EnumStruct:getDeclaredMethod(name, args) end

--- @returns ClassStruct
function EnumStruct:finalize() end

-- MARK: - Module

--- @class VMEnumModule: VMModule
local API = {};

--- @param enumDef EnumStructParameter
---
--- @return EnumStruct
function API.newEnum(enumDef) end
