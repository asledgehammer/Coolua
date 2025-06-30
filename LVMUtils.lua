---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local API = {};

-- @param params ParameterDefinition[]
---
--- @return string
function API.paramsToString(params)
    local s = '';

    if not params or #params == 0 then return s end

    for i = 1, #params do
        local param = params[i];
        local sTypes = '';
        for j = 1, #param.types do
            if sTypes == '' then
                sTypes = param.types[j];
            else
                sTypes = sTypes .. '|' .. param.types[j];
            end
        end
        local sParam = string.format('%s: %s', param.name, sTypes);
        if s == '' then
            s = sParam;
        else
            s = s .. ', ' .. sParam;
        end
    end

    return s;
end

--- @class string
--- @field split fun(self, delimiter: string): string[]

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

function API.anyToString(v, level, pretty)
    pretty = pretty or false;
    if level == nil or level < 0 then level = 0 end
    local indent = '';
    if pretty then
        indent = string.rep('  ', level);
    end
    local type = type(v);
    if type == 'number' then
        return indent .. tostring(v);
    elseif type == 'boolean' then
        return indent .. tostring(v);
    elseif type == 'nil' then
        return indent .. 'nil';
    elseif type == 'table' then
        return indent .. API.tableToString(v, level, pretty);
    else
        return indent .. '"' .. tostring(v) .. '"';
    end
end

function API.tableToString(t, level, pretty)
    if level == nil or level < 0 then level = 0 end
    local indent_n2 = string.rep('    ', math.max(level - 2, 0));
    local indent_n1 = string.rep('    ', math.max(level - 1, 0));
    local indent_0 = string.rep('    ', math.max(level, 0));
    local indent_p1 = string.rep('    ', math.max(level + 1, 0));
    local s = '';
    if API.isArray(t) then
        return API.arrayToString(t, level + 1);
    else
        for k, v in pairs(t) do
            local vStr = API.anyToString(v, level + 1, pretty);
            if s == '' then
                s = k .. ' = ' .. vStr;
            else
                s = s .. ',\n' .. indent_p1 .. k .. ' = ' .. vStr;
            end
        end
    end
    if s == '' then return '{}' end
    return '{\n' .. indent_p1 .. s .. '\n' .. indent_0 .. '}';
end

function API.arrayToString(array, level, pretty)
    if #array == 0 then return '[]' end

    if level == nil then level = 0 end
    local indent_0 = string.rep('    ', math.max(level, 0));
    local indent_p1 = string.rep('    ', math.max(level + 1, 0));
    local s = '';
    for i = 1, #array do
        if s == '' then
            s = API.anyToString(array[i], level + 1);
        else
            s = s .. ',\n' .. indent_p1 .. API.anyToString(array[i], level + 1, pretty);
        end
    end
    return '[\n' .. indent_p1 .. s .. '\n' .. indent_0 .. ']';
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
        print(string.format('__newindex2(%s, %s)', field, tostring(value)));
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
