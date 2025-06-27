local LuaClass = require 'lua.LuaClass';
local Class = LuaClass.ClassDefinition;

local Package = Class({
    scope = 'public',
    final = true,
});

Package:addField({
    scope = 'private',
    final = true,
    type = 'string',
    name = 'path'
});

Package:addField({
    scope = 'private',
    final = true,
    type = 'string',
    name = 'name'
});

Package:addField({
    scope = 'private',
    final = true,
    type = 'table',
    name = 'classes'
});

Package:addConstructor({
    scope = 'public'
},
function (self, path)
    local split = path:split('.');
    local name table.remove(split, #split);
    table.join(split, '.');
end)

return Package;
