--- @param level integer
--- 
--- @return integer currentLine
local function getCurrentLine(level)
    return debug.getInfo(level, 'l').currentline;
end

print("Current line: ", getCurrentLine(2));
