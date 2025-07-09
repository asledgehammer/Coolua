---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local dump = require 'dump'.any;

local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local builder = LuaClass.builder;
local static = builder.static;
local class = builder.class;
local public = builder.public;

-- Main files need to initialize LuaClass. --

--- Java Example:
--- ```java
--- public class EnclosingClass {
---   public static class EnclosedClass {}
--- }
--- ```
local EnclosingClass = class 'EnclosingClass' (public) {
  static {
    class 'EnclosedClass' (public) {}
  }
};

print(EnclosingClass);
print(EnclosingClass.EnclosedClass);
-- print('_G.tests', dump(_G.tests));
-- print(_G.tests.EnclosingClass.EnclosedClass);
