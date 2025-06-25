local Dimension = require 'cssbox/layout/Dimension';

local dim1 = Dimension.new(5, 5);
local dim2 = Dimension.new(5, 4);
local dim3 = Dimension.new(5, 5);

print('ClassDefinition tests:\n');
print('\tClassDefinition:__tostring()', Dimension);
print('\tClassDefinition:__type__\t\t', Dimension.__type__);
print('\nInstance tests:\n');
print('\tobject:getWidth(): ', dim1:getWidth());
print('\tobject:toString(): ', dim1);
print('\tdim1 == dim2 (false): ', dim1 == dim2);
print('\tdim1 == dim3  (true): ', dim1 == dim3);
