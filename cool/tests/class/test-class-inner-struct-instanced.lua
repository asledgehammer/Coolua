---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';
local dump = require 'cool/dump';
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
  class 'EnclosedClass' (public) {
  }
};

print('\n## TEST ##\n');

local ins = EnclosingClass.new();

print(ins);
print(ins.EnclosedClass);
print(EnclosingClass.EnclosedClass);
