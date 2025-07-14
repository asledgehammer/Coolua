---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

local API = {
    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
    end
};

--- @cast API VMUtils

-- In order for indexing to work on read-only tables, we'll need to override
-- the pairs/ipairs global functions. (Lua 5.1 compatability)

-- Store the original pairs and ipairs to call via proxy in read-only tables.
local originalPairs = pairs;
local originalIPairs = ipairs;

_G.pairs = function(tbl)
    -- Catch read-only tables and print their weapped tables.
    if tbl.__readonly__ and tbl.__pairs__ then
        return tbl.__pairs__(tbl);
    end

    -- Normal behavior.
    return originalPairs(tbl);
end

_G.ipairs = function(tbl)
    -- Catch read-only tables and print their weapped tables.
    if tbl.__readonly__ and tbl.__ipairs__ then
        return tbl.__ipairs__(tbl);
    end

    -- Normal behavior.
    return originalIPairs(tbl);
end

local meta;
function API.readonly(table)
    local __newindex = function(_, field, value)
        -- VM bypass.
        if vm.isInside() then
            table[field] = value;
            return;
        end
        error('Attempt to modify read-only object.', 2);
    end

    local __pairs = function()
        return pairs(table);
    end

    table.__pairs__ = function()
        return originalPairs(table);
    end
    table.__ipairs__ = function()
        return originalIPairs(table);
    end

    -- A general flag to make sure that anything implementing this utility can identify and handle.
    table.__readonly__ = true;

    meta = getmetatable(table) or {};

    local mt = {};
    for key, value in pairs(meta) do
        mt[key] = value;
    end

    mt.__newindex = __newindex;
    mt.__pairs = __pairs;
    mt.__index = table;

    -- IMPORTANT: This is how to make sure tampering isn't possible.
    mt.metatable = false;

    return setmetatable({}, mt);
end

function API.typeValueString(o)
    return string.format('{type = %s, value = %s}', type(o), tostring(o));
end

function API.isValidName(name)
    return name
        and name ~= ''
        and string.find(string.sub(name, 1, 1), '[^%a^_^]+') == nil
        and string.find(name, '[^%w^_^]+') == nil;
end

--- @param t any
---
--- @return boolean result
function API.isArray(t)
    if not t or type(t) ~= 'table' then return false end

    local i = 0;
    for _ in pairs(t) do
        i = i + 1;
        if t[i] == nil then return false end
    end
    return true;
end

--- @return table
function API.clone(tbl)
    local clone = {};
    if API.isArray(tbl) then
        for i = 1, #tbl do
            table.insert(clone, tbl[i]);
        end
    else
        for k, v in pairs(tbl) do
            clone[k] = v;
        end
    end
    return clone;
end

function API.arrayContains(tbl, e)
    if not API.isArray(tbl) then
        error('Not an array.', 2);
    end

    local len = #tbl;
    if len == 0 then return false end
    for i = 1, len do
        if tbl[i] == e then return true end
    end

    return false;
end

function API.arrayContainsDuplicates(tbl)
    if not API.isArray(tbl) then
        error('Not an array.', 2);
    end

    local len = #tbl;
    for i = 1, len do
        for j = 1, len do
            if i ~= j and tbl[i] == tbl[j] then
                return true;
            end
        end
    end

    return false;
end

return API;
