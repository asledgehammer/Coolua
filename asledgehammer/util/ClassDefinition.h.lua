--- @meta

--- @alias LuaClassScope 'private'|'protected'|'package'|'public'

--- @class ClassContext The ClassContext is used to monitor and audit calls for scope-visible methods and fields.
--- @field class ClassDefinition|nil The current class in the stack.
--- @field context 'constructor'|'method'|nil The current context. (Final fields can be set here)
--- @field executable ExecutableDefinition|nil The definition of the context.
local ClassContext = {};

--- @class ClassDefinitionParameter
--- @field package string
--- @field name string
--- @field final boolean? (Default: false)
--- @field scope LuaClassScope? (Default: public)
--- @field superClass ClassDefinition? (Default: nil)

--- @class (exact) FieldDefinition
--- @field __type__ 'FieldDefinition'
--- @field name string
--- @field types string[]
--- @field scope LuaClassScope
--- @field value any
--- @field static boolean
--- @field final boolean
--- @field assignedOnce boolean This flag is used for final fields. If true, all assignments will fail.

--- @class (exact) FieldDefinitionParameter
--- @field name string
--- @field types string[]?
--- @field type string?
--- @field scope LuaClassScope?
--- @field static boolean?
--- @field final boolean?
--- @field value any?

--- @class (exact) ExecutableDefinition
--- @field __type__ 'ExecutableDefinition'
--- @field parameters ParameterDefinition[]
--- @field func function

--- @class (exact) ConstructorDefinitionParameter
--- @field parameters ParameterDefinitionParameter[]?

--- @class (exact) ConstructorDefinition: ExecutableDefinition
--- @field __type__ 'ConstructorDefinition'
--- @field func fun(o: any, ...)

--- @class (exact) ParameterDefinitionParameter
--- @field types string[]?
--- @field type string?
--- @field name string

--- @class (exact) ParameterDefinition
--- @field __type__ 'ParameterDefinition'
--- @field name string
--- @field types string[]

--- @class (exact) MethodDefinitionParameter
--- @field scope LuaClassScope? (Default: public)
--- @field static boolean? (Default: false)
--- @field final boolean? (Default: false)
--- @field name string
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)

--- @class (exact) MethodDefinition: ExecutableDefinition
--- @field __type__ 'MethodDefinition'
--- @field scope LuaClassScope
--- @field static boolean
--- @field final boolean
--- @field name string
--- @field override boolean (Default: false)
--- @field super MethodDefinition? (Internally assigned. If none, this is nil)
--- @field returns string[]
--- @field func fun(o: any, ...): (any?)

--- @class (exact) ReturnsDefinitionParameter
--- @field types string[]?
--- @field type string?

--- @class (exact) ReturnsDefinition
--- @field __type__ 'ReturnsDefinition'
--- @field types string[]

--- @class ClassDefinition
--- @field __type__ 'ClassDefinition'
--- @field type string
--- @field path string
--- @field methods table<string, MethodDefinition[]>
--- @field superClass ClassDefinition?
--- @field subClasses ClassDefinition[]
--- @field lock boolean
--- @field name string
--- @field package string
--- @field declaredFields table<string, FieldDefinition>
--- @field declaredMethods table<string, MethodDefinition>
--- @field declaredConstructors ConstructorDefinition[]
local ClassDefinition = {};

-- MARK: - Field

--- @param definition FieldDefinitionParameter
---
--- @return FieldDefinition
function ClassDefinition:addField(definition) end

--- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function ClassDefinition:getField(name) end

--- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function ClassDefinition:getDeclaredField(name) end

-- MARK: - Constructor

--- @param func function
---
--- @return ConstructorDefinition
function ClassDefinition:addConstructor(func) end

--- @param definition ConstructorDefinitionParameter
--- @param func function
---
--- @return ConstructorDefinition
function ClassDefinition:addConstructor(definition, func) end

--- @param args any[]
---
--- @return function|nil constructorWithArgs
function ClassDefinition:getConstructor(args) end

--- @param args any[]
---
--- @return function|nil constructorWithArgs
function ClassDefinition:getDeclaredConstructor(args) end

-- MARK: - Method

--- @param definition MethodDefinitionParameter
--- @param func function
---
--- @return MethodDefinition
function ClassDefinition:addMethod(definition, func) end

--- Attempts to resolve a MethodDefinition in the ClassDefinition. If the method isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function ClassDefinition:getMethods(name) end

--- Attempts to resolve a MethodDefinition in the ClassDefinition. If the method isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function ClassDefinition:getDeclaredMethods(name) end

--- @returns ClassDefinition
function ClassDefinition:finalize() end

--- @param class ClassDefinition
---
--- @return boolean
function ClassDefinition:isAssignableFromType(class) end
