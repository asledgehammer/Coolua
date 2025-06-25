---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local OOPUtils = {};

--- A common printf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function OOPUtils.printf(message, ...)
    print(string.format(message, ...));
end

--- A common errorf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param level number
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function OOPUtils.errorf(level, message, ...)
    level = level or 1;
    error(string.format(message, ...), level);
end

--- A common debugf implementation in modern compiled languages. Takes 2nd -> Nth arguments as `string.format(...)`
--- arguments.
---
--- @param flag boolean If true, the message prints. If false, it doesn't.
--- @param message string The message to format and print.
--- @param ... any The `string.format(...)` arguments to inject.
function OOPUtils.debugf(flag, message, ...)
    if flag then OOPUtils.printf(message, ...) end
end

function OOPUtils.copyArray(array)
    if not OOPUtils.isArray(array) then
        error(string.format('Object is not array. %s', OOPUtils.typeValueString(array)), 2);
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
function OOPUtils.copyTable(t)
    if not type(t) == 'table' then
        error(string.format('Object is not a table. %s', OOPUtils.typeValueString(t)), 2);
    end

    if OOPUtils.isArray(t) then
        return OOPUtils.copyArray(t);
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
function OOPUtils.typeValueString(o)
    return string.format('{type = %s, value = %s}', type(o), tostring(o));
end

function OOPUtils.anyToString(v, level, pretty)
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
        return indent .. OOPUtils.tableToString(v, level, pretty);
    else
        return indent .. '"' .. tostring(v) .. '"';
    end
end

function OOPUtils.tableToString(t, level, pretty)
    if level == nil or level < 0 then level = 0 end
    local indent_n2 = string.rep('    ', math.max(level - 2, 0));
    local indent_n1 = string.rep('    ', math.max(level - 1, 0));
    local indent_0 = string.rep('    ', math.max(level, 0));
    local indent_p1 = string.rep('    ', math.max(level + 1, 0));
    local s = '';
    if OOPUtils.isArray(t) then
        return OOPUtils.arrayToString(t, level + 1);
    else
        for k, v in pairs(t) do
            local vStr = OOPUtils.anyToString(v, level + 1, pretty);
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

function OOPUtils.arrayToString(array, level, pretty)
    if #array == 0 then return '[]' end

    if level == nil then level = 0 end
    local indent_0 = string.rep('    ', math.max(level, 0));
    local indent_p1 = string.rep('    ', math.max(level + 1, 0));
    local s = '';
    for i = 1, #array do
        if s == '' then
            s = OOPUtils.anyToString(array[i], level + 1);
        else
            s = s .. ',\n' .. indent_p1 .. OOPUtils.anyToString(array[i], level + 1, pretty);
        end
    end
    return '[\n' .. indent_p1 .. s .. '\n' .. indent_0 .. ']';
end

function OOPUtils.isValidName(name)
    return string.find(name, '[^%w^_^$]+') == nil;
end

--- @param t table
---
--- @return boolean result
function OOPUtils.isArray(t)
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
function OOPUtils.arrayContains(array, value)
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
function OOPUtils.arrayContainsDuplicates(array)
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
function OOPUtils.getType(val)
    local valType = type(val);

    -- Support for Lua-Class types.
    if valType == 'table' and val.__type__ then
        valType = 'class:' .. val.__type__;
    end

    return valType;
end

-- MARK: - Errors

function OOPUtils.IllegalScopeException(o, scope)
    error(
        string.format(
            'Lua Class (%s): Illegal LuaClassScope given when assigning class-property: %s',
            o.name,
            scope
        ),
        3
    );
end

function OOPUtils.IllegalParameterException(o, name, args)
    local argsLen = #args;
    local s = '';
    for i = 1, argsLen do
        local arg = args[i];
        local argType = OOPUtils.getType(arg);
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

function OOPUtils.FieldTypeException(o, name, types, value)
    local sTypes = '';
    if OOPUtils.getType(types) == 'table' then
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
        OOPUtils.getType(value),
        sTypes
    );
    error(s, 3);
end

function OOPUtils.FieldNotExistsException(o, name, value)
    local s = string.format(
        'Lua Class (%s): Attempted to assign non-field "%s" with type = %s and value = %s".',
        o.__type,
        name,
        OOPUtils.getType(value),
        tostring(value)
    );
    error(s, 3);
end

function OOPUtils.FieldAccessException(o, name)
    local s = string.format(
        'Lua Class (%s): Attempted to access private field: "%s"',
        o.__type,
        name
    );
    error(s, 3);
end

function OOPUtils.createClassMetatable(o)
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
            OOPUtils.FieldAccessException(o, field);
            return;
        end

        if field == 'width' or field == 'height' then
            if type(value) ~= 'number' then
                OOPUtils.FieldTypeError(tbl, field, { 'number' }, value);
            end
            __fields[field] = value;
            return;
        end
        OOPUtils.FieldNotExistsException(tbl, field, value);
    end

    setmetatable(o, mt);
end

return OOPUtils;
