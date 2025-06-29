local LVM;

--- @type LVMPackageModule
local API = {

    __type__ = 'LVMModule',

    setLVM = function(lvm) LVM = lvm end
};

function API.newPackageStruct()
    local t, mt, fields = {}, {}, {};
    mt.__index = fields;
    mt.__newindex = function(_, field, value)
        if not LVM.allowPackageStructModifications then
            error('Cannot modify Package Structure.', 2);
        end
        fields[field] = value;
    end
    setmetatable(t, mt);
    return t;
end

function API.addToPackageStruct(def)
    local package = def.package;
    local split = package:split('.');
    local packageCurr = _G;
    for i = 1, #split do
        local packageNext = split[i];
        if not packageCurr[packageNext] then
            packageCurr[packageNext] = API.newPackageStruct();
        end
        packageCurr = packageCurr[packageNext];
    end
    packageCurr[def.name] = def;
end

return API;
