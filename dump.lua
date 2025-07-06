local LVMUtils = require 'LVMUtils';

local dump = {};

function dump.array(a, level, maxLevel)
    level = level or 0;
    maxLevel = maxLevel or 10;

    local indent0 = string.rep('    ', level);
    local indent1 = string.rep('    ', level + 1);

    local len = #a;

    local tag = string.format('<Array[%i]> ', len);

    if len == 0 then return string.format('%s[]', tag) end

    local s = '';
    for i = 1, #a do
        local v = a[i];
        local e = string.format('[%i] = %s', i, dump.any(v, level + 1, maxLevel));
        if s == '' then
            s = indent1 .. e;
        else
            s = s .. ',\n' .. indent1 .. e;
        end
    end

    return string.format('%s[\n%s\n' .. indent0 .. ']', tag, s);
end

function dump.table(t, level, maxLevel)
    level = level or 0;
    maxLevel = maxLevel or 10;

    local indent0 = string.rep('    ', level);
    local indent1 = string.rep('    ', level + 1);

    local tag = '';
    local s = '';

    if t.__type__ then
        tag = '<' .. t.__type__ .. '> ';
    end

    -- Sort keys.
    local keys = {};
    for key, _ in pairs(t) do
        table.insert(keys, key);
    end
    table.sort(keys, function(a, b)
        return a < b;
    end);

    for i = 1, #keys do
        local key = keys[i];
        local value = t[key];
        if key ~= '__type__' then
            local e = string.format('%s = %s', key, dump.any(value, level + 1, maxLevel));
            if s == '' then
                s = indent1 .. e;
            else
                s = s .. ',\n' .. indent1 .. e;
            end
        end
    end

    if s == '' then
        return tag .. '{}';
    end

    return string.format('%s{\n%s\n' .. indent0 .. '}', tag, s);
end

function dump.string(s)
    return '"' .. tostring(s) .. '"';
end

function dump.func(f)
    return '<function>';
end

function dump.userdata(ud)
    return '<userdata>';
end

function dump.object(o)
    return tostring(o);
end

function dump.class(c)
    return 'Class <' .. c.path .. '>';
end

function dump.any(e, level, maxLevel)
    level = level or 0;
    maxLevel = maxLevel or 10;

    if maxLevel <= level then
        return '<...>';
    end

    local t = type(e);
    if t == 'table' then
        if e.__type__ and e.__type__ == 'ClassStructDefinition' then
            return dump.class(e);
        elseif LVMUtils.isArray(e) then
            return dump.array(e, level, maxLevel);
        else
            return dump.table(e, level, maxLevel);
        end
    elseif t == 'string' then
        return dump.string(e);
    elseif t == 'function' then
        return dump.func(e);
    elseif t == 'userdata' then
        return dump.userdata(e);
    else
        return dump.object(e);
    end
end

return dump;
