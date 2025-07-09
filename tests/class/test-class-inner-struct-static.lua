---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'PrintPlus';
local printf = PrintPlus.printf;

local LuaClass = require 'LuaClass';
local dump     = require 'dump'.any;
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
  static {
    class 'EnclosedClass' (public) {

    }
  }
};

print('\n## TEST ##\n');

printf('enclosing class: %s', dump(EnclosingClass));
printf('encloded class: %s', dump(EnclosingClass.EnclosedClass));
printf('Explicit package-call to enclosed class: %s', dump(packages.tests.class.EnclosingClass.EnclosedClass));
