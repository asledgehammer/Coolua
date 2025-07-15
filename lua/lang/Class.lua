---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local vm = require 'cool/vm';
local import = vm.import;

-- Builder API ------------------------ --
local builder = require 'cool/builder';
local class = builder.class;
local field = builder.field;
local constructor = builder.constructor;
local method = builder.method;
local parameters = builder.parameters;
local properties = builder.properties;
local get = builder.get;
local returnTypes = builder.returnTypes;

local public = builder.public;
local private = builder.private;
local final = builder.final;
local vararg = builder.vararg;
-- ------------------------------------ --

local Object = import 'lua.lang.Object';
local Package = import 'lua.lang.Package';

-- NOTE: We create a placeholder of class and then define it because of references to itself.
local Class = import 'lua.lang.Class';

Class = class 'Class' (public, final) {

    field '__type__' (public, final) {
        properties {
            type = 'string',
            value = 'lua.lang.Class'
        }
    },

    field 'package' (private) {
        properties {
            type = Package
        },
        get(public) {
            function(self)
                if not self.package then
                    self.package = vm.getPackage(self.definition.pkg);
                end
                return self.package;
            end
        },
    },

    field 'name' (private, final) {
        properties {
            type = 'string'
        },
        get(public) {},
    },

    field 'struct' (private, final) {
        properties {
            types = {
                'ClassStruct',
                'InterfaceStruct',
                'EnumStruct'
            }
        },
        get(public) {}
    },

    constructor(private) {
        parameters {
            {
                name = 'def',
                types = { 'ClassStruct', 'InterfaceStruct', 'EnumStruct' }
            }
        },
        --- @param self Class
        --- @param definition ClassStruct
        body = function(self, definition)
            self.struct = definition;
            self.name = definition.name;
        end
    },

    method 'new' (public, final, vararg) {
        parameters({ type = 'any' }),
        returnTypes(Object),
        function(self, ...)
            return self.struct.new(...);
        end
    },

    method 'isAssignableFromType' (public) {
        parameters({ name = 'other', type = Class }),
        returnTypes('boolean'),
        --- @param self Class
        --- @param other Class|ClassStruct
        function(self, other)
            if not other then
                return false;
            elseif other.__type__ == 'ClassStruct' then
                return self:getStruct():isAssignableFromType(other);
            else
                return self:getStruct():isAssignableFromType(other:getStruct());
            end
        end
    },

    method 'isInterface' (public, final) {
        returnTypes('boolean'),
        function(self)
            return self.struct.__type__ == 'InterfaceStruct';
        end
    },

    method 'isEnum' (public, final) {
        returnTypes('boolean'),
        function(self)
            return self.struct.__type__ == 'EnumStruct';
        end
    }
};

return Class;
