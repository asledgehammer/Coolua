---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local VM = require 'cool/vm';
local import = VM.import;
local newClass = VM.class.newClass;

local Object = import 'lua.lang.Object';
local Package = import 'lua.lang.Package';

-- public final class Class {
local Class = newClass({
    -- Define these for debugging purposes.
    -- path = 'lua.lang',
    -- name = 'Class',

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
    returnTypes = Object,
    body = function(self, ...)
        return self.definition.new(...);
    end
});

Class:addMethod({
    scope = 'public',
    name = 'isAssignableFromType',
    parameters = {
        { name = 'other', type = Class }
    },
    returnTypes = 'boolean',

    --- @param self Class
    --- @param other Class|ClassStructDefinition
    body = function(self, other)
        if not other then
            return false;
        elseif other.__type__ == 'ClassStructDefinition' then
            return self:getDefinition():isAssignableFromType(other);
        else
            return self:getDefinition():isAssignableFromType(other:getDefinition());
        end
    end
});

Class:addMethod({
    scope = 'public',
    final = true,
    name = 'isInterface',
    returnTypes = 'boolean',
    body = function(self)
        return self.definition.__type__ == 'InterfaceStructDefinition';
    end
});

Class:addMethod({
    scope = 'public',
    final = true,
    name = 'isEnum',
    returnTypes = 'boolean',
    body = function(self)
        return self.definition.__type__ == 'EnumStructDefinition';
    end
});

-- }

return Class:finalize();
