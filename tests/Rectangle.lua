---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';
local import = LuaClass.import;

-- Builder API ------------------------ --
local builder = LuaClass.builder;
local class = builder.class;
local extends = builder.extends;
local static = builder.static;
local field = builder.field;
local constructor = builder.constructor;
local method = builder.method;
local toString = builder.toString;
local properties = builder.properties;
local parameters = builder.parameters;
local returns = builder.returns;
local get = builder.get;
local set = builder.set;
local private = builder.private;
local public = builder.public;
local final = builder.final;
-- ------------------------------------ --

local Dimension = import 'tests.Dimension';

--- @type RectangleDefinition
local Rectangle = class 'Rectangle' (public) {
    extends(Dimension),

    field 'x' (private) {
        properties {
            type = 'number',
            value = 0
        },
        get(public),
        set(public)
    },

    field 'y' (private) {
        properties {
            type = 'number',
            value = 0
        },
        get(public),
        set(public)
    },

    constructor(public) {

        parameters { 'number', 'number', 'number', 'number' },

        --- @param self Rectangle
        --- @param width number
        --- @param height number
        super = function(self, x, y, width, height)
            self:super(width, height);
        end,

        --- @param self Rectangle
        --- @param x number
        --- @param y number
        --- @param width number
        --- @param height number
        body = function(self, x, y, width, height)
            self.x = x;
            self.y = y;
        end

    },

    toString {
        --- @param self Rectangle
        function(self)
            return string.format(
                'Rectangle(x = %.4f, y = %.4f, width = %.4f, height = %.4f)',
                self:getX(), self:getY(), self:getWidth(), self:getHeight()
            );
        end
    },

    static {
        method 'sayHello' (public, final) {
            returns 'void',

            function()
                print('Hello, World!');
            end
        }
    },
};

return Rectangle;
