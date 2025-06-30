local LVM = require 'LVM';
local newClass = LVM.class.newClass;

local Package = newClass({
    scope = 'public',
    final = true,
});

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
