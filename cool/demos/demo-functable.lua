-- Create a metatable
local mt = {}

-- Define the __call metamethod
mt.__call = function(t, ...)
  print("Table called!")
  -- Perform actions when the table is called
end

-- Define the __index metamethod
mt.__index = function(t, key)
  print("Attempting to index with key:", key)
  -- Customize index lookup behavior
  return "Default value"
end

-- Create a table and set its metatable
local my_table = {}
setmetatable(my_table, mt)

-- Call the table (triggers __call)
my_table() -- Output: Table called!

-- Index the table (triggers __index for non-existent keys)
print(my_table.some_key) -- Output: Attempting to index with key: some_key, Default value