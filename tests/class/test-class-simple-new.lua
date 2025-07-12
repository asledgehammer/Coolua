---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

require 'cool';

print('## TEST ##\n');

local Dimension = require 'tests/Dimension';

local dim1 = Dimension.new(5, 5);
local dim2 = Dimension.new(5, 4);
local dim3 = Dimension.new(5, 5);

print('ClassStructDefinition tests:\n');
print('\tClassStructDefinition:__tostring()', Dimension);
print('\tClassStructDefinition:__type__\t\t', Dimension.__type__);
print('\nInstance tests:\n');
print('\tobject:getWidth(): ', dim1:getWidth());
print('\tobject:toString(): ', dim1);
print('\tdim1 == dim2 (false): ', dim1 == dim2);
print('\tdim1 == dim3 (true): ', dim1 == dim3);

print('\tdim1:getClass() = ', dim1:getClass());
