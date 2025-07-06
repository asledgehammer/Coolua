local dump = require 'dump';

local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;
local isArray = LVMUtils.isArray;

-- Builder API ------------------------ --
local builder = require 'LuaClassBuilder';
local class = builder.class;
local extends = builder.extends;
local implements = builder.implements;
local static = builder.static;
local field = builder.field;
local constructor = builder.constructor;
local method = builder.method;
local equals = builder.equals;
local toString = builder.toString;
local properties = builder.properties;
local parameters = builder.parameters;
local returns = builder.returns;
local get = builder.get;
local set = builder.set;
local private = builder.private;
local protected = builder.protected;
local public = builder.public;
local final = builder.final;
local abstract = builder.abstract;
-- ------------------------------------ --

local Dimension = class 'Dimension' (public) {

    field 'width' (private) {
        properties {
            type = 'number',
            value = 0
        },
        get(public) {
            function(self)
                return self.width;
            end
        },
        set(public)
    },

    field 'height' (private) {
        properties {
            type = 'number',
            value = 0
        },
        get(public),
        set(public),
    },

    constructor(public) {

        parameters = {
            { name = 'width',  type = 'number' },
            { name = 'height', type = 'number' }
        },

        --- @param self Dimension
        --- @param width number
        --- @param height number
        super = function(self, width, height)
            self:super();
        end,

        --- @param self Dimension
        --- @param width number
        --- @param height number
        body = function(self, width, height)
            self.width = width;
            self.height = height;
        end

    },

    equals {
        --- @param self Dimension
        --- @param other Object
        function(self, other)
            if not other or self:instanceOf(other:getClass()) then
                return false;
            end
            --- @cast other Dimension
            return self:getWidth() == other:getWidth() and self:getHeight() == other:getHeight();
        end
    },

    toString {
        --- @param self Dimension
        function(self)
            return string.format('Dimension(width = %.4f, height = %.4f)',
                self:getWidth(), self:getHeight()
            );
        end
    }
};

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
            properties {
                returns 'void',
            },

            body = function()
                print('Hello, World!');
            end
        }
    },
};

print(dump.any(Dimension.fields));
