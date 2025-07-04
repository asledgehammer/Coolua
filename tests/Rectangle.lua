---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';
local newClass = LuaClass.newClass;

local Dimension = require 'tests/Dimension';

local Rectangle = newClass({
    scope = 'public',
    extends = Dimension
});

Rectangle:addField {

    scope = 'private',
    type = 'number',
    name = 'x',
    value = 0,

    get = { scope = 'public' },
    set = { scope = 'public' }
};

Rectangle:addField {

    scope = 'private',
    type = 'number',
    name = 'y',
    value = 0,

    get = { scope = 'public' },
    set = { scope = 'public' }
};

Rectangle:addConstructor {
    scope = 'public',

    --- @param o Rectangle
    body = function(o)
        o:super();
        o.x = 0;
        o.y = 0;
    end
};

Rectangle:addConstructor {

    scope = 'public',

    parameters = {
        { name = 'x',      type = 'number' },
        { name = 'y',      type = 'number' },
        { name = 'width',  type = 'number' },
        { name = 'height', type = 'number' }
    },

    --- @param super SuperTable
    --- @param width number
    --- @param height number
    super = function(super, _, _, width, height)
        super(width, height);
    end,

    --- @param self Rectangle
    --- @param x number
    --- @param y number
    --- @param width number
    --- @param height number
    body = function(self, x, y, width, height)
        self:super(width, height);
        self.x = x;
        self.y = y;
    end

};

Rectangle:addMethod {

    scope = 'public',
    name = 'toString',
    returns = 'string',

    --- @param self Rectangle
    body = function(self)
        return self:getX() .. ', ' .. self:getY() .. ', ' .. self:super();
    end
};

Rectangle:finalize();

--- @cast Rectangle RectangleDefinition
return Rectangle;
