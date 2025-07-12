---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

local isArray = require 'cool/vm/utils'.isArray;

--- @type VMTypeModule
local API = {

    __type__ = 'VMModule',

    --- @param vm VM
    setVM = function(vm)
        vm = vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

function API.isAssignableFromType(value, typeOrTypes)
    if API.getType(typeOrTypes) == 'table' then
        --- @cast typeOrTypes string[]
        if isArray(typeOrTypes) then
            for i = 1, #typeOrTypes do
                if typeOrTypes[i] == 'any' or typeOrTypes[i] == API.getType(value) then
                    return true;
                end
            end
            return false;
        end
    end
    --- @cast typeOrTypes string
    return API.getType(value) == typeOrTypes;
end

function API.canCast(from, to)
    -- TODO: Implement inferred class cast type(s).
    return from == to;
end

function API.anyCanCastToTypes(from, to)
    local fromLen = #from;
    local toLen = #to;
    for i = 1, fromLen do
        local a = from[i];
        for j = 1, toLen do
            local b = to[j];
            if API.canCast(a, b) then
                return true;
            end
        end
    end
    return false;
end

function API.getType(val)
    local valType = type(val);

    -- Support for Lua-Class types.
    if valType == 'table' then
        if val.__type__ then
            valType = val.__type__;
        elseif val.type then
            valType = val.type;
        end
    end

    return valType;
end

return API;
