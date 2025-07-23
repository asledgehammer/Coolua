local cool = require 'cool';

-- BUILDER API ------------------ --
local builder = cool.builder;
local interface = builder.interface;
local method = builder.method;
local createMethodTemplate = builder.createMethodTemplate;
local public = builder.public;
-- ------------------------------ --

--- @type RunnableDefinition
local Runnable = interface 'Runnable' (public) {
    method 'run' {}
};

-- public void run() {}
createMethodTemplate(Runnable, 'run');

return Runnable;
