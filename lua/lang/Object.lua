---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVM = require 'LVM';
local newClass = LVM.newClass;

--- @type ObjectDefinition
local Object = newClass({ scope = 'public' });

-- MARK: - Constructors

Object:addConstructor({
        scope = 'public',
        parameters = {}
    },
    function() end
);

-- MARK: - instanceOf()

Object:addMethod({
        scope = 'public',
        final = true,
        name = 'instanceOf',
        parameters = {
            {
                name = 'class',
                type = 'ClassDefinition'
            }
        },
        returns = 'boolean'
    },
    --- @param self Object
    --- @param class ClassDefinition
    ---
    --- @return boolean isAssignable
    function(self, class)
        return class:isAssignableFromType(self:getClass());
    end
);

-- MARK: - equals()

Object:addMethod({
        scope = 'public',
        name = 'equals',
        parameters = {
            {
                name = 'other',
                type = 'any'
            }
        },
        returns = 'boolean'
    },
    --- @param self Object
    --- @param other Object
    ---
    --- @return boolean
    function(self, other)
        print('Object.equals');
        return self == other;
    end
);

-- MARK: - toString()

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

-- MARK: - getClass()

Object:addMethod({
        scope = 'public',
        final = true,
        name = 'getClass',
        returns = 'ClassDefinition'
    },
    --- @param self Object
    ---
    --- @return ClassDefinition classDef
    function(self)
        return self.__class__;
    end
);

Object:finalize();

return Object;
