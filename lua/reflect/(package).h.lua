--- @meta

-- (Set the root package definition)

--- @class _G
--- @field lua Package_lua

--- (Add Sub-Packages)
--- @class (exact) Package_lua
--- @field lang Package_lua_lang
--- @field reflect Package_lua_reflect

-- MARK: - Packages

--- @class (exact) Package_lua_lang
--- @field Class ClassDefinition
--- @field Object ObjectDefinition
--- @field Package PackageDefinition
--- @field StackTraceElement StackTraceElementDefinition

--- @class (exact) Package_lua_reflect
--- @