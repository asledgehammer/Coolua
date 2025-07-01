-- TODO: Create class object that wraps ClassDefinition.

local LVM = require 'LVM';
local newClass = LVM.class.newClass;

local Package = require 'lua/lang/Package';

-- public final class Class {
local Class = newClass({ scope = 'public', final = true });

-- private final String package { get; }
Class:addField({
    scope = 'private',
    final = true,
    name = 'package',
    type = 'string',

    get = { scope = 'public' }
});

-- private final String name { get; };
Class:addField({
    scope = 'private',
    final = true,
    name = 'name',
    type = 'string',

    get = { scope = 'public' }
});

-- private final ClassDefinition def { get; };
Class:addField({
    scope = 'private',
    final = true,
    name = 'def',
    type = 'ClassDefinition',

    get = { scope = 'public' }
});

-- private Class(String package, String name, ClassDefinition def)
Class:addConstructor({
        scope = 'private',
        parameters = {
            { name = 'package', type = Package },
            { name = 'name',    type = 'string' },
            { name = 'def',     type = 'ClassDefinition' }
        }
    },
    --- @param self Class
    --- @param package string
    --- @param name string
    --- @param def ClassDefinition
    function(self, package, name, def)
        self.package = package;
        self.name = name;
        self.def = def;
    end
);

-- }

return Class:finalize();
