---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local debugf = PrintPlus.debugf;

--- @type VM
local VM;

local utils = require 'cool/vm/utils';
local readonly = utils.readonly;

--- @type VMPackageModule
local API;
API = {

    __type__ = 'VMModule',

    packages = {},

    --- @param vm VM
    setVM = function(vm)
        VM = vm;
        VM.moduleCount = VM.moduleCount + 1;
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
            debugf(VM.debug.pkg, '[PACKAGE] :: CREATE package: %s', pkgNext);
        end
        pkgCurr = pkgCurr[pkgNext];
    end
    debugf(VM.debug.pkg, '[PACKAGE] :: package (%s): Adding class: %s', def.pkg, VM.print.printStruct(def));
    pkgCurr[def.name] = def;
end

return API;
