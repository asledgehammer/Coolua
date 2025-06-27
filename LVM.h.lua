--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @alias ClassScope 'private'|'protected'|'package'|'public'

--- @class ClassContext The ClassContext is used to monitor and audit calls for scope-visible methods and fields.
--- @field class LVMClassDefinition The current class in the stack.
--- @field context 'constructor'|'method'|'field-get'|'field-set' The current context. (Final fields can be set here)
--- @field executable MethodDefinition|ConstructorDefinition? The definition of the context.
--- @field field FieldDefinition?
--- @field file string
--- @field line integer
local ClassContext = {};

--- @class LVMClassDefinitionParameter
--- @field name string? (Default: The name of the file)
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: public)
--- @field superClass LVMClassDefinition? (Default: nil)

--- @class (exact) FieldDefinition
--- @field __type__ 'FieldDefinition'
--- @field class LVMClassDefinition
--- @field name string
--- @field types string[]
--- @field scope ClassScope
--- @field value any
--- @field static boolean
--- @field final boolean
--- @field assignedOnce boolean This flag is used for final fields. If true, all assignments will fail.

--- @class (exact) FieldDefinitionParameter
--- @field name string
--- @field types string[]?
--- @field type string?
--- @field scope ClassScope?
--- @field static boolean?
--- @field final boolean?
--- @field value any?

--- @class (exact) ConstructorDefinitionParameter
--- @field scope ClassScope? (Default: "package")
--- @field parameters ParameterDefinitionParameter[]?

--- @class (exact) ConstructorDefinition
--- @field class LVMClassDefinition
--- @field scope ClassScope
--- @field parameters ParameterDefinition[]
--- @field __type__ 'ConstructorDefinition'
--- @field func fun(o: any, ...)

--- @class (exact) ParameterDefinitionParameter
--- @field types string[]?
--- @field type string?
--- @field name string

--- @class (exact) ParameterDefinition
--- @field __type__ 'ParameterDefinition'
--- @field class LVMClassDefinition
--- @field name string
--- @field types string[]

--- @class (exact) MethodDefinitionParameter
--- @field scope ClassScope? (Default: public)
--- @field static boolean? (Default: false)
--- @field final boolean? (Default: false)
--- @field name string
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)

--- @class (exact) MethodDefinition
--- @field __type__ 'MethodDefinition'
--- @field class LVMClassDefinition
--- @field scope ClassScope
--- @field static boolean
--- @field final boolean
--- @field name string
--- @field override boolean (Default: false)
--- @field super MethodDefinition? (Internally assigned. If none, this is nil)
--- @field parameters ParameterDefinition[]
--- @field returns string[]
--- @field func fun(o: any, ...): (any?)
--- @field lineRange {start: number, stop: number} The function's start and stop line.

--- @class (exact) ReturnsDefinitionParameter
--- @field types string[]?
--- @field type string?

--- @class (exact) ReturnsDefinition
--- @field __type__ 'ReturnsDefinition'
--- @field types string[]

--- @class LVMClassDefinition
--- @field __type__ 'ClassDefinition'
--- @field __middleConstructor function
--- @field __middleMethods table<string, function>
--- @field printHeader string
--- @field type string
--- @field path string
--- @field methods table<string, MethodDefinition[]>
--- @field superClass LVMClassDefinition?
--- @field subClasses LVMClassDefinition[]
--- @field lock boolean
--- @field name string
--- @field package string
--- @field declaredFields table<string, FieldDefinition>
--- @field declaredMethods table<string, MethodDefinition>
--- @field declaredConstructors ConstructorDefinition[]
--- @field staticFields table<string, any> Stores the static values for classes.
local LVMClassDefinition = {};

-- MARK: - Field

--- @param definition FieldDefinitionParameter
---
--- @return FieldDefinition
function LVMClassDefinition:addField(definition) end

--- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function LVMClassDefinition:getField(name) end

--- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return FieldDefinition? fieldDefinition
function LVMClassDefinition:getDeclaredField(name) end

-- MARK: - Constructor

--- @param constructorDefinition ConstructorDefinitionParameter
--- @param func function
---
--- @return ConstructorDefinition
function LVMClassDefinition:addConstructor(constructorDefinition, func) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function LVMClassDefinition:getConstructor(args) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function LVMClassDefinition:getDeclaredConstructor(args) end

-- MARK: - Method

--- @param definition MethodDefinitionParameter
--- @param func function
---
--- @return MethodDefinition
function LVMClassDefinition:addMethod(definition, func) end

--- Attempts to resolve a MethodDefinition in the ClassDefinition. If the method isn't declared for the class level, the
--- super-class(es) are checked.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function LVMClassDefinition:getMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function LVMClassDefinition:getMethod(name, args) end

--- Attempts to resolve a MethodDefinition in the ClassDefinition. If the method isn't defined in the class, nil
--- is returned.
---
--- @param name string
---
--- @return MethodDefinition[]? methods
function LVMClassDefinition:getDeclaredMethods(name) end

--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function LVMClassDefinition:getDeclaredMethod(name, args) end

--- @returns ClassDefinition
function LVMClassDefinition:finalize() end

--- @param class LVMClassDefinition
---
--- @return boolean
function LVMClassDefinition:isAssignableFromType(class) end

--- @param line integer
---
--- @return ConstructorDefinition|nil method
function LVMClassDefinition:getExecutableFromLine(line) end

--- @param line integer
---
--- @return MethodDefinition|nil method
function LVMClassDefinition:getMethodFromLine(line) end

--- @param line integer
---
--- @return ConstructorDefinition|nil method
function LVMClassDefinition:getConstructorFromLine(line) end