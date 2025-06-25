---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local DebugUtils = {};

if _G['ZombRandFloat'] then -- Project Zomboid Kahlua Environment.

else                        -- Native Lua Environment.
    --- @class CallInfo
    ---
    --- @field currentLine integer
    --- @field path string

    -- MARK: - General

    local function modifyPath(path)
        path = string.gsub(path, '\\', '/');
        path = string.gsub(path, '.lua', '');
        path = string.gsub(path, './', '', 1);
        path = string.gsub(path, '/', '.');
        return path;
    end

    --- @param levelOrFunc function|integer
    --- @param isClassPath boolean? (Default: false) If true, the path is transformed to `ClassDefinition.path` syntax.
    ---
    --- @return string path
    function DebugUtils.getPath(levelOrFunc, isClassPath)
        local dS = debug.getinfo(levelOrFunc, "S");
        if isClassPath then return modifyPath(dS.short_src) end
        return dS.short_src;
    end

    --- @param levelOrFunc function|integer
    ---
    --- @return integer line
    function DebugUtils.getCurrentLine(levelOrFunc)
        return debug.getinfo(levelOrFunc, 'l').currentline;
    end

    --- @param level integer
    --- @param isClassPath boolean? (Default: false) If true, the path is transformed to `ClassDefinition.path` syntax.
    ---
    --- @return CallInfo
    function DebugUtils.getCallInfo(level, isClassPath)
        local level_p1 = level + 1;
        return {
            currentLine = DebugUtils.getCurrentLine(level_p1),
            path = DebugUtils.getPath(level_p1, isClassPath),
        };
    end

    -- MARK: - Func Specific

    --- @class FunctionInfo
    ---
    --- @field path string
    --- @field start integer
    --- @field stop integer

    --- @param func function
    ---
    --- @return number start, number stop
    function DebugUtils.getFuncRange(func)
        local info = debug.getinfo(func, 'S');
        return info.linedefined, info.lastlinedefined;
    end

    --- @param func function
    --- @param isClassPath boolean? (Default: false) If true, the path is transformed to `ClassDefinition.path` syntax.
    --- @return FunctionInfo
    function DebugUtils.getFuncInfo(func, isClassPath)
        local path = DebugUtils.getPath(func, isClassPath);
        local start, stop = DebugUtils.getFuncRange(func);
        return {
            path = path,
            start = start,
            stop = stop
        };
    end
end

return DebugUtils;
