--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) ExecutableDefinition (interface)
--- @field __type__ string
--- @field signature string The identity of the method. used for comparison.
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field parameters ParameterDefinition[]
--- @field body function?
--- @field bodyInfo FunctionInfo The function's information. (line-range and path)
--- @field scope ClassScope

--- @class (exact) MethodDefinition: ExecutableDefinition
--- @field __type__ 'MethodDefinition'
--- @field class StructDefinition
--- @field name string
--- @field super MethodDefinition? (Internally assigned. If none, this is nil)
--- @field generics GenericsTypesDefinition?
--- @field parameters ParameterDefinition[]
--- @field returns string[]
---
--- * General Flags *
--- @field static boolean
--- @field final boolean
--- @field override boolean (Default: false)
---
--- * Class Flags *
--- @field abstract boolean (Default: false)
---
--- * Interface Flags *
--- @field interface boolean (Default: false) If the method belongs to an interface.
--- @field default boolean (Default: false) If true, `interface` is true and the method is also defined in the interface.

--- @class (exact) MethodDefinitionParameter
---
--- @field scope ClassScope? (Default: public)
--- @field static boolean? (Default: false)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field parameters ParameterDefinitionParameter[]? (Default: no parameters)
--- @field returns (string[]|string)? (Default: void)

--- @class (exact) ConstructorDefinition: ExecutableDefinition
--- @field __type__ 'ConstructorDefinition'
--- @field class ClassStructDefinition
--- @field parameters ParameterDefinition[]
--- @field super fun(super: SuperTable, ...) This function is called prior to the body function.
--- @field body fun(o: any, ...) TODO: Rename as `body`.

--- @class (exact) ConstructorDefinitionParameter
--- @field scope ClassScope? (Default: "package")
--- @field parameters ParameterDefinitionParameter[]?
--- @field super fun(super: SuperTable, ...)? This function is called prior to the body function. If not defined, an attempt at `super()` is called. If not exists, an error occurs.
--- @field body fun(o: any, ...)? TODO: Rename as `body`.

--- @class (exact) ParameterDefinition
--- @field __type__ 'ParameterDefinition'
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class ClassStructDefinition
--- @field name string
--- @field types string[]

--- @class (exact) ParameterDefinitionParameter
--- @field types string[]?
--- @field type string?
--- @field name string?

-- MARK: - Module

--- @class LVMExecutableModule: LVMModule
local API = {};

--- @param classDef StructDefinition
--- @param name string
--- @param methods table<string, MethodDefinition>
---
--- @return fun(o: ClassInstance, ...): (any?)
function API.createMiddleMethod(classDef, name, methods) end

--- @param classDef Methodable
---
--- @return string[] methodNames
function API.getDeclaredMethodNames(classDef, array) end

--- @param classDef StructDefinition
--- @param methodNames string[]?
---
--- @return string[] methodNames
function API.getMethodNames(classDef, methodNames) end

--- @param definition MethodDefinition
---
--- @return string
function API.createSignature(definition) end

--- @param struct StructDefinition Used to cache results at class-level.
--- @param name string
--- @param methods table<string, MethodDefinition>
--- @param args any[]
---
--- @return MethodDefinition|nil
function API.resolveMethod(struct, name, methods, args) end

--- @param name string
--- @param args string[]
---
--- @return string methodSignature
function API.createCallSignature(name, args) end

--- @param args any[]
---
--- @return string[] argsAsTypes
function API.argsToTypes(args) end

--- @param methods table<string, MethodDefinition>
--- @param args any[]
---
--- @return MethodDefinition|nil
function API.resolveMethodDeep(methods, args) end

--- @param self StructDefinition
--- @param name string
--- @param comb table<string, table<MethodDefinition>>
---
--- @return table<string, table<string, MethodDefinition>>
function API.combineAllMethods(self, name, comb) end

--- @param self ClassStructDefinition|InterfaceStructDefinition
function API.compileMethods(self) end

--- @param self StructDefinition
--- @param path string
--- @param line integer
---
--- @return MethodDefinition|nil method
function API.getDeclaredMethodFromLine(self, path, line) end

--- @param self ClassStructDefinition|InterfaceStructDefinition
--- @param path string
--- @param line number
---
--- @return ExecutableDefinition
function API.getExecutableFromLine(self, path, line) end

--- @param func function?
---
--- @return FunctionInfo
function API.getExecutableInfo(func) end

--- @param classDef ClassStructDefinition
function API.createMiddleConstructor(classDef) end

--- @param constructors ConstructorDefinition[]
--- @param args table
---
--- @return ConstructorDefinition|nil
function API.resolveConstructor(constructors, args) end

--- @param definition ConstructorDefinition
---
--- @return string
function API.createSignature(definition) end

--- @param self Constructable
--- @param path string
--- @param line integer
---
--- @return ConstructorDefinition|nil method
function API.getConstructorFromLine(self, path, line) end

--- @param paramsA ParameterDefinition[]
--- @param paramsB ParameterDefinition[]
---
--- @return boolean
function API.areCompatible(paramsA, paramsB) end

--- @param arg string
---
--- @return string[] argTypes
function API.getVarargTypes(arg) end

--- @param arg string
---
--- @return boolean isVararg
function API.isVararg(arg) end

--- @param defParams ParameterDefinition
---
--- @return ParameterDefinition
function API.compile(defParams) end
