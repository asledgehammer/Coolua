local PrintPlus = require 'cool/print';
local printf = PrintPlus.printf;
local errorf = PrintPlus.errorf;

local dump = require 'cool/dump'.any;
local cool = require 'cool';

-- BUILDER API ----------- --
local builder = cool.builder;
local import = builder.import;
local class = builder.class;
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
local Test = class 'Test' (public, final) {
    implements(Runnable),

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
            self:print();
            local result = xpcall(function()
                timeStarted = os.clock();
                local retVal = self:getBody(self)(self);
                timeStopped = os.clock();
                return retVal;
            end, function(errMsg)
                self:print();
                self:printf('Result: FAILURE');
                print(debug.traceback(errMsg, 2));
            end);

            if result then
                self:print();
                self:printf('Result: SUCCESS (%i ms)', (timeStopped - timeStarted) * 1000);
            else
                self:print();
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
        function(self, message, ...)
            local args = { ... };
            local argLen = #args;
            if argLen == 0 then
                print(self.header);
                return;
            end
            --- Repackage first argument to have the header.
            args[1] = string.format('%s :: %s', self.header, args[1]);
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
            message = message or '';
            local combined = string.format('%s :: %s', self.header, message);
            printf(combined, ...);
        end
    }
};

return Test;
