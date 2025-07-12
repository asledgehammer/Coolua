---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local printf = PrintPlus.printf;

local cool = require 'cool';
local dump = require 'cool/dump'.any;
local packages = cool.packages;

print('## TEST ##\n');

-- Builder API ------------------------ --
local builder = cool.builder;
local static = builder.static;
local class = builder.class;

local public = builder.public;
-- ------------------------------------ --

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
