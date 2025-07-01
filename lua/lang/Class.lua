-- TODO: Create class object that wraps ClassDefinition.

local LVM = require 'LVM';
local newClass = LVM.class.newClass;

require 'lua/lang/Object';

local Package = require 'lua/lang/Package';

-- public final class Class {
local Class = newClass({
    -- Define these for debugging purposes.
    path = 'lua.lang',
    name = 'Class',

    scope = 'public',
    final = true
});

-- private final String __type__;
Class:addField({
    scope = 'public',
    name = '__type__',
    type = 'string',
});

-- private final String package { get; }
Class:addField({
    scope = 'private',
    name = 'package',
    type = Package,

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
    name = 'definition',
    type = 'LVMClassDefinition',

    get = { scope = 'public' }
});

-- private Class(String package, String name, ClassDefinition def)
Class:addConstructor({
        scope = 'private',
        parameters = {
            { name = 'def', type = 'ClassDefinition' }
        }
    },
    --- @param self Class
    --- @param definition ClassDefinition
    function(self, definition)
        self.definition = definition;
        self.name = definition.name;
        self.__type__ = 'lua.lang.Class';
    end
);

Class:addMethod({
        scope = 'public',
        final = true,
        name = 'new',
        parameters = {
            { type = 'any...' }
        },
        returns = 'lua.lang.Object'
    },
    function(self, ...)
        return self.definition.new(...);
    end
);

-- }

return Class:finalize();
