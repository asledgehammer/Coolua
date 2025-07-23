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

-- Create the super-class.
local SuperClass = class 'SuperClass' {
    constructor {
        function()
            print('Hello from SuperClass!');
        end
    }
};

-- Create the class.
local SubClass = class 'SubClass' {
    -- Extend the super-class using this API.
    extends(SuperClass),

    constructor {
        function()
            print('Hello from SubClass!');
        end
    }
};

-- Print out the class structs, showing that the sub-class extends the super-class.
print(SuperClass);
print(SubClass);

-- Create an instance of the class.
SubClass.new();

-- MARK: - Basic API

local SuperClass = cool.newClass {
    name = 'SuperClass'
};

SuperClass:addConstructor {
    body = function()
        print('Hello from SuperClass!');
    end
};

local SubClass = cool.newClass {
    name = 'SubClass',
    extends = SuperClass,
};

SubClass:addConstructor {
    body = function()
        print('Hello from SubClass!');
    end
};

-- Print out the class structs, showing that the sub-class extends the super-class.
print(SuperClass);
print(SubClass);

-- Create an instance of the class.
SubClass.new();
