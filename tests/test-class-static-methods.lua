local Math = require 'org/example/Math';

local test = true;
if test then
    local math = Math.new();
    print('(class) PI = ' .. tostring(math.getPI()));
    print('(static from instance) PI = ' .. tostring(math.PI));
end
