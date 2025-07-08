---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

local API = {
    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
    end
};

local meta;
function API.readonly(table)
    meta = getmetatable(table) or {};

    local __newindex = function(_, field, value)
        if LVM.isOutside() then
            error('Attempt to modify read-only object.', 2);
        end

        table[field] = value;
    end

    return setmetatable({}, {
        __index     = table,
        __newindex  = __newindex,
        __metatable = false,
        __add       = meta.__add,
        __sub       = meta.__sub,
        __mul       = meta.__mul,
        __div       = meta.__div,
        __mod       = meta.__mod,
        __pow       = meta.__pow,
        __eq        = meta.__eq,
        __lt        = meta.__lt,
        __le        = meta.__le,
        __concat    = meta.__concat,
        __call      = meta.__call,
        __tostring  = meta.__tostring
    });
end

--- @class string
--- @field split fun(self, delimiter: string): string[]
--- @field startsWith fun(self, str: string): boolean

--- @param self string
--- @param delimiter string
--- @return string[]
function string.split(self, delimiter)
    if self == '' then return {} end
    local t = {};
    for str in string.gmatch(self, "([^" .. delimiter .. "]+)") do
        table.insert(t, str);
    end
    return t;
end

--- @param self string
--- @param str string
---
--- @return boolean
function string.startsWith(self, str)
    return string.find(self, str, 1, true) == 1;
end

function API.copyArray(array)
    if not API.isArray(array) then
        error(string.format('Object is not array. %s', API.typeValueString(array)), 2);
    end

    local array2 = {};
    for i = 1, #array do
        table.insert(array2, array[i]);
    end

    return array2;
end

--- @param t table
---
--- @return table
function API.copyTable(t)
    if not type(t) == 'table' then
        error(string.format('Object is not a table. %s', API.typeValueString(t)), 2);
    end

    if API.isArray(t) then
        return API.copyArray(t);
    end

    local array2 = {};
    for k, v in pairs(t) do
        array2[k] = v;
    end

    return array2;
end

--- @param o any
---
--- @return string typeValueString
function API.typeValueString(o)
    return string.format('{type = %s, value = %s}', type(o), tostring(o));
end

function API.isValidName(name)
    return string.find(name, '[^%w^_^$]+') == nil;
end

--- @param t table
---
--- @return boolean result
function API.isArray(t)
    if type(t) ~= 'table' then return false end
    local i = 0;
    for _ in pairs(t) do
        i = i + 1;
        if t[i] == nil then return false end
    end
    return true;
end

--- @param array any[]
--- @param value any
---
--- @return boolean result True if one or more array contents contains an equal value.
function API.arrayContains(array, value)
    local len = #array;
    for i = 1, len do
        if array[i] == value then
            return true;
        end
    end
    return false;
end

--- @param array any[]
---
--- @return boolean result True if two or more array indices contains equal values.
function API.arrayContainsDuplicates(array)
    local len = #array;
    for i = 1, len do
        for j = 1, len do
            if i ~= j and array[i] == array[j] then
                return true;
            end
        end
    end
    return false;
end

return API;
