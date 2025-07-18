---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local dump = require 'cool/dump'.any;

-- Project Zomboid Kahlua Environment.
_G.INSIDE_PZ = _G['ZombRandFloat'] ~= nil;
if not INSIDE_PZ then return end

_G.xpcall = _G.pcall;

local debug = {};

local EMPTY = {
    linedefined = -1,
    lastlinedefined = -1,
    currentline = -1,
    source = '(unknown)'
};

local function adjustSource(src)
    if not src then return src end
    src = getShortenedFilename(src);

    local found = false;
    local start, _end = string.find(src, '/media/lua/shared/', 1, true);
    if start ~= nil and _end ~= nil and start ~= 0 and _end ~= 0 then
        src = string.sub(src, _end + 1);
        found = true;
    end

    if not found then
        start, _end = string.find(src, '/media/lua/server/', 1, true);
        if start ~= nil and _end ~= nil and start ~= 0 and _end ~= 0 then
            src = string.sub(src, _end + 1);
            found = true;
        end
    end

    if not found then
        start, _end = string.find(src, '/media/lua/client/', 1, true);
        if start ~= nil and _end ~= nil and start ~= 0 and _end ~= 0 then
            src = string.sub(src, _end + 1);
        end
    end

    return src;
end

--- @param f function
---
--- @return table
local function getinfoFunc(f)
    local source = adjustSource(getFilenameOfClosure(f)) or '';
    local linedefined = getFirstLineOfClosure(f) or -1;
    local lastlinedefined;
    if getLastLineOfClosure then
        lastlinedefined = getLastLineOfClosure(f);
    else
        lastlinedefined = linedefined;
    end
    return {
        linedefined = linedefined,
        lastlinedefined = lastlinedefined,
        source = source,
    };
end

--- @param level integer
---
--- @return table
local function getinfoLevel(level)
    level = level - 1;
    if level < 0 then level = 0 end
    local result = EMPTY;
    local co = getCurrentCoroutine();
    local top = getCallframeTop(co);
    repeat
        local frame = getCoroutineCallframeStack(co, level);
        if frame then
            result = {
                source = adjustSource(getFilenameOfCallframe(frame)) or EMPTY.source,
                linedefined = -1,
                lastlinedefined = -1,
                currentline = getLineNumber(frame) or -1
            };
        end
        level = level + 1;
    until result.source ~= EMPTY.source or level >= top;
    return result;
end

function debug.printStack()
    local result = nil;
    local level = 0;
    local s = 'COROUTINE STACK: [\n';
    local top = getCallframeTop(getCurrentCoroutine());
    repeat
        result = getinfoLevel(level);
        s = s .. '\t[' .. tostring(level) .. ']: ' .. dump(result, {}) .. ',\n';
        level = level + 1;
    until level == top;
    s = s .. ']';
    print(s);
end

--- @param levelOrFunc function|integer
---
--- @return table
function debug.getinfo(levelOrFunc)
    local result;
    local targ = type(levelOrFunc);
    if targ == 'function' then
        result = getinfoFunc(levelOrFunc);
    elseif targ == 'number' then
        result = getinfoLevel(levelOrFunc);
    else
        error('Invalid arg type: ' .. targ, 2);
    end

    if not result.source then result.source = EMPTY.source end
    if not result.currentline then result.currentline = -1 end
    if not result.linedefined then result.linedefined = -1 end
    if not result.lastlinedefined then result.lastlinedefined = -1 end

    return result;
end

_G.debug = debug;
