---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'lua/LuaClass';
local Class = LuaClass.ClassDefinition;

local Math = Class({ scope = 'public' });

Math:addConstructor({
    scope = 'public',
    parameters = {}
}, function() end);

Math:addMethod({
        scope = 'public',
        static = true,
        final = true,
        name = 'getPI',
        parameters = {},
        returns = 'number'
    },
    function() return math.pi end
);

Math:finalize();

return Math;
