---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    setLVM = function(lvm) LVM = lvm end

};

--- @cast API LVMParameterModule

--- @param paramsA ParameterDefinition[]
--- @param paramsB ParameterDefinition[]
---
--- @return boolean
function API.areCompatible(paramsA, paramsB)
    if #paramsA ~= #paramsB then
        print(string.format('Params length mismatch: #a = %i, #b = %i', #paramsA, #paramsB));
        return false;
    end

    for i = 1, #paramsA do
        local a = paramsA[i];
        local b = paramsB[i];
        if not LVM.type.anyCanCastToTypes(a.types, b.types) then
            return false;
        end
    end

    return true;
end

function API.getVarargTypes(arg)
    if not API.isVararg(arg) then
        errorf(2, 'Type is not vararg: %s', arg);
    end
    return arg:sub(1, #arg - 3):split('|');
end

function API.isVararg(arg)
    local len = #arg;
    if len < 3 then return false end
    return string.sub(arg, len - 2, len) == '...';
end

function API.compile(defParams)

    if not defParams then return {} end

    -- Convert any simplified type declarations.
    local paramLen = #defParams;
    if paramLen then
        for i = 1, paramLen do
            local param = defParams[i];

            -- Validate parameter type(s).
            if not param.type and not param.types then
                errorf(2, 'Parameter #%i doesn\'t have a defined type string or types string[]. (name = %s)',
                    i, param.name
                );
            else
                if param.type and not param.types then
                    param.types = { param.type };
                    --- @diagnostic disable-next-line
                    param.type = nil;
                end
            end

            -- Validate parameter name.
            if not param.name and not LVM.parameter.isVararg(param.types[1]) then
                errorf(2, 'Parameter #%i doesn\'t have a defined name string.', i);
            elseif param.name == '' then
                errorf(2, 'Parameter #%i has an empty name string.', i);
            end
        end
    end

    return defParams;
end

return API;
