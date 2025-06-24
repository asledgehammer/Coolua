local ClassDefinition = require 'asledgehammer/util/ClassDefinition';

--- @type DimensionDefinition
local Object = ClassDefinition({
    package = 'lua.lang',
    final = false,
    scope = 'public',
    name = 'Object',
});

Object:addConstructor(
    function(o)
    end
);

Object:addMethod({
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
    function(self, class)
        return class:isAssignableFromType(self:getClass());
    end
);

Object:addMethod({
    name = 'equals',
    parameters = {
        {
            name = 'other',
            type = 'any'
        }
    },
    returns = 'boolean'
}, function(self, other)
    return self == other;
end);

Object:addMethod({
    name = 'toString',
    returns = 'string'
}, function(self)
    return 'LuaClass: ' .. self.path;
end);

Object:addMethod({
    final = true,
    name = 'getClass',
    returns = 'ClassDefinition'
}, function(self)
    return self.__class;
end);

Object:finalize();

return Object;
