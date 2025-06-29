---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

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

return API;
