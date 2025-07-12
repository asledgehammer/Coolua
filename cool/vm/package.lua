---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local debugf = PrintPlus.debugf;

--- @type VM
local vm;

local utils = require 'cool/vm/utils';
local readonly = utils.readonly;

--- @type VMPackageModule
local API;
API = {

    __type__ = 'VMModule',

    packages = {},

    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
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
            debugf(vm.debug.pkg, '[PACKAGE] :: CREATE package: %s', pkgNext);
        end
        pkgCurr = pkgCurr[pkgNext];
    end
    debugf(vm.debug.pkg, '[PACKAGE] :: package (%s): Adding class: %s', def.pkg, vm.print.printStruct(def));
    pkgCurr[def.name] = def;
end

function API.getPackage(pkg)
    local split = pkg:split('.');
    local pkgCurr = API.packages;
    for i = 1, #split do
        local pkgNext = split[i];
        if not pkgCurr[pkgNext] then return nil end
        pkgCurr = pkgCurr[pkgNext];
    end
    return pkgCurr;
end

return API;
