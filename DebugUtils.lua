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

    --- @param path string
    --- @param rootPath string?
    ---
    --- @return string
    local function modifyPath(path, rootPath)
        if rootPath then
            rootPath = modifyPath(rootPath);
            local colonStart = string.find(rootPath, ':.', 1, true);

            if colonStart ~= 0 then
                rootPath = string.sub(rootPath, colonStart + 2);
            end

            rootPath = rootPath .. '.';
        end
        
        path = string.gsub(path, '...:.', '');

        path = string.gsub(path, '\\', '/');
        path = string.gsub(path, '%.lua', '');
        path = string.gsub(path, '%./', '', 1);
        path = string.gsub(path, '/', '.');

        if rootPath then
            local start, _end = string.find(path, rootPath, 1, true);
            if start ~= nil and _end ~= nil and start ~= 0 and _end ~= 0 then
                path = string.sub(path, _end);
            end
        end

        return path;
    end

    --- @param levelOrFunc function|integer
    --- @param rootPath string?
    --- @param isClassPath boolean? (Default: false) If true, the path is transformed to `ClassDefinition.path` syntax.
    ---
    --- @return string path
    function DebugUtils.getPath(levelOrFunc, rootPath, isClassPath)
        local dS = debug.getinfo(levelOrFunc, 'S');
        if isClassPath then return modifyPath(dS.short_src, rootPath) end
        return dS.short_src;
    end

    --- @param levelOrFunc function|integer
    ---
    --- @return integer line
    function DebugUtils.getCurrentLine(levelOrFunc)
        return debug.getinfo(levelOrFunc, 'l').currentline;
    end

    --- @param level integer
    --- @param rootPath string?
    --- @param isClassPath boolean? (Default: false) If true, the path is transformed to `ClassDefinition.path` syntax.
    ---
    --- @return CallInfo
    function DebugUtils.getCallInfo(level, rootPath, isClassPath)
        local level_p1 = level + 1;
        return {
            currentLine = DebugUtils.getCurrentLine(level_p1),
            path = DebugUtils.getPath(level_p1, rootPath, isClassPath),
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
    --- @param rootPath string?
    --- @param isClassPath boolean? (Default: false) If true, the path is transformed to `ClassDefinition.path` syntax.
    --- 
    --- @return FunctionInfo
    function DebugUtils.getFuncInfo(func, rootPath, isClassPath)
        local path = DebugUtils.getPath(func, rootPath, isClassPath);
        local start, stop = DebugUtils.getFuncRange(func);
        return {
            path = path,
            start = start,
            stop = stop
        };
    end
end

return DebugUtils;
