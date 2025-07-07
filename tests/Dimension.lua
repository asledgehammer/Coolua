---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LuaClass = require 'LuaClass';

-- Builder API ------------------------ --
local builder = LuaClass.builder;
local class = builder.class;
local field = builder.field;
local constructor = builder.constructor;
local equals = builder.equals;
local toString = builder.toString;
local properties = builder.properties;
local parameters = builder.parameters;
local get = builder.get;
local set = builder.set;
local private = builder.private;
local public = builder.public;
-- ------------------------------------ --

--- @type DimensionDefinition
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

        parameters {
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
        --- 
        --- @return boolean equalsOther
        function(self, other)
            if not other or not self:instanceOf(other:getClass()) then
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

return Dimension;
