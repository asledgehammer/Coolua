---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVM = require 'LVM';
local newClass = LVM.class.newClass;

-- ! NOTE: All class objects for fields and parameter types are inferred using strings to prevent LVM-loading errors. !

LVM.flags.ignorePushPopContext = true;

--- @type ObjectDefinition
local Object = newClass({

    -- Define these for debugging purposes.
    package = 'lua.lang',
    name = 'Object',

    scope = 'public'
});

LVM.flags.ignorePushPopContext = false;

Object:addConstructor({
    scope = 'public',
    parameters = {}
});

Object:addMethod({
        scope = 'public',
        final = true,
        name = 'instanceOf',
        parameters = {
            { name = 'class', type = 'lua.lang.Class' }
        },
        returns = 'boolean'
    },
    --- @param self Object
    --- @param class Class
    ---
    --- @return boolean isAssignable
    function(self, class)
        return class:isAssignableFromType(self:getClass());
    end
);

Object:addMethod({
        scope = 'public',
        name = 'equals',
        parameters = {
            { name = 'other', type = 'any' }
        },
        returns = 'boolean'
    },
    --- @param self Object
    --- @param other Object
    ---
    --- @return boolean
    function(self, other)
        return self == other;
    end
);

Object:addMethod({
        scope = 'public',
        name = 'toString',
        returns = 'string'
    },
    --- @param self Object
    ---
    --- @return string
    function(self)
        return 'LuaClass: ' .. self.__type__;
    end
);

Object:addMethod({
        scope = 'public',
        final = true,
        name = 'getClass',
        returns = 'lua.lang.Class'
    },
    --- @param self Object
    ---
    --- @return Class class
    function(self)
        return self.__class__;
    end
);

return Object:finalize();
