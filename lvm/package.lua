---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'PrintPlus';
local debugf = PrintPlus.debugf;

--- @type LVM
local LVM;

--- @type LVMPackageModule
local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
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
    debugf(LVM.debug.pkg, '[PACKAGE] :: package (%s): Adding class: %s', def.pkg, LVM.print.printStruct(def));
    pkgCurr[def.name] = def;
end

return API;
