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

    packages = {},

    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
};

function API.newPackageStruct(path)
    local t, mt, fields = { path = path }, {}, {};
    mt.__index = fields;
    mt.__newindex = function(_, field, value)
        if not LVM.flags.allowPackageStructModifications then
            error('Cannot modify Package Structure.', 2);
        end
        fields[field] = value;
    end
    mt.__tostring = function(self)
        return string.format('Package (%s)', self.path);
    end
    setmetatable(t, mt);
    return t;
end

function API.addToPackageStruct(def)
    local pkg = def.pkg;
    local split = pkg:split('.');
    local pkgCurr = API.packages;
    for i = 1, #split do
        local pkgNext = split[i];
        if not pkgCurr[pkgNext] then
            local subPath = table.concat(split, '.', 1, i);
            pkgCurr[pkgNext] = API.newPackageStruct(subPath);
            debugf(LVM.debug.pkg, '[PACKAGE] :: CREATE package: %s', pkgNext);
        end
        pkgCurr = pkgCurr[pkgNext];
    end
    debugf(LVM.debug.pkg, '[PACKAGE] :: package (%s): Adding class: %s', def.pkg, LVM.print.printStruct(def));
    pkgCurr[def.name] = def;
end

return API;
