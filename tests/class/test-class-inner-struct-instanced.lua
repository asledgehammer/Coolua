---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';
local dump     = require 'dump'
local packages = LuaClass.packages;

print('## TEST ##\n');

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
  class 'EnclosedClass' (public) {

  }
};

print('\n## TEST ##\n');

local ins = EnclosingClass.new();

print(ins);
print(ins.EnclosedClass);
print(EnclosingClass.EnclosedClass);

