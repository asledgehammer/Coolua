---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- Require this to load injected functions to basic Lua types.
require 'cool/plus';

local utils = require 'cool/vm/utils';

local PrintPlus = require 'cool/print';
local debugf = PrintPlus.debugf;

--- @type VM
local vm;

local function predofile(...)
    local status, lib = pcall(dofile, ...)
    if status then return lib end
    return nil
end

local function getFullPath()
    local level = 1;
    local info = debug.getinfo(level);
    local lastRootPath = info.source;
    local rootPath = info.source;
    while info ~= nil do
        level = level + 1;
        info = debug.getinfo(level);
        if info then
            local next = info.source;
            lastRootPath = rootPath;
            rootPath = next;
        end
    end

    if rootPath == '=[C]' then
        rootPath = lastRootPath;
    end

    rootPath = string.gsub(rootPath, '\\', '/');
    rootPath = string.gsub(rootPath, '@', '');

    return rootPath;
end

local function getRootPath()
    local fullRootPath = getFullPath();
    local rootPath = '';
    local folders = fullRootPath:split('/');
    local built = '';
    for i = 1, #folders do
        if built == '' then
            built = folders[i];
        else
            built = built .. '/' .. folders[i];
        end
        local test = built .. '/cool/vm/utils.lua';
        local x = predofile(test);
        if x then
            rootPath = built;
            break;
        end
    end
    return rootPath;
end

local debug = require 'cool/vm/debug';

debugf(debug.internal, '\n### VM INIT ###\n');

local ROOT_PATH = getRootPath();

vm = {

    __type__ = 'VM',

    moduleCount = 0,

    ROOT_PATH = ROOT_PATH,

    DEFINITIONS = {},
    CLASSES = {},
    PACKAGES = {},

    debug = debug,
    enum = require 'cool/vm/enum',
    constants = require 'cool/vm/constants',
    flags = require 'cool/vm/flags',
    print = require 'cool/vm/print',
    type = require 'cool/vm/type',
    scope = require 'cool/vm/scope',
    audit = require 'cool/vm/audit',
    package = require 'cool/vm/package',
    generic = require 'cool/vm/generic',
    stack = require 'cool/vm/stack',
    super = require 'cool/vm/super',
    field = require 'cool/vm/field',
    executable = require 'cool/vm/executable',
    class = require 'cool/vm/class',
    struct = require 'cool/vm/struct',
    interface = require 'cool/vm/interface',

    isInside = function()
        return vm.flags.internal ~= 0;
    end,

    isOutside = function()
        return vm.flags.internal == 0;
    end,

    stepIn = function()
        vm.flags.internal = vm.flags.internal + 1;
    end,

    stepOut = function()
        if vm.isOutside() then
            error('Cannot step out of internal VM. (Already outside)', 2);
        end
        vm.flags.internal = vm.flags.internal - 1;
    end
};

utils.setVM(vm);
vm.debug.setVM(vm);
vm.enum.setVM(vm);
vm.constants.setVM(vm);
vm.flags.setVM(vm);
vm.print.setVM(vm);
vm.type.setVM(vm);
vm.scope.setVM(vm);
vm.audit.setVM(vm);
vm.package.setVM(vm);
vm.generic.setVM(vm);
vm.stack.setVM(vm);
vm.super.setVM(vm);
vm.field.setVM(vm);
vm.executable.setVM(vm);
vm.class.setVM(vm);
vm.struct.setVM(vm);
vm.interface.setVM(vm);

function vm.import(path)
    local def = vm.DEFINITIONS[path];

    if not def then
        pcall(function()
            def = require(string.gsub(path, '%.', '/'));
        end);
    end

    if not def then
        debugf(vm.debug.scope, '[SCOPE] :: Could not resolve struct: %s (Creating StructReference)', path);
        def = vm.struct.newReference(path);
        vm.DEFINITIONS[path] = def;
    end

    return def;
end

--- @param path string
---
--- @return StructDefinition|nil
function vm.forNameDef(path)
    return vm.DEFINITIONS[path];
end

function vm.forName(path)
    --- @type Class?
    local class = vm.CLASSES[path];

    if not class then
        local def = vm.DEFINITIONS[path];
        if def and (
                def.__type__ == 'ClassStructDefinition' or
                def.__type__ == 'InterfaceStructDefinition' or
                def.__type__ == 'EnumStructDefinition'
            ) then
            --- @cast def ClassStructDefinition|InterfaceStructDefinition|EnumStructDefinition

            vm.stepIn();
            class = vm.package.packages.lua.lang.Class.new(def);
            vm.stepOut();

            vm.CLASSES[path] = class;
        end
    end

    return class;
end

function vm.getPackage(path)
    local pkg = vm.PACKAGES[path];
    if not pkg then
        local pkgTable = vm.package.getPackage(path);
        if not pkgTable then
            PrintPlus.errorf(2, 'Package doesn\'t exist: %s', path);
        end
        pkg = vm.import 'lua.lang.Package'.new(path);
        vm.PACKAGES[path] = pkg;
    end
    return pkg;
end

debugf(vm.debug.internal, '[VM] :: Loaded %i Modules.', vm.moduleCount);
debugf(vm.debug.internal, '[VM] :: ROOT_PATH = ' .. ROOT_PATH);

debugf(vm.debug.internal, '\n### VM READY ###\n');

return vm;
