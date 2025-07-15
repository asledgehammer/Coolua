--- @meta

---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- MARK: - Struct

--- @class (exact) Parameterable
---
--- @field parameters ParameterStruct[]
--- @field vararg boolean If true, the executable's last paramater is a vararg.

--- @class (exact) ParameterableInput
---
--- @field parameters ParameterStruct[]? (Default: No parameters)
--- @field vararg boolean? (Default: false) If true, the executable's last paramater is a vararg.

--- @class (exact) ExecutableStruct: Parameterable
---
--- @field __type__ string
---
--- @field signature string The identity of the method. used for comparison.
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field body function?
--- @field bodyInfo FunctionInfo The function's information. (line-range and path)
--- @field scope ClassScope

--- @class (exact) MethodStruct: ExecutableStruct
---
--- @field __type__ 'MethodStruct'
---
--- @field struct Struct
--- @field name string
--- @field super MethodStruct? (Internally assigned. If none, this is nil)
--- @field parameters ParameterStruct[]
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

--- @class (exact) MethodStructInput: ParameterableInput
---
--- @field scope ClassScope? (Default: public)
--- @field static boolean? (Default: false)
--- @field final boolean? (Default: false)
--- @field name string
--- @field returnTypes (string[]|string)? (Default: void)

--- @class (exact) StaticMethodStructInput
---
--- @field scope ClassScope? (Default: package)
--- @field name string
--- @field parameters ParameterStructInput[]? (Default: no parameters)
--- @field returnTypes AllowedType[]|AllowedType
--- @field body function?

--- @class (exact) ConstructorStruct: ExecutableStruct
---
--- @field __type__ 'ConstructorStruct'
---
--- @field __super_flag__ boolean Used internally to track calls to super while invoked.
--- @field struct ClassStruct
--- @field parameters ParameterStruct[]
--- @field super fun(o: any, ...) This function is called prior to the body function.
--- @field superInfo FunctionInfo The super function's information. (line-range and path)
--- @field body fun(o: any, ...) TODO: Rename as `body`.

--- @class (exact) ConstructorStructInput: ParameterableInput
--- @field scope ClassScope? (Default: "package")
--- @field super fun(super: SuperTable, ...)? This function is called prior to the body function. If not defined, an attempt at `super()` is called. If not exists, an error occurs.
--- @field body fun(o: any, ...)? TODO: Rename as `body`.

--- @class (exact) ParameterStruct
---
--- @field __type__ 'ParameterStruct'
---
--- @field audited boolean If true, the struct is audited and verified to be valid.
--- @field struct ClassStruct
--- @field name string
--- @field types AllowedType[]

--- @class (exact) ParameterStructInput
--- @field types AllowedType[]?
--- @field type AllowedType?
--- @field name string?

-- MARK: - Module

--- @class VMExecutableModule: VMModule
--- @field defaultSuperFuncInfo FunctionInfo
local API = {};

--- @param struct Struct
function API.createMiddleMethods(struct) end

--- @param classDef Struct
--- @param name string
--- @param methods table<string, MethodStruct>
---
--- @return fun(o: ClassInstance, ...): (any?)
function API.createMiddleMethod(classDef, name, methods) end

--- @param classDef Methodable
---
--- @return string[] methodNames
function API.getDeclaredMethodNames(classDef, array) end

--- @param classDef Struct
--- @param methodNames string[]?
---
--- @return string[] methodNames
function API.getMethodNames(classDef, methodNames) end

--- @param definition MethodStruct
---
--- @return string
function API.createSignature(definition) end

--- @param struct Struct Used to cache results at class-level.
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

--- @param self Struct
--- @param name string
--- @param comb table<string, table<MethodStruct>>
---
--- @return table<string, table<string, MethodStruct>>
function API.combineAllMethods(self, name, comb) end

--- @param self ClassStruct|InterfaceStruct
function API.compileMethods(self) end

--- @param self Struct
--- @param path string
--- @param line integer
---
--- @return MethodStruct|nil method
function API.getDeclaredMethodFromLine(self, path, line) end

--- @param self ClassStruct|InterfaceStruct
--- @param path string
--- @param line number
---
--- @return ExecutableStruct
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

--- @param paramsA ParameterStruct[]
--- @param paramsB ParameterStruct[]
---
--- @return boolean
function API.areCompatible(paramsA, paramsB) end

--- @param def ParameterableInput
---
--- @return ParameterStruct[]
function API.compile(def) end

--- Used to fill-in for missing super function blocks for constructors.
---
--- @param super SuperTable
function API.defaultSuperFunc(super) end

--- @param struct ExecutableStruct
--- @param args any[]
function API.checkArguments(struct, args) end
