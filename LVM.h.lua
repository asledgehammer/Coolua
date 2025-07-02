--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @alias ClassScope 'private'|'protected'|'package'|'public'

-- MARK: - LVM

--- @class (exact) LVM
---
--- @field __type__ 'LVM'
---
--- * Constants
--- @field ROOT_PATH string The root path of the running source code.
--- 
--- * Modules
--- @field debug LVMDebugModule
--- @field enum LVMEnumModule
--- @field flags LVMFlagsModule
--- @field constants LVMConstantsModule
--- @field print LVMPrintModule
--- @field type LVMTypeModule
--- @field scope LVMScopeModule
--- @field audit LVMAuditModule
--- @field package LVMPackageModule
--- @field generic LVMGenericModule
--- @field meta LVMMetaModule
--- @field stack LVMStackModule
--- @field super LVMSuperModule
--- @field field LVMFieldModule
--- @field parameter LVMParameterModule
--- @field constructor LVMConstructorModule
--- @field method LVMMethodModule
--- @field class LVMClassModule
--- 
--- * Helper functions
--- @field isInside fun(): boolean
--- @field isOutside fun(): boolean
--- @field stepIn fun()
--- @field stepOut fun()
--- 
local LVM = {};

--- @class LVMModule
---
--- @field __type__ 'LVMModule'
local LVMModule = {};

--- @param lvm LVM
function LVMModule.setLVM(lvm) end

-- MARK: - Generics

--- @alias GenericsTypesDefinition GenericTypeDefinition[] Applied on Class-Scope and Method-Scope.

--- @class (exact) GenericTypeDefinition The base definition for all generic definitions.
---
--- @field __type__ 'GenericTypeDefinition'
---
--- @field name string The name of the genric type.
--- @field types table<string, any> One or more types to assign.

--- @alias GenericsTypesDefinitionParameter GenericTypeDefinitionParameter[] Applied on Class-Scope and Method-Scope.

--- @class (exact) GenericTypeDefinitionParameter
---
--- @field name string The name of the generic type.
--- @field types string[]? If two or more types are assignable, use the types string[].
--- @field type string? If one type is assignable, use the type string.

-- MARK: - Class

-- MARK: - Field

--- @class (exact) FieldDefinition
--- @field __type__ 'FieldDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class LVMClassDefinition
--- @field name string
--- @field types string[]
--- @field scope ClassScope
--- @field value any
--- @field static boolean
--- @field final boolean
--- @field get FieldGetDefinition?
--- @field set FieldSetDefinition?
--- @field assignedOnce boolean This flag is used for final fields. If true, all assignments will fail.

--- @class (exact) FieldDefinitionParameter
--- @field name string
--- @field types string[]?
--- @field type string?
--- @field scope ClassScope?
--- @field static boolean?
--- @field final boolean?
--- @field value any?
--- @field get FieldGetDefinition?
--- @field set FieldSetDefinition?

--- @class (exact) FieldGetDefinition
--- @field scope ClassScope?
--- @field func function?

--- @class (exact) FieldSetDefinition
--- @field scope ClassScope?
--- @field func function?

-- MARK: - Constructor

--- @class (exact) ConstructorDefinition
--- @field __type__ 'ConstructorDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class LVMClassDefinition
--- @field scope ClassScope
--- @field parameters ParameterDefinition[]
--- @field func fun(o: any, ...)

--- @class (exact) ConstructorDefinitionParameter
--- @field scope ClassScope? (Default: "package")
--- @field parameters ParameterDefinitionParameter[]?

-- MARK: - Parameter

--- @class (exact) ParameterDefinition
--- @field __type__ 'ParameterDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class LVMClassDefinition
--- @field name string
--- @field types string[]

--- @class (exact) ParameterDefinitionParameter
--- @field types string[]?
--- @field type string?
--- @field name string?

-- MARK: - Method

--- @class (exact) MethodDefinition
--- @field __type__ 'MethodDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class LVMClassDefinition
--- @field scope ClassScope
--- @field static boolean
--- @field final boolean
--- @field name string
--- @field override boolean (Default: false)
--- @field super MethodDefinition? (Internally assigned. If none, this is nil)
--- @field generics GenericsTypesDefinition?
--- @field parameters ParameterDefinition[]
--- @field returns string[]
--- @field func fun(o: any, ...): (any?)
--- @field lineRange {start: number, stop: number} The function's start and stop line.
--- @field abstract boolean (Default: false)

--- @class (exact) MethodDefinitionParameter
--- @field scope ClassScope? (Default: public)
--- @field static boolean? (Default: false)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)
--- @field abstract boolean? (Default: false)

-- MARK: - Return

--- @class (exact) ReturnsDefinition
--- @field __type__ 'ReturnsDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field types string[]

--- @class (exact) ReturnsDefinitionParameter
--- @field types string[]?
--- @field type string?

-- MARK: (LVM) Class

--- @class (exact) LVMClassDefinitionParameter
--- @field name string? (Default: The name of the file)
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field superClass LVMClassDefinition? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
--- @field static boolean? If the class is defined as static.
--- @field pkg string?
--- @field abstract boolean? (Default: false)


--- @class (exact) LVMChildClassDefinitionParameter
--- @field name string? (Default: The name of the file)
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field superClass LVMClassDefinition? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
--- @field pkg string?
--- @field abstract boolean? (Default: false)

--- @class (exact) LVMClassDefinition
--- @field __type__ 'ClassDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field __middleConstructor function
--- @field __middleMethods table<string, function>
--- @field printHeader string
--- @field type string
--- @field path string
--- @field methods table<string, MethodDefinition[]>
--- @field superClass LVMClassDefinition
--- @field subClasses (LVMClassDefinition|Class)[]
--- @field lock boolean
--- @field name string
--- @field final boolean (Default: false) If the class is final and cannot be extended.
--- @field isChild boolean
--- @field package string
--- @field classObj Class?
--- @field declaredFields table<string, FieldDefinition>
--- @field declaredMethods table<string, MethodDefinition>
--- @field declaredConstructors ConstructorDefinition[]
--- @field staticFields table<string, any> Stores the static values for classes.
--- @field generics GenericsTypesDefinition? If the class supports generics, this is where its defined.
--- @field abstract boolean (Default: false)
---
--- @field children table<string, LVMClassDefinition> Any classes that are defined within the class's context.
--- @field static boolean (Default: false) If true, the class is considered static.
--- @field enclosingClass LVMClassDefinition
local LVMClassDefinition = {};

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

--- @param constructorDefinition ConstructorDefinitionParameter
--- @param func function
---
--- @return ConstructorDefinition
function LVMClassDefinition:addConstructor(constructorDefinition, func) end

--- @param constructorDefinition ConstructorDefinitionParameter
---
--- @return ConstructorDefinition
function LVMClassDefinition:addConstructor(constructorDefinition) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function LVMClassDefinition:getConstructor(args) end

--- @param args any[]
---
--- @return ConstructorDefinition|nil constructorDefinition
function LVMClassDefinition:getDeclaredConstructor(args) end

--- @param definition MethodDefinitionParameter
--- @param func function?
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

--- @returns LVMClassDefinition
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

--- @return Class
function LVMClassDefinition:create() end

-- MARK: StackTrace

--- @class ClassContext The ClassContext is used to monitor and audit calls for scope-visible methods and fields.
---
--- @field class LVMClassDefinition The current class in the stack.
--- @field context 'constructor'|'method'|'field-get'|'field-set' The current context. (Final fields can be set here)
--- @field executable MethodDefinition|ConstructorDefinition? The definition of the context.
--- @field field FieldDefinition?
--- @field file string
--- @field line integer
local ClassContext = {};
