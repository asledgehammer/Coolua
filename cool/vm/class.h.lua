--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) ClassMethodStructParameter
--- @field scope ClassScope? (Default: public)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body function

--- @class (exact) ClassStaticMethodStructParameter
--- @field scope ClassScope? (Default: public)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body function

--- @class (exact) ClassAbstractMethodStructParameter
--- @field scope ClassScope? (Default: public)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body nil

--- @class (exact) ClassStructParameter: StructDefinitionParameter
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field extends ClassStruct? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
--- @field static boolean? If the class is defined as static.
--- @field abstract boolean? (Default: false)
--- @field implements InterfaceStruct|InterfaceStruct[]?

--- @class (exact) ChildClassStructParameter: StructDefinitionParameter
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field extends ClassStruct? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
--- @field abstract boolean? (Default: false)
--- @field implements InterfaceStruct|InterfaceStruct[]?

--- @class (exact) ClassStruct: HierarchicalStructDefinition, Genericable, Constructable, Fieldable, Staticable, Abstractable, Auditable
--- @field __type__ 'ClassStruct'
--- @field __readonly__ boolean
--- @field __supertable__ SuperTable
---
--- @field printHeader string
--- @field type string
--- @field classObj Class?
--- @field super ClassStruct?
--- @field sub ClassStruct[]
--- @field interfaces InterfaceStruct[]
local ClassStruct = {};

--- @return ClassInstance
function ClassStruct:new(...) end

--- @param definition FieldDefinitionParameter
---
--- @return FieldDefinition
function ClassStruct:addField(definition) end

--- @param definition StaticFieldDefinitionParameter
---
--- @return FieldDefinition
function ClassStruct:addStaticField(definition) end

--- Attempts to resolve a FieldDefinition in the ClassStruct. If the field isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function ClassStruct:getField(name) end

--- @return FieldDefinition[]
function ClassStruct:getFields() end

--- Attempts to resolve a FieldDefinition in the ClassStruct. If the field isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function ClassStruct:getDeclaredField(name) end

--- @param constructorDefinition ConstructorDefinitionParameter
---
--- @return ConstructorDefinition
function ClassStruct:addConstructor(constructorDefinition) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function ClassStruct:getConstructor(args) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function ClassStruct:getDeclaredConstructor(args) end

--- @param definition ClassMethodStructParameter
---
--- @return MethodStruct
function ClassStruct:addMethod(definition) end

--- @param definition ClassAbstractMethodStructParameter
---
--- @return MethodStruct
function ClassStruct:addAbstractMethod(definition) end

--- @param definition ClassStaticMethodStructParameter
---
--- @return MethodStruct
function ClassStruct:addStaticMethod(definition) end

--- Attempts to resolve a MethodStruct in the ClassStruct. If the method isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function ClassStruct:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function ClassStruct:getMethod(name, args) end

--- Attempts to resolve a MethodStruct in the ClassStruct. If the method isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return MethodStruct[]? methods
function ClassStruct:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodStruct|nil MethodStruct
function ClassStruct:getDeclaredMethod(name, args) end

--- @return ClassStruct
function ClassStruct:finalize() end

--- @return boolean
function ClassStruct:isFinalized() end

--- @param class ClassStruct
---
--- @return boolean
function ClassStruct:isAssignableFromType(class) end

--- @param class Hierarchical?
---
--- @return boolean
function ClassStruct:isSuperClass(class) end

--- @param class ClassStruct The class to evaulate.
---
--- @return boolean result True if the class to evaluate is a super-class of the subClass.
function ClassStruct:isSubClass(class) end

--- @param superInterface InterfaceStruct
---
--- @return boolean
function ClassStruct:isSuperInterface(superInterface) end

--- @param clsDef StructDefinition
function ClassStruct:addStaticStruct(clsDef) end

--- @param clsDef StructDefinition
function ClassStruct:addInstanceStruct(clsDef) end

--- @param outer StructDefinition
function ClassStruct:setOuterStruct(outer) end

-- MARK: - Module

--- @class VMClassModule: VMModule
local API = {};

--- Defined for all classes so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
function API.equals(a, b) end

--- @param defParams ClassStructParameter
---
--- @return ClassStruct
function API.newClass(defParams) end

--- @param defParams ChildClassStructParameter
--- @param outer StructDefinition
---
--- @return ClassStruct
function API.newClass(defParams, outer) end
