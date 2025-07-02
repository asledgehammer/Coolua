---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVM = require 'LVM';
local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local Dimension = require 'tests/Dimension';

local Rectangle = newClass({
    scope = 'public',
    superClass = Dimension
});

Rectangle:addField({
    scope = 'private',
    type = 'number',
    name = 'x',
    value = 0
});

Rectangle:addField({
    scope = 'private',
    type = 'number',
    name = 'y',
    value = 0
});

Rectangle:addConstructor({
        scope = 'public',
        parameters = {}
    },
    --- @param o Rectangle
    function(o)
        o:super();
        o.x = 0;
        o.y = 0;
    end
);

Rectangle:addConstructor({
        scope = 'public',
        parameters = {
            { name = 'x',      type = 'number' },
            { name = 'y',      type = 'number' },
            { name = 'width',  type = 'number' },
            { name = 'height', type = 'number' }
        }
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

Rectangle:addMethod({
        scope = 'public',
        name = 'getX',
        returns = 'number'
    },
    --- @param self Rectangle
    ---
    --- @return number x
    function(self) return self.x end
);

Rectangle:addMethod({
        scope = 'public',
        name = 'setX',
        returns = 'number'
    },
    --- @param self Rectangle
    --- @param x number
    function(self, x) self.x = x end
);

Rectangle:addMethod({
        scope = 'public',
        name = 'getY',
        returns = 'number'
    },
    --- @param self Rectangle
    ---
    --- @return number y
    function(self) return self.y end
);

Rectangle:addMethod({
        scope = 'public',
        name = 'setY',
        returns = 'number'
    },
    --- @param self Rectangle
    --- @param y number
    function(self, y) self.x = y end
);

Rectangle:addMethod({
        scope = 'public',
        name = 'toString',
        returns = 'string'
    },
    function(self)
        return self:getX() .. ', ' .. self:getY() .. ', ' .. self:super();
    end
);

Rectangle:finalize();

--- @cast Rectangle RectangleDefinition
return Rectangle;