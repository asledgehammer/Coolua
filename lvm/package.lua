---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVMUtils = require 'LVMUtils';
local debugf = LVMUtils.debugf;

--- @type LVM
local LVM;

--- @type LVMPackageModule
local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

function API.newPackageStruct()
    local t, mt, fields = {}, {}, {};
    mt.__index = fields;
    mt.__newindex = function(_, field, value)
        if not LVM.flags.allowPackageStructModifications then
            error('Cannot modify Package Structure.', 2);
        end
        fields[field] = value;
    end
    setmetatable(t, mt);
    return t;
end

function API.addToPackageStruct(def)
    debugf(LVM.debug.pkg, 'addToPackageStruct(pkg = %s, name = %s)', def.pkg, def.name);
    local pkg = def.pkg;
    local split = pkg:split('.');
    local pkgCurr = _G;
    for i = 1, #split do
        local pkgNext = split[i];
        if not pkgCurr[pkgNext] then
            pkgCurr[pkgNext] = API.newPackageStruct();
        end
        pkgCurr = pkgCurr[pkgNext];
    end
    pkgCurr[def.name] = def;
end

return API;
