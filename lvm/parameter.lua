---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;

--- @type LVM
local LVM;

--- @type LVMParamModule
local API = {

    __type__ = 'LVMModule',

    setLVM = function(lvm) LVM = lvm end
};

--- @param paramsA ParameterDefinition[]
--- @param paramsB ParameterDefinition[]
---
--- @return boolean
function API.areCompatable(paramsA, paramsB)
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

return API;
