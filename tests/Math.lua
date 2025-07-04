---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local Math = newClass({ scope = 'public' });

--- @cast Math MathDefinition

Math:addField({
    scope = 'public',
    static = true,
    final = true,
    name = 'PI',
    type = 'number',
    value = math.pi
})

Math:addConstructor({
    scope = 'public',
    parameters = {}
}, function() end);

Math:addStaticMethod({
        scope = 'public',
        final = true,
        name = 'getPI',
        returns = 'number'
    },
    function() return Math.PI end
);

Math:finalize();

return Math;
