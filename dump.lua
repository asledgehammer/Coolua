---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- Properties that can be modified for global default configuration of dumps.
local DEFAULT_INDENT_STEP = string.rep(' ', 4);
local NEW_LINE = '\n';
local DEFAULT_MAX_LEVEL = 12;
local DEFAULT_LABEL = false;
local DEFAULT_LABEL_FIELD = '__type__';
local DEFAULT_PRETTY = false;

--- The default configuration for all dumps.
local DEFAULT_CONFIGURATION = {
    pretty = DEFAULT_PRETTY,
    level = 0,
    maxLevel = DEFAULT_MAX_LEVEL,
    label = DEFAULT_LABEL,
    labelField = DEFAULT_LABEL_FIELD
};

--- @param t table
---
--- @return boolean result
local function isArray(t)
    if type(t) ~= 'table' then return false end
    local i = 0;
    for _ in pairs(t) do
        i = i + 1;
        if t[i] == nil then return false end
    end
    return true;
end

--- @param data DumpMetadata|nil
--- @param e any
local function isDiscovered(data, e)
    if not data or not e then return false end
    for i = 1, #data.discovered do
        if data.discovered[i] == e then
            return true;
        end
    end
    return false;
end

--- @param cfg table?
---
--- @return DumpConfiguration
local function adaptConfiguration(cfg)
    if not cfg then return DEFAULT_CONFIGURATION end

    -- Polyfill missing settings.
    if not cfg.level then cfg.level = 0 end
    if not cfg.maxLevel then cfg.maxLevel = DEFAULT_MAX_LEVEL end
    if not cfg.label then cfg.label = DEFAULT_LABEL end
    if not cfg.labelField then cfg.labelField = DEFAULT_LABEL_FIELD end
    if not cfg.pretty then cfg.pretty = DEFAULT_PRETTY end

    return cfg;
end

--- @param data DumpConfiguration
---
--- @return DumpMetadata
local function createMetadata(data)
    return { level = data.level, discovered = {} };
end

--- @type dump
local dump = {};

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

function dump.discovered()
    return '<cyclic>';
end

function dump.array(a, cfg, metadata)
    cfg = adaptConfiguration(cfg);
    metadata = metadata or createMetadata(cfg);

    if isDiscovered(metadata, a) then
        return dump.discovered();
    end
    table.insert(metadata.discovered, a);

    local newline = ' ';
    local indent0, indent1 = '', '';
    if cfg.pretty then
        newline = NEW_LINE;
        indent0 = string.rep(DEFAULT_INDENT_STEP, metadata.level);
        indent1 = string.rep(DEFAULT_INDENT_STEP, metadata.level + 1);
    end
    local len = #a;

    local label = '';
    if cfg.label then
        label = string.format('<Array[%i]> ', len);
    end

    if len == 0 then return string.format('%s[]', label) end

    local s = '';
    for i = 1, #a do
        local v = a[i];

        metadata.level = metadata.level + 1;
        local e = dump.any(v, cfg, metadata);
        metadata.level = metadata.level - 1;

        if cfg.label then
            e = string.format('[%i] = %s', i, e);
        end
        if s == '' then
            s = indent1 .. e;
        else
            s = s .. ',' .. newline .. indent1 .. e;
        end
    end

    return string.format('%s[' .. newline .. '%s' .. newline .. indent0 .. ']', label, s);
end

function dump.table(t, cfg, metadata)
    cfg = adaptConfiguration(cfg);
    metadata = metadata or createMetadata(cfg);

    if isDiscovered(metadata, t) then
        return dump.discovered();
    end
    table.insert(metadata.discovered, t);

    local newline = ' ';
    local indent0, indent1 = '', '';
    if cfg.pretty then
        newline = NEW_LINE;
        indent0 = string.rep(DEFAULT_INDENT_STEP, metadata.level);
        indent1 = string.rep(DEFAULT_INDENT_STEP, metadata.level + 1);
    end

    local label = '';
    local s = '';

    if cfg.label and t[cfg.labelField] then
        label = '<' .. tostring(t[cfg.labelField]) .. '> ';
    end

    -- Sort keys.
    local keys = {};
    for key, _ in pairs(t) do
        table.insert(keys, key);
    end
    table.sort(keys, function(a, b)
        return tostring(a) < tostring(b);
    end);

    for i = 1, #keys do
        local key = keys[i];
        local value = t[key];
        if not cfg.label or key ~= cfg.labelField then
            local sKey = key;
            if type(key) == 'number' then
                sKey = '[' .. key .. ']'
            end
            metadata.level = metadata.level + 1;
            local e = string.format('%s = %s', tostring(sKey), dump.any(value, cfg, metadata));
            metadata.level = metadata.level - 1;
            if s == '' then
                s = indent1 .. e;
            else
                s = s .. ',' .. newline .. indent1 .. e;
            end
        end
    end

    if s == '' then
        return label .. '{}';
    end

    return string.format('%s{' .. newline .. '%s' .. newline .. indent0 .. '}', label, s);
end

function dump.any(e, cfg, metadata)
    if isDiscovered(metadata, e) then
        return dump.discovered();
    end

    cfg = adaptConfiguration(cfg);
    metadata = metadata or createMetadata(cfg);

    if cfg.maxLevel <= cfg.level then
        return '<...>';
    end

    local t = type(e);
    if t == 'table' then
        if e.__type__ and e.__type__ == 'ClassStructDefinition' then
            return dump.class(e);
        elseif isArray(e) then
            return dump.array(e, cfg, metadata);
        else
            return dump.table(e, cfg, metadata);
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

setmetatable(dump, {
    __call = function(self, ...)
        return self.any(...);
    end
});

return dump;
