---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

require 'cool/vm';
local dump = require 'cool/dump'.any;

-- Builder API ------------------------ --
local builder = require 'cool/builder';
local class = builder.class;
local field = builder.field;
local constructor = builder.constructor;
local method = builder.method;
local parameters = builder.parameters;
local properties = builder.properties;
local get = builder.get;
local toString = builder.toString;

local public = builder.public;
local private = builder.private;
local final = builder.final;
-- ------------------------------------ --

--- @type StackTraceElementDefinition
local StackTraceElement = class 'StackTraceElement' (public) {
    
    field 'path' (private, final) {
        properties {
            type = 'string'
        },
        get(public) {}
    },
    
    field 'line' (private, final) {
        properties {
            type = 'number'
        },
        get(public) {}
    },
    
    field 'context' (private, final) {
        properties {
            type = 'string'
        },
        get(public) {}
    },
    
    field 'struct' (private, final) {
        properties {
            type = 'any'
        },
        get 'getCallingStruct' (public) {}
    },

    field 'element' (private, final) {
        properties {
            type = 'any'
        },
        get(public) {}
    },

    constructor(public) {
        parameters {
            { name = 'path',    type = 'string' },
            { name = 'line',    type = 'number' },
            { name = 'struct',   type = 'any' },
            { name = 'context', type = 'string' },
            { name = 'element', type = 'any' }
        },

        --- @param self StackTraceElement
        super = function(self)
            self:super();
        end,

        --- @param self StackTraceElement
        --- @param path string
        --- @param line number
        --- @param struct Struct
        --- @param context string
        --- @param element FieldStruct|ConstructorStruct|MethodStruct
        body = function(self, path, line, struct, context, element)
            self.path = path;
            self.line = line;
            self.struct = struct;
            self.context = context;
            self.element = element;
        end
    },

    toString {
        function(self)
            local path, line, context, element = self.path, self.line, self.context, self.element;
            if element then
                if element.__type__ == 'MethodStruct' then
                    local callSyntax;
                    if element.static then
                        callSyntax = '.';
                    else
                        callSyntax = ':';
                    end
                    return string.format('%s:%s: calling %s%s%s(%s)',
                        path,
                        line,
                        element.struct.name,
                        callSyntax,
                        element.name,
                        dump(element.parameters)
                    );
                elseif element.__type__ == 'ConstructorStruct' then
                    return string.format('%s:%s: calling %s.new(%s)',
                        path,
                        line,
                        element.struct.name,
                        dump(element.parameters)
                    );
                elseif element.__type__ == 'FieldStruct' then
                    if context == 'field-get' then
                        return string.format('%s:%s: accessing field %s.%s',
                            path,
                            line,
                            element.struct.name,
                            element.name
                        );
                    elseif context == 'field-set' then
                        return string.format('%s:%s: assigning field %s.%s',
                            path,
                            line,
                            element.struct.name,
                            element.name
                        );
                    end
                end
            end
            return string.format('%s:%s:',
                tostring(path),
                tostring(line)
            );
        end
    }
};

return StackTraceElement;
