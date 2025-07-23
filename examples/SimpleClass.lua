-- MARK: - Imports

local cool = require 'cool';

-- Builder API ------------------------ --
local builder = cool.builder;
local import = builder.import;
local class = builder.class;
local interface = builder.interface;
local extends = builder.extends;
local implements = builder.implements;
local static = builder.static;
local field = builder.field;
local constructor = builder.constructor;
local method = builder.method;
local properties = builder.properties;
local parameters = builder.parameters;
local returnTypes = builder.returnTypes;
local get = builder.get;
local set = builder.set;
local createMethodTemplate = builder.createMethodTemplate;
local getMethodTemplate = builder.getMethodTemplate;
local equals = builder.equals;
local toString = builder.toString;
local private = builder.private;
local protected = builder.protected;
local public = builder.public;
local final = builder.final;
local abstract = builder.abstract;
local vararg = builder.vararg;
-- ------------------------------------ --

-- MARK: - Builder API

-- Create the class.
local SimpleClassBuilder = class 'SimpleClassBuilder' {
    constructor {
        function()
            print('Hello from Builder!');
        end
    }
};

-- Create an instance of the class.
local object = SimpleClassBuilder.new();
print(object);

-- MARK: - Basic API

-- Create the class.
local SimpleClassBasic = cool.newClass {
    name = 'SimpleClassBasic'
};

SimpleClassBasic:addConstructor {
    body = function()
        print('Hello from Basic!');
    end
};

-- Create an instance of the class.
local objectBasic = SimpleClassBasic.new();
print(objectBasic);
