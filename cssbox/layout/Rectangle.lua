local LuaClass = require 'asledgehammer/util/LuaClass';
local ClassDefinition = LuaClass.ClassDefinition;

local Dimension = require 'cssbox/layout/Dimension';

--- @type RectangleDefinition
local Rectangle = ClassDefinition({
    package = 'cssbox.layout',
    name = 'Rectangle',
    superClass = Dimension
});

Rectangle:addField({ name = 'x', type = 'number', value = 0 });
Rectangle:addField({ name = 'y', type = 'number', value = 0 });

Rectangle:addConstructor(
--- @param o Rectangle
    function(o)
        o:super();
        o.x = 0;
        o.y = 0;
    end
);

Rectangle:addConstructor({
        { name = 'x',      type = 'number' },
        { name = 'y',      type = 'number' },
        { name = 'width',  type = 'number' },
        { name = 'height', type = 'number' }
    },
    --- @param self Rectangle
    --- @param x number
    --- @param y number
    --- @param width number
    --- @param height number
    function(self, x, y, width, height)
        self:super(width, height);
        self.x = x;
        self.y = y;
    end
);

Rectangle:addMethod({ name = 'getX', returns = 'number' },
    --- @param self Rectangle
    ---
    --- @return number x
    function(self) return self.x end
);

Rectangle:addMethod({ name = 'setX', returns = 'number' },
    --- @param self Rectangle
    --- @param x number
    function(self, x) self.x = x end
);

Rectangle:addMethod({ name = 'getY', returns = 'number' },
    --- @param self Rectangle
    ---
    --- @return number y
    function(self) return self.y end
);

Rectangle:addMethod({ name = 'setY', returns = 'number' },
    --- @param self Rectangle
    --- @param y number
    function(self, y) self.x = y end
);

Rectangle:addMethod({ name = 'toString', returns = 'string' },
    function(self)
        return self:getX() .. ', ' .. self:getY() .. ', ' .. self:super();
    end
);

Rectangle:finalize();

return Rectangle;
