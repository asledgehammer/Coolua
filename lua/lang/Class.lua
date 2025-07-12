---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local VM = require 'cool/vm';
local import = VM.import;

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
            type = 'string'
        },
        get(public) {
            function(self)
                if not self.package then
                    self.package = VM.getPackage(self.definition.pkg);
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

    field 'definition' (private, final) {
        properties {
            types = {
                'ClassStructDefinition',
                'InterfaceStructDefinition',
                'EnumStructDefinition'
            }
        },
        get(public) {}
    },

    constructor(private) {
        parameters {
            {
                name = 'def',
                types = { 'ClassStructDefinition', 'InterfaceStructDefinition', 'EnumStructDefinition' }
            }
        },
        --- @param self Class
        --- @param definition ClassStructDefinition
        body = function(self, definition)
            self.definition = definition;
            self.name = definition.name;
            -- self.package = VM.getPackage(definition.pkg);
        end
    },

    method 'new' (public, final) {
        parameters({ type = 'any...' }),
        returnTypes(Object),
        function(self, ...)
            return self.definition.new(...);
        end
    },

    method 'isAssignableFromType' (public) {
        parameters({ name = 'other', type = Class }),
        returnTypes('boolean'),
        --- @param self Class
        --- @param other Class|ClassStructDefinition
        function(self, other)
            if not other then
                return false;
            elseif other.__type__ == 'ClassStructDefinition' then
                return self:getDefinition():isAssignableFromType(other);
            else
                return self:getDefinition():isAssignableFromType(other:getDefinition());
            end
        end
    },

    method 'isInterface' (public, final) {
        returnTypes('boolean'),
        function(self)
            return self.definition.__type__ == 'InterfaceStructDefinition';
        end
    },

    method 'isEnum' (public, final) {
        returnTypes('boolean'),
        function(self)
            return self.definition.__type__ == 'EnumStructDefinition';
        end
    }
};

return Class;
