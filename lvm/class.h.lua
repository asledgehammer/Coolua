--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) LVMClassDefinitionParameter: StructDefinitionParameter
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field superClass LVMClassDefinition? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
--- @field static boolean? If the class is defined as static.
--- @field abstract boolean? (Default: false)

--- @class (exact) LVMChildClassDefinitionParameter
--- @field final boolean? (Default: false)
--- @field scope ClassScope? (Default: package)
--- @field superClass LVMClassDefinition? (Default: nil)
--- @field generics GenericsTypesDefinitionParameter? Any generic parameter definitions.
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

-- MARK: - Module

--- @class LVMClassModule: LVMModule
local API = {};

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves the definition struct.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return LVMClassDefinition|nil The LVM class definition struct. If no definition exists with the path then nil is returned.
function API.forNameDef(path) end

--- Simulates path resolution from Java via `Class.forName(..)`. Resolves (or builds) a Class object.
---
--- @param path string The path to the class. syntax: `<package>.<class>`
---
--- @return Class|nil classObj The class object. If no definition exists with the path then nil is returned.
function API.forName(path) end

--- Defined for all classes so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
function API.equals(a, b) end

--- @param defParams LVMClassDefinitionParameter
---
--- @return LVMClassDefinition
function API.newClass(defParams) end

--- @param defParams LVMChildClassDefinitionParameter
--- @param enclosingClass LVMClassDefinition
---
--- @return LVMClassDefinition
function API.newClass(defParams, enclosingClass) end
