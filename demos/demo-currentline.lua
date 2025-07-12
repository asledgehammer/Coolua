--- @param level integer
--- 
--- @return integer currentLine
local function getCurrentLine(level)
    return debug.getinfo(level, 'l').currentline;
end

print("Current line: ", getCurrentLine(2));
