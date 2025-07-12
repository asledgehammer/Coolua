---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local vm = require 'cool/vm';
local newClass = vm.class.newClass;

vm.flags.ignorePushPopContext = true;

local Object = newClass({

    -- Define these for debugging purposes.
    pkg = 'lua.lang',
    name = 'Object',

    scope = 'public'
});

vm.flags.ignorePushPopContext = false;

Object:addConstructor({
    scope = 'public',

    --- @param self Class
    super = function(self)
        print('Invoke Object super');
        self:super();
    end,

    body = function()

    end
});

Object:addMethod({
    scope = 'public',
    final = true,
    name = 'instanceOf',
    parameters = {
        { name = 'class', type = 'lua.lang.Class' }
    },
    returnTypes = 'boolean',

    --- @param self Object
    --- @param class Class
    ---
    --- @return boolean isAssignable
    body = function(self, class)
        return class:isAssignableFromType(self:getClass());
    end
});

Object:addMethod({
    scope = 'public',
    name = 'equals',
    parameters = {
        { name = 'other', type = 'any' }
    },
    returnTypes = 'boolean',

    --- @param self Object
    --- @param other Object
    ---
    --- @return boolean
    body = function(self, other)
        return self == other;
    end
});

Object:addMethod({
    scope = 'public',
    name = 'toString',
    returnTypes = 'string',

    --- @param self Object
    ---
    --- @return string
    body = function(self)
        return 'Class: ' .. tostring(self.__type__);
    end
});

Object:addMethod({
    scope = 'public',
    final = true,
    name = 'getClass',
    returnTypes = 'lua.lang.Class',

    --- @param self Object
    ---
    --- @return Class class
    body = function(self)
        return self.__class__;
    end
});

--- @cast Object ObjectDefinition

return Object:finalize();
