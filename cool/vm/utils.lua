---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

local API = {
    --- @param vm VM
    setVM = function(vm)
        vm = vm;
    end
};

--- @cast API VMUtils

local meta;
function API.readonly(table)
    table.__readonly__ = true;

    meta = getmetatable(table) or {};

    local __newindex = function(_, field, value)
        if vm.isOutside() then
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
