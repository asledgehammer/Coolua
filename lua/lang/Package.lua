---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local VM = require 'cool/vm';
local newClass = VM.class.newClass;

require 'lua/lang/Object';

-- public final class Package {

local Package = newClass({
    -- Define these for debugging purposes.
    path = 'lua.lang',
    name = 'Package',

    scope = 'public',
    final = true
});

-- private final string path { get; }
Package:addField({
    scope = 'private',
    final = true,
    type = 'string',
    name = 'path',

    get = { scope = 'public' }
});

-- private final string name { get; }
Package:addField({
    scope = 'private',
    final = true,
    type = 'string',
    name = 'name',

    get = { scope = 'public' }
});

-- private final Class[] classes; { get; }
Package:addField({
    scope = 'private',
    final = true,
    type = 'table',
    name = 'classes',

    get = { scope = 'public' }
});

-- private Package(String path)
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

-- }

return Package:finalize();
