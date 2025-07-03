--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) ClassStructDefinitionParameter: StructDefinitionParameter
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field superClass ClassStructDefinition? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
--- @field static boolean? If the class is defined as static.
--- @field abstract boolean? (Default: false)

--- @class (exact) ChildClassStructDefinitionParameter: StructDefinitionParameter
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field superClass ClassStructDefinition? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
--- @field abstract boolean? (Default: false)

--- @class (exact) ClassStructDefinition: StructDefinition, Genericable, Hierarchical, Constructable, Fieldable, Staticable, Abstractable, Auditable
--- @field __type__ 'ClassStructDefinition'
--- @field printHeader string
--- @field type string
--- @field lock boolean
--- @field classObj Class?
--- @field superClass ClassStructDefinition?
local ClassStructDefinition = {};

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

--- Attempts to resolve a FieldDefinition in the ClassStructDefinition. If the field isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function ClassStructDefinition:getDeclaredField(name) end

--- @param constructorDefinition ConstructorDefinitionParameter
--- @param func function
---
--- @return ConstructorDefinition
function ClassStructDefinition:addConstructor(constructorDefinition, func) end

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

--- @param definition MethodDefinitionParameter
--- @param func function?
---
--- @return MethodDefinition
function ClassStructDefinition:addMethod(definition, func) end

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

--- @param line integer
---
--- @return ConstructorDefinition|nil method
function ClassStructDefinition:getExecutableFromLine(line) end

--- @param line integer
---
--- @return MethodDefinition|nil method
function ClassStructDefinition:getMethodFromLine(line) end

--- @param line integer
---
--- @return ConstructorDefinition|nil method
function ClassStructDefinition:getConstructorFromLine(line) end

--- @return Class
function ClassStructDefinition:create() end

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
--- @param enclosingClass ClassStructDefinition
---
--- @return ClassStructDefinition
function API.newClass(defParams, enclosingClass) end
