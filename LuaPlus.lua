---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

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

--- @return table
function table:clone()
    local clone = {};
    if self:isArray() then
        for i = 1, #self do
            table.insert(clone, self[i]);
        end
    else
        for k, v in pairs(self) do
            clone[k] = v;
        end
    end
    return clone;
end

function table:arrayContains(e)
    if not self:isArray() then
        error('Not an array.', 2);
    end

    local len = #self;
    if len == 0 then return false end
    for i = 1, len do
        if self[i] == e then return true end
    end

    return false;
end

function table:arrayContainsDuplicates()
    if not self:isArray() then
        error('Not an array.', 2);
    end

    local len = #self;
    for i = 1, len do
        for j = 1, len do
            if i ~= j and self[i] == self[j] then
                return true;
            end
        end
    end

    return false;
end

--- @return boolean result
function table:isArray()
    local i = 0;
    for _ in pairs(self) do
        i = i + 1;
        if self[i] == nil then return false end
    end
    return true;
end

local API = {};

--- @cast API LuaPlus

local mt_new = { __index = table };

function API.newTable()
    return setmetatable({}, mt_new);
end

return API;
