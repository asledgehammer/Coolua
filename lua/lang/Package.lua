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
        scope = 'public',
        parameters = {
            { name = 'path', type = 'string' }
        }
    },
    function(self, path)
        local split = path:split('.');
        local name = table.remove(split, #split);
        local package = table.join(split, '.');
        self.name = name;
        self.path = package;
        self.classes = {};
    end
);

Package:finalize();

return Package;
