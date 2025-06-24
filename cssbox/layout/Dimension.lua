local LuaClass = require 'asledgehammer/util/LuaClass';
local ClassDefinition = LuaClass.ClassDefinition;

--- @type DimensionDefinition
local StrictDimension = ClassDefinition({
    package = 'cssbox.layout',
    scope = 'public',
    name = 'Dimension',
});

StrictDimension:addField({
    scope = 'private',
    type = 'number',
    name = 'width',
    value = 0
});

StrictDimension:addField({
    scope = 'private',
    type = 'number',
    name = 'height',
    value = 0
});

StrictDimension:addConstructor({
        { type = 'number', name = 'width' },
        { type = 'number', name = 'height' },
    },
    --- @param self Dimension
    --- @param width number
    --- @param height number
    function(self, width, height)
        self.width = width;
        self.height = height;
    end
);

StrictDimension:addMethod({ name = 'getWidth', returns = 'number' },
    --- @param self Dimension
    ---
    --- @return number width
    function(self)
        return self.width;
    end
);

StrictDimension:addMethod({ name = 'getHeight', returns = 'number' },
    --- @param self Dimension
    ---
    --- @return number height
    function(self) return self.height end
);

StrictDimension:addMethod({ name = 'toString', returns = 'string' },
    function(self)
        return tostring(self:getWidth()) .. ', ' .. tostring(self:getHeight());
    end
);

StrictDimension:addMethod({
        name = 'equals',
        parameters = {
            {
                name = 'other',
                type = 'any'
            }
        },
        returns = 'boolean'
    },
    --- @param self Dimension
    --- @param other any
    function(self, other)
        if not other.__type__ or self.__type__ ~= other.__type__ then
            return false;
        end
        --- @cast other Dimension
        return self:getWidth() == other:getWidth() and self:getHeight() == other:getHeight();
    end
);

StrictDimension:finalize();

return StrictDimension;
