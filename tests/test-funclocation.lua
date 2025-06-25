-- Define a function
function my_function()
    -- Some code...
end

-- Get information about the function
local func_info = debug.getinfo(my_function)

-- Print the line number where it was defined
print("Function 'my_function' is defined on line:", func_info.lastlinedefined)

--- @param func function
--- 
--- @return integer lineStart, integer lineEnd
local function getLines(func)
    local info = debug.getinfo(func);
    return info.linedefined, info.lastlinedefined;
end
