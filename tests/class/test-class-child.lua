local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

-- Main files need to initialize LuaClass. --

--[[
  public class EnclosingClass {
    static class EnclosedClass {
    }
  }
--]]

-- MARK: - Enclosing

local EnclosingClass = newClass({
    pkg = 'tests',
    name = 'EnclosingClass',
    scope = 'public',
});

EnclosingClass:finalize();

-- MARK: - Enclosed

local EnclosedClass = newClass({
    name = 'EnclosedClass'
    -- Package level
}, EnclosingClass);

EnclosedClass:finalize();


print(EnclosingClass);
print(EnclosedClass);

print(EnclosingClass.EnclosedClass);
print(_G.tests.EnclosingClass.EnclosedClass);
