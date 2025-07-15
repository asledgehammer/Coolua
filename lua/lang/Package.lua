---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local vm = require 'cool/vm';
local import = vm.import;
local newClass = vm.class.newClass;

import 'lua.lang.Object';

local Package = newClass({ scope = 'public', final = true });

Package:addField({
    scope = 'private',
    final = true,
    type = 'string',
    name = 'path',

    get = { scope = 'public' }
});

Package:addField({
    scope = 'private',
    final = true,
    type = 'string',
    name = 'name',

    get = { scope = 'public' }
});

Package:addField({
    scope = 'private',
    final = true,
    type = 'table',
    name = 'classes',

    get = { scope = 'public' }
});

Package:addConstructor({
    scope = 'private',
    parameters = {
        { name = 'path', type = 'string' }
    },

    --- @param self Package
    super = function(self)
        self:super();
    end,

    --- @param self Package
    --- @param path string
    body = function(self, path)
        local split = path:split('.');
        local name = table.remove(split, #split);
        local pkg = table.concat(split, '.');
        self.name = name;
        self.path = pkg;
        self.classes = {};
    end
});

Package:finalize();

return Package;
