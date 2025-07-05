---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

--[[
  public class EnclosingClass {
    static class EnclosedClass {
    }
  }
--]]

-- MARK: - Enclosing

local EnclosingClass = newClass({
    pkg = 'org.example',
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

-- Return the top-level class.

return EnclosingClass;
