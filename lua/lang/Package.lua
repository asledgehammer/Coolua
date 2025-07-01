local LVM = require 'LVM';
local newClass = LVM.class.newClass;

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

-- }

return Package:finalize();
