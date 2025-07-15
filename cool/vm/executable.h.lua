--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Definition

--- @class (exact) Parameterable
---
--- @field parameters ParameterDefinition[]
--- @field vararg boolean If true, the executable's last paramater is a vararg.

--- @class (exact) ParameterableInput
---
--- @field parameters ParameterDefinition[]? (Default: No parameters)
--- @field vararg boolean? (Default: false) If true, the executable's last paramater is a vararg.

--- @class (exact) ExecutableDefinition: Parameterable
---
--- @field __type__ string
---
--- @field signature string The identity of the method. used for comparison.
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field body function?
--- @field bodyInfo FunctionInfo The function's information. (line-range and path)
--- @field scope ClassScope

--- @class (exact) MethodStruct: ExecutableDefinition
---
--- @field __type__ 'MethodStruct'
---
--- @field class StructDefinition
--- @field name string
--- @field super MethodStruct? (Internally assigned. If none, this is nil)
--- @field generics GenericsTypesDefinition?
--- @field parameters ParameterDefinition[]
--- @field returnTypes AllowedType[]|AllowedType
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

--- @class (exact) MethodStructParameter: ParameterableInput
---
--- @field scope ClassScope? (Default: public)
--- @field static boolean? (Default: false)
--- @field final boolean? (Default: false)
--- @field name string
--- @field generics GenericsTypesDefinitionParameter?
--- @field returnTypes (string[]|string)? (Default: void)

--- @class (exact) ConstructorStruct: ExecutableDefinition
---
--- @field __type__ 'ConstructorStruct'
---
--- @field __super_flag__ boolean Used internally to track calls to super while invoked.
--- @field class ClassStruct
--- @field parameters ParameterDefinition[]
--- @field super fun(o: any, ...) This function is called prior to the body function.
--- @field superInfo FunctionInfo The super function's information. (line-range and path)
--- @field body fun(o: any, ...) TODO: Rename as `body`.

--- @class (exact) ConstructorStructParameter: ParameterableInput
--- @field scope ClassScope? (Default: "package")
--- @field super fun(super: SuperTable, ...)? This function is called prior to the body function. If not defined, an attempt at `super()` is called. If not exists, an error occurs.
--- @field body fun(o: any, ...)? TODO: Rename as `body`.

--- @class (exact) ParameterDefinition
---
--- @field __type__ 'ParameterDefinition'
---
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field class ClassStruct
--- @field name string
--- @field types AllowedType[]

--- @class (exact) ParameterDefinitionParameter
--- @field types AllowedType[]?
--- @field type AllowedType?
--- @field name string?

-- MARK: - Module

--- @class VMExecutableModule: VMModule
--- @field defaultSuperFuncInfo FunctionInfo
local API = {};

--- @param struct StructDefinition
function API.createMiddleMethods(struct) end

--- @param classDef StructDefinition
--- @param name string
--- @param methods table<string, MethodStruct>
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

--- @param definition MethodStruct
---
--- @return string
function API.createSignature(definition) end

--- @param struct StructDefinition Used to cache results at class-level.
--- @param name string
--- @param methods table<string, MethodStruct>
--- @param args any[]
---
--- @return MethodStruct|nil
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

--- @param methods table<string, MethodStruct>
--- @param args any[]
---
--- @return MethodStruct|nil
function API.resolveMethodDeep(methods, args) end

--- @param self StructDefinition
--- @param name string
--- @param comb table<string, table<MethodStruct>>
---
--- @return table<string, table<string, MethodStruct>>
function API.combineAllMethods(self, name, comb) end

--- @param self ClassStruct|InterfaceStruct
function API.compileMethods(self) end

--- @param self StructDefinition
--- @param path string
--- @param line integer
---
--- @return MethodStruct|nil method
function API.getDeclaredMethodFromLine(self, path, line) end

--- @param self ClassStruct|InterfaceStruct
--- @param path string
--- @param line number
---
--- @return ExecutableDefinition
function API.getExecutableFromLine(self, path, line) end

--- @param func function?
---
--- @return FunctionInfo
function API.getExecutableInfo(func) end

--- @param classDef ClassStruct
function API.createMiddleConstructor(classDef) end

--- @param constructors ConstructorStruct[]
--- @param args table
---
--- @return ConstructorStruct|nil
function API.resolveConstructor(constructors, args) end

--- @param definition ConstructorStruct
---
--- @return string
function API.createSignature(definition) end

--- @param self Constructable
--- @param path string
--- @param line integer
---
--- @return ConstructorStruct|nil method
function API.getConstructorFromLine(self, path, line) end

--- @param paramsA ParameterDefinition[]
--- @param paramsB ParameterDefinition[]
---
--- @return boolean
function API.areCompatible(paramsA, paramsB) end

--- @param def ParameterableInput
---
--- @return ParameterDefinition[]
function API.compile(def) end

--- Used to fill-in for missing super function blocks for constructors.
---
--- @param super SuperTable
function API.defaultSuperFunc(super) end

--- @param struct ExecutableDefinition
--- @param args any[]
function API.checkArguments(struct, args) end
