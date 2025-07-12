---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';

-- Builder API ------------------------ --
local builder = cool.builder;
local class = builder.class;
local extends = builder.extends;
local method = builder.method;
local parameters = builder.parameters;
local returns = builder.returns;
local createMethodTemplate = builder.createMethodTemplate;

local public = builder.public;
local abstract = builder.abstract;
-- ------------------------------------ --

-- Create a method template for the abstract method that'll be implemented.
local aMethod = createMethodTemplate('aMethod', { public }, {
    parameters {},
    returns 'void'
});

local AbstractClass = class 'AbstractClass' (abstract) {
    method 'aMethod' (public, abstract) {
        returns 'void'
    }
};

local ImplementedClass = class 'ImplementedClass' (abstract) {
    extends(AbstractClass),
    
    aMethod {
        function()
            print('Running from implemented abstract class!');
        end
    }
};

print('## TEST ##\n');

local o = ImplementedClass:new();
o:aMethod();
