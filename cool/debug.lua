---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

require 'cool/plus';

local PrintPlus = require 'cool/print';
local printf = PrintPlus.printf;
local debugf = PrintPlus.debugf;

_G.INSIDE_PZ = _G['ZombRandFloat'] ~= nil;

-- If in ProjectZomboid environment, load fixes for missing Lua debug instrumentation API.
if INSIDE_PZ then
    pcall(function() require 'cool/pz_fix' end);
end

local DebugUtils = {};

--- @param str string
---
--- @return string strWithoutAtSymbol
local function removeAt(str)
    if INSIDE_PZ or not str then return str end
    if str:startsWith('@') then str = str:sub(2) end
    return str;
end

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
    if not path then return path end

    if INSIDE_PZ then
        path = string.gsub(path, '\\', '/');
        path = string.gsub(path, '%.lua', '');
        path = string.gsub(path, '%./', '', 1);
        path = string.gsub(path, '/', '.');
        return path;
    end

    if rootPath and rootPath ~= '' then
        rootPath = modifyPath(rootPath);
        local colonStart = string.find(rootPath, ':.', 1, true);

        if colonStart ~= nil and colonStart ~= 0 then
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
--- @param isClassPath boolean? (Default: false) If true, the path is transformed to `Struct.path` syntax.
---
--- @return string path
function DebugUtils.getPath(levelOrFunc, rootPath, isClassPath)
    local dS = debug.getinfo(levelOrFunc);
    local result;
    if isClassPath then
        result = modifyPath(removeAt(dS.source), rootPath);
    else
        result = removeAt(dS.source);
    end

    if result:startsWith('.') then
        while result:startsWith('.') do
            result = string.sub(result, 2);
        end
    end

    return result;
end

--- @param levelOrFunc function|integer
---
--- @return integer line
function DebugUtils.getCurrentLine(levelOrFunc)
    local line = debug.getinfo(levelOrFunc).currentline;
    -- print('line: ', levelOrFunc, line, debug.getinfo(levelOrFunc - 1, 'l').currentline);
    return line;
end

--- @param level integer
--- @param rootPath string?
--- @param isClassPath boolean? (Default: false) If true, the path is transformed to `Struct.path` syntax.
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
    local info = debug.getinfo(func);
    return info.linedefined, info.lastlinedefined;
end

--- @param func function
--- @param rootPath string?
--- @param isClassPath boolean? (Default: false) If true, the path is transformed to `Struct.path` syntax.
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

return DebugUtils;
