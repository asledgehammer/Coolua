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

-- NOTE: table.concat exists.
--- @class table
--- @field join fun(array: string[], delimiter: string): string

--- @param array string[]
--- @param delimiter string|any
---
--- @return string
function table.join(array, delimiter)
    if not array or #array == 0 then error('Array is nil or empty.', 2) end
    local s = '';
    for i = 1, #array do
        if s == '' then
            s = array[i];
        else
            s = s .. tostring(delimiter) .. array[i];
        end
    end
    return s;
end

--- A common printf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function API.printf(message, ...)
    print(string.format(message, ...));
end

--- A common errorf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param level number
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function API.errorf(level, message, ...)
    level = level or 1;
    error(string.format(message, ...), level);
end

--- A common debugf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param flag boolean If true, the message prints. If false, it doesn't.
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function API.debugf(flag, message, ...)
    if flag then API.printf(message, ...) end
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

--- @param val any
---
--- @return type|string
function API.getType(val)
    local valType = type(val);

    -- Support for Lua-Class types.
    if valType == 'table' and val.__type__ then
        valType = 'class:' .. val.__type__;
    end

    return valType;
end

-- MARK: - Errors

function API.IllegalScopeException(o, scope)
    error(
        string.format(
            'Lua Class (%s): Illegal LuaClassScope given when assigning class-property: %s',
            o.name,
            scope
        ),
        3
    );
end

function API.IllegalParameterException(o, name, args)
    local argsLen = #args;
    local s = '';
    for i = 1, argsLen do
        local arg = args[i];
        local argType = API.getType(arg);
        if argType == 'table' and arg.__type then
            argType = string.format('Lua Class (%s)', arg.__type);
        end
        local body;
        if argType == 'nil' then
            body = argType;
        else
            local value = tostring(arg);
            if argType == 'string' then
                value = '"' .. value .. '"';
            end
            body = string.format('(%s) = %s', argType, value);
        end
        if s == '' then
            s = s .. string.format('\n\t%s', body);
        else
            s = s .. string.format(',\n\t%s', body)
        end
    end
    s = string.format('Lua Class (%s): Unknown method %s(%s\n)', o.__type, name, s);
    error(s, 3);
end

function API.FieldTypeException(o, name, types, value)
    local sTypes = '';
    if API.getType(types) == 'table' then
        local len = #types;
        for i = 1, len do
            if sTypes == '' then
                sTypes = '\t' .. types[i];
            else
                sTypes = sTypes .. ',\n\t' .. types[i]
            end
        end
    end
    local s = string.format(
        'Lua Class (%s): Attempted to assign field "%s" with type "%s". Expected type(s): [\n%s\n]',
        o.__type,
        name,
        API.getType(value),
        sTypes
    );
    error(s, 3);
end

function API.FieldNotExistsException(o, name, value)
    local s = string.format(
        'Lua Class (%s): Attempted to assign non-field "%s" with type = %s and value = %s".',
        o.__type,
        name,
        API.getType(value),
        tostring(value)
    );
    error(s, 3);
end

function API.FieldAccessException(o, name)
    local s = string.format(
        'Lua Class (%s): Attempted to access private field: "%s"',
        o.__type,
        name
    );
    error(s, 3);
end

function API.createClassMetatable(o)
    local mt = getmetatable(o) or {};

    local __fields = {};

    -- Copy functions & fields.
    for k, v in pairs(o) do
        __fields[k] = v;
    end

    mt.__index = __fields;

    mt.__newindex = function(tbl, field, value)
        -- Hide assignment table.
        if field == '__fields' then
            API.FieldAccessException(o, field);
            return;
        end

        if field == 'width' or field == 'height' then
            if type(value) ~= 'number' then
                API.FieldTypeError(tbl, field, { 'number' }, value);
            end
            __fields[field] = value;
            return;
        end
        API.FieldNotExistsException(tbl, field, value);
    end

    setmetatable(o, mt);
end

--- Converts the first character to upper. (Used for get-set shorthand)
---
--- @param str string
---
--- @return string firstCharUpperString
function API.firstCharToUpper(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2);
end

return API;
