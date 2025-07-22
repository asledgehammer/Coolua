---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type VM
local vm;

local dump = require 'cool/dump'.any;

local isArray = require 'cool/vm/utils'.isArray;

local PrintPlus = require 'cool/print';
local printf = PrintPlus.printf;
local debugf = PrintPlus.debugf;
local errorf = PrintPlus.errorf;

local dumpCfg = { pretty = true, label = true };

local function asTypeValueString(value)
    return dump(
        {
            type = type(value),
            value = value,
        },
        dumpCfg
    );
end

--- @type VMTypeModule
local API = {

    __type__ = 'VMModule',

    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

function API.isAssignableFromTypes(value, types)
    if type(types) ~= 'table' or not isArray(types) then
        errorf(2, 'types is not an array. {type = %s, value = %s}',
            type(types), tostring(types)
        );
    end

    local typeLen = #types;
    if typeLen == 0 then error('types array is empty.', 2) end
    for i = 1, typeLen do
        if API.isAssignableFromType(value, types[i]) then
            return true;
        end
    end

    return false;
end

function API.isAssignableFromType(value, _type)
    local result = false;

    -- (any check)
    if _type == 'any' then
        -- print('>>>>> A');
        result = true;
    end

    -- (void|nil check)
    if not result and (_type == 'void' or _type == 'nil') and value == nil then
        -- print('>>>>> B');
        result = true;
    end

    -- (boolean check)
    if not result and _type == 'boolean' and type(value) == 'boolean' then
        -- print('>>>>> C');
        result = true;
    end

    -- (numeric check)
    if not result and _type == 'number' and type(value) == 'number' then
        -- print('>>>>> D');
        result = true;
    end

    -- (string check)
    if not result and _type == 'string' and type(value) == 'string' then
        -- print('>>>>> E');
        result = true;
    end

    -- (function check)
    if not result and _type == 'function' and type(value) == 'function' then
        -- print('>>>>> F');
        result = true;
    end

    -- (userdata check) (Catch-all for tables, even our structs or struct-instances)
    if not result and _type == 'table' and type(value) == 'table' then
        result = true;
    elseif not result then
        -- (hierarchical Struct type-check)
        local typeStruct = _type;
        -- TODO: Implement lua.lang stuff like 'class' or 'interface' or 'enum' or 'record' being catch-alls.
        -- print('>>>>> H: typeStruct: ' .. tostring(typeStruct));
        if typeStruct then
            local valueStruct = value;
            if valueStruct then
                if typeStruct.__type__ == 'ClassStruct' then
                    result = typeStruct == valueStruct.__class__:getStruct() or typeStruct:isSuperClass(valueStruct);
                    -- print('>>>>> H2: ', result);
                elseif typeStruct.__type__ == 'InterfaceStruct' then
                    result = typeStruct == valueStruct.__class__:getStruct() or typeStruct:isSuperInterface(valueStruct);
                    -- print('>>>>> H3: ', result);
                elseif typeStruct.__type__ == 'RecordStruct' then
                    result = typeStruct == valueStruct.__class__:getStruct();
                    -- print('>>>>> H4: ', result);
                elseif typeStruct.__type__ == 'EnumStruct' then
                    result = typeStruct == valueStruct.__class__:getStruct();
                    -- print('>>>>> H5: ', result);
                end
            else
                -- print('>>>>> H6');
            end
        else
            -- print('>>>>> H3');
        end
    end

    -- (thread check)
    if not result and _type == 'thread' and type(value) == 'thread' then
        -- print('>>>>> I');
        result = true;
    end

    -- (userdata check)
    -- TODO: Figure out how to handle Java-specific types in Kahlua environment.
    if not result and _type == 'userdata' and type(value) == 'userdata' then
        -- print('>>>>> J');
        result = true;
    end

    -- (string-struct check) (NOTE: Can be accurate only after inspecting string-literal struct-type references)
    if not result and type(_type) == 'string' then
        -- print('>>>>> K');
        -- (hierarchical Struct type-check)
        local typeStruct = vm.STRUCTS[_type];
        if typeStruct then
            local valueStruct = value;
            if valueStruct then
                if typeStruct.__type__ == 'ClassStruct' then
                    result = typeStruct == valueStruct.__class__:getStruct() or typeStruct:isSuperClass(valueStruct);
                    -- print('>>>>> K2: ', result);
                elseif typeStruct.__type__ == 'InterfaceStruct' then
                    result = typeStruct == valueStruct.__class__:getStruct() or typeStruct:isSuperInterface(valueStruct);
                    -- print('>>>>> K3: ', result);
                elseif typeStruct.__type__ == 'RecordStruct' then
                    result = typeStruct == valueStruct.__class__:getStruct();
                    -- print('>>>>> K4: ', result);
                elseif typeStruct.__type__ == 'EnumStruct' then
                    result = typeStruct == valueStruct.__class__:getStruct();
                    -- print('>>>>> K5: ', result);
                end
            end
            -- print('>>>>> K6: ' .. result);
        elseif _type == 'ClassStruct' then
            result = value.__type__ == 'ClassStruct';
            -- print('>>>>> K7: ', result);
        elseif _type == 'InterfaceStruct' then
            result = value.__type__ == 'InterfaceStruct';
            -- print('>>>>> K8: ', result);
        elseif _type == 'RecordStruct' then
            result = value.__type__ == 'RecordStruct';
            -- print('>>>>> K9: ', result);
        elseif _type == 'EnumStruct' then
            result = value.__type__ == 'EnumStruct';
            -- print('>>>>> K10: ', result);
        else
            -- print('>>>>> K11');
        end
    end

    debugf(vm.debug.type, '[TYPE] :: >> isAssignableFromType(type = %s, value = %s) == %s',
        asTypeValueString(_type), asTypeValueString(value), tostring(result)
    );

    return result;
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
