---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'PrintPlus';
local debugf = PrintPlus.debugf;

--- @type LVM
local LVM;

local LVMUtils = require 'LVMUtils';
local readonly = LVMUtils.readonly;

--- @type LVMPackageModule
local API;
API = {

    __type__ = 'LVMModule',

    packages = {},

    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
        API.packages = readonly({
            __type__ = 'PackageDefinition',
            path = '(Default Package)'
        });
    end
};

function API.addToPackageStruct(def)
    local pkg = def.pkg;
    local split = pkg:split('.');
    local pkgCurr = API.packages;
    for i = 1, #split do
        local pkgNext = split[i];
        if not pkgCurr[pkgNext] then
            local subPath = table.concat(split, '.', 1, i);
            pkgCurr[pkgNext] = readonly({
                __type__ = 'PackageDefinition',
                path = subPath
            });
            debugf(LVM.debug.pkg, '[PACKAGE] :: CREATE package: %s', pkgNext);
        end
        pkgCurr = pkgCurr[pkgNext];
    end
    debugf(LVM.debug.pkg, '[PACKAGE] :: package (%s): Adding class: %s', def.pkg, LVM.print.printStruct(def));
    pkgCurr[def.name] = def;
end

return API;
