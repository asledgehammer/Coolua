local PrintPlus = require 'cool/print';
local printf = PrintPlus.printf;

local cool = require 'cool';

-- BUILDER API ----------- --
local builder = cool.builder;
local import = builder.import;
local class = builder.class;
local static = builder.static;
local implements = builder.implements;
local constructor = builder.constructor;
local parameters = builder.parameters;
local field = builder.field;
local properties = builder.properties;
local get = builder.get;
local method = builder.method;
local getMethodTemplate = builder.getMethodTemplate;
local vararg = builder.vararg;

local public = builder.public;
local private = builder.private;
local final = builder.final;
-- ----------------------- --

--- @type RunnableDefinition
local Runnable = import 'lua.lang.Runnable';

local run = getMethodTemplate(Runnable, 'run');

--- @type TestDefinition
local Test;
Test = class 'Test' (public, final) {
    implements(Runnable),

    static {
        field 'silent' (public) {
            properties {
                type = 'boolean',
                value = false
            }
        }
    },

    field 'name' (private, final) {
        properties {
            type = 'string'
        },
        get {}
    },

    field 'body' (private, final) {
        properties {
            type = 'function'
        },
        get {}
    },

    field 'header' (private, final) {
        properties {
            type = 'string'
        }
    },

    constructor(public) {
        parameters {
            { name = 'name',     type = 'string' },
            { name = 'testFunc', type = 'function' }
        },
        --- @param name string
        --- @param testFunc fun(self: Test): boolean
        function(self, name, testFunc)
            self.name = name;
            self.header = string.format('[TEST][%s]', name);
            self.body = testFunc;
        end
    },

    run {
        function(self)
            local timeStarted, timeStopped = 0, 0;
            self:printf('Running..');
            local printedResult = false;
            local result = xpcall(function()
                timeStarted = os.clock();
                local retVal = self:getBody(self)(self);
                timeStopped = os.clock();
                return retVal;
            end, function(errMsg)
                self:printf('Result: FAILURE');
                if not Test.silent then
                    print(debug.traceback(errMsg, 2));
                end
                printedResult = true;
            end);

            if result then
                self:printf('Result: SUCCESS (%i ms)', (timeStopped - timeStarted) * 1000);
            elseif not printedResult then
                self:printf('Result: FAILURE');
            end
        end
    },

    method 'print' (public, vararg) {
        parameters {
            { name = 'args', type = 'any' }
        },

        --- @param self Test
        --- @param ... any?
        function(self, ...)
            if Test.silent then return end
            local args = { ... };
            local argLen = #args;
            if argLen == 0 then
                print(self.header);
                return;
            end
            --- Repackage first argument to have the header.
            args[1] = string.format('%s :: %s', self.header, tostring(args[1]));
            print(unpack(args));
        end
    },

    method 'printf' (public, vararg) {
        parameters {
            { name = 'message', type = 'string' },
            { name = 'args',    type = 'any' }
        },

        --- @param self Test
        --- @param message string?
        --- @param ... any?
        function(self, message, ...)
            if Test.silent then return end
            message = message or '';
            local combined = string.format('%s :: %s', self.header, message);
            printf(combined, ...);
        end
    }
};

return Test;
