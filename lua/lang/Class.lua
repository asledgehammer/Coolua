-- TODO: Create class object that wraps ClassStructDefinition.

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

-- private final ClassStructDefinition def { get; };
Class:addField({
    scope = 'private',
    final = true,
    name = 'definition',
    types = {
        'ClassStructDefinition',
        'InterfaceStructDefinition',
        'EnumStructDefinition'
    },

    get = { scope = 'public' }
});

-- private Class(String package, String name, ClassStructDefinition def)
Class:addConstructor({
    scope = 'private',
    parameters = {
        {
            name = 'def',
            types = {
                'ClassStructDefinition',
                'InterfaceStructDefinition',
                'EnumStructDefinition'
            }
        }
    },

    --- @param self Class
    super = function(self)
        self:super();
    end,

    --- @param self Class
    --- @param definition ClassStructDefinition
    body = function(self, definition)
        self.definition = definition;
        self.name = definition.name;
        self.__type__ = 'lua.lang.Class';
    end
});

Class:addMethod({
    scope = 'public',
    final = true,
    name = 'new',
    parameters = {
        { type = 'any...' }
    },
    returns = 'lua.lang.Object',
    body = function(self, ...)
        return self.definition.new(...);
    end
});

Class:addMethod({
    scope = 'public',
    final = true,
    name = 'isInterface',
    returns = 'boolean',
    body = function(self)
        return self.definition.__type__ == 'InterfaceStructDefinition';
    end
});

Class:addMethod({
    scope = 'public',
    final = true,
    name = 'isEnum',
    returns = 'boolean',
    body = function(self)
        return self.definition.__type__ == 'EnumStructDefinition';
    end
});

-- }

return Class:finalize();
