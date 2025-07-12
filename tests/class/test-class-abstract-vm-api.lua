---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local cool = require 'cool';
local newClass = cool.newClass;

local AbstractClass = newClass {
    name = 'AbstractClass',
    scope = 'public',
    abstract = true,
};

AbstractClass:addAbstractMethod {
    scope = 'public',
    name = 'aMethod',
    returnTypes = 'void'
};

AbstractClass:finalize();

local ImplAbstractClass = newClass {
    name = 'ImplAbstractClass',
    scope = 'public',
    final = true,
    extends = AbstractClass
};

ImplAbstractClass:addMethod {
    scope = 'public',
    name = 'aMethod',
    returnTypes = 'void',

    body = function()
        print('Running from implemented abstract class!');
    end
};

ImplAbstractClass:finalize();

print('## TEST ##\n');

local o = ImplAbstractClass:new();
o:aMethod();
