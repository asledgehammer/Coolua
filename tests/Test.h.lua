--- @meta

--- @class TestDefinition: ObjectDefinition
local TestDefinition = {};

--- @param name string
--- @param testFunc fun(self: Test): boolean
---
--- @return Test instance
function TestDefinition.new(name, testFunc) end

--- @class Test: Object, Runnable
--- @field header string
local Test = {};

--- @return boolean result
function Test.run() end

--- @param message string
--- @param ... any?
function Test:printf(message, ...) end

--- @param ... any?
function Test:print(...) end
