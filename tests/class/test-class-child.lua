---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';
local packages = LuaClass.packages;

local builder = LuaClass.builder;
local static = builder.static;
local class = builder.class;
local public = builder.public;

print('## TEST ##\n');

-- Main files need to initialize LuaClass. --

--- Java Example:
--- ```java
--- public class EnclosingClass {
---   public static class EnclosedClass {}
--- }
--- ```
local EnclosingClass = class 'EnclosingClass' (public) {
  static {
    class 'EnclosedClass' (public) {

    }
  }
};

print('\n## TEST ##\n');

print(EnclosingClass);
print(EnclosingClass.EnclosedClass);
print(packages);
print(packages.tests);
print(packages.tests.class);
print(packages.tests.class.EnclosingClass.EnclosedClass);
