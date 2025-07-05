--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) ClassMethodDefinitionParameter 
--- @field scope ClassScope? (Default: public)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)
--- @field body function

--- @class (exact) ClassStaticMethodDefinitionParameter 
--- @field scope ClassScope? (Default: public)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)
--- @field body function

--- @class (exact) ClassAbstractMethodDefinitionParameter 
--- @field scope ClassScope? (Default: public)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)
--- @field body nil

--- @class (exact) ClassStructDefinitionParameter: StructDefinitionParameter
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field extends ClassStructDefinition? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
--- @field static boolean? If the class is defined as static.
--- @field abstract boolean? (Default: false)
--- @field implements InterfaceStructDefinition|InterfaceStructDefinition[]?

--- @class (exact) ChildClassStructDefinitionParameter: StructDefinitionParameter
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field extends ClassStructDefinition? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
--- @field abstract boolean? (Default: false)
--- @field implements InterfaceStructDefinition|InterfaceStructDefinition[]?

--- @class (exact) ClassStructDefinition: HierarchicalStructDefinition, Genericable, Constructable, Fieldable, Staticable, Abstractable, Auditable
--- @field __type__ 'ClassStructDefinition'
--- @field __supertable__ SuperTable
--- @field printHeader string
--- @field type string
--- @field lock boolean
--- @field classObj Class?
--- @field super ClassStructDefinition?
--- @field sub ClassStructDefinition[]
--- @field interfaces InterfaceStructDefinition[]
local ClassStructDefinition = {};

--- @return ClassInstance
function ClassStructDefinition:new(...) end

--- @param definition FieldDefinitionParameter
---
--- @return FieldDefinition
function ClassStructDefinition:addField(definition) end

--- Attempts to resolve a FieldDefinition in the ClassStructDefinition. If the field isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function ClassStructDefinition:getField(name) end

--- @return FieldDefinition[]
function ClassStructDefinition:getFields() end

--- Attempts to resolve a FieldDefinition in the ClassStructDefinition. If the field isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function ClassStructDefinition:getDeclaredField(name) end

--- @param constructorDefinition ConstructorDefinitionParameter
---
--- @return ConstructorDefinition
function ClassStructDefinition:addConstructor(constructorDefinition) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function ClassStructDefinition:getConstructor(args) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function ClassStructDefinition:getDeclaredConstructor(args) end

--- @param definition ClassMethodDefinitionParameter
---
--- @return MethodDefinition
function ClassStructDefinition:addMethod(definition) end

--- @param definition ClassAbstractMethodDefinitionParameter
---
--- @return MethodDefinition
function ClassStructDefinition:addAbstractMethod(definition) end

--- @param definition ClassStaticMethodDefinitionParameter
---
--- @return MethodDefinition
function ClassStructDefinition:addStaticMethod(definition) end

--- Attempts to resolve a MethodDefinition in the ClassStructDefinition. If the method isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function ClassStructDefinition:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function ClassStructDefinition:getMethod(name, args) end

--- Attempts to resolve a MethodDefinition in the ClassStructDefinition. If the method isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function ClassStructDefinition:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function ClassStructDefinition:getDeclaredMethod(name, args) end

--- @returns ClassStructDefinition
function ClassStructDefinition:finalize() end

--- @param class ClassStructDefinition
---
--- @return boolean
function ClassStructDefinition:isAssignableFromType(class) end

--- @param class Hierarchical?
---
--- @return boolean
function ClassStructDefinition:isSuperClass(class) end

--- @param class ClassStructDefinition The class to evaulate.
---
--- @return boolean result True if the class to evaluate is a super-class of the subClass.
function ClassStructDefinition:isSubClass(class) end

--- @param superInterface InterfaceStructDefinition
---
--- @return boolean
function ClassStructDefinition:isSuperInterface(superInterface) end

-- MARK: - Module

--- @class LVMClassModule: LVMModule
local API = {};

--- Defined for all classes so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
function API.equals(a, b) end

--- @param defParams ClassStructDefinitionParameter
---
--- @return ClassStructDefinition
function API.newClass(defParams) end

--- @param defParams ChildClassStructDefinitionParameter
--- @param outer StructDefinition
---
--- @return ClassStructDefinition
function API.newClass(defParams, outer) end
