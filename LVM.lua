---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;
local printf = LVMUtils.printf;
local debugf = LVMUtils.debugf;

--- @type LVM
local LVM;

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
        local test = built .. '/LVMUtils.lua';
        local x = predofile(test);
        if x then
            rootPath = built;
            break;
        end
    end
    return rootPath;
end

local debug = require 'lvm/debug';

debugf(debug.internal, '\n### LVM INIT ###\n');

local ROOT_PATH = getRootPath();

LVM = {

    __type__ = 'LVM',

    moduleCount = 0,

    ROOT_PATH = ROOT_PATH,

    DEFINITIONS = {},
    CLASSES = {},

    debug = debug,
    enum = require 'lvm/enum',
    constants = require 'lvm/constants',
    flags = require 'lvm/flags',
    print = require 'lvm/print',
    type = require 'lvm/type',
    scope = require 'lvm/scope',
    audit = require 'lvm/audit',
    package = require 'lvm/package',
    generic = require 'lvm/generic',
    meta = require 'lvm/meta',
    stack = require 'lvm/stack',
    super = require 'lvm/super',
    field = require 'lvm/field',
    executable = require 'lvm/executable',
    class = require 'lvm/class',
    struct = require 'lvm/struct',
    interface = require 'lvm/interface',

    isInside = function()
        return LVM.flags.internal ~= 0;
    end,

    isOutside = function()
        return LVM.flags.internal == 0;
    end,

    stepIn = function()
        LVM.flags.internal = LVM.flags.internal + 1;
    end,

    stepOut = function()
        if LVM.isOutside() then
            error('Cannot step out of internal LVM. (Already outside)', 2);
        end
        LVM.flags.internal = LVM.flags.internal - 1;
    end
};

LVM.debug.setLVM(LVM);
LVM.enum.setLVM(LVM);
LVM.constants.setLVM(LVM);
LVM.flags.setLVM(LVM);
LVM.print.setLVM(LVM);
LVM.type.setLVM(LVM);
LVM.scope.setLVM(LVM);
LVM.audit.setLVM(LVM);
LVM.package.setLVM(LVM);
LVM.generic.setLVM(LVM);
LVM.meta.setLVM(LVM);
LVM.stack.setLVM(LVM);
LVM.super.setLVM(LVM);
LVM.field.setLVM(LVM);
LVM.executable.setLVM(LVM);
LVM.class.setLVM(LVM);
LVM.struct.setLVM(LVM);
LVM.interface.setLVM(LVM);

--- @param path string
---
--- @return StructDefinition|nil
function LVM.forNameDef(path)
    return LVM.DEFINITIONS[path];
end

function LVM.forName(path)
    --- @type Class?
    local class = LVM.CLASSES[path];

    if not class then
        local def = LVM.DEFINITIONS[path];
        -- printf('LVM.DEFINITIONS[%s] = %s', path, tostring(def));
        if def and (
                def.__type__ == 'ClassStructDefinition' or
                def.__type__ == 'InterfaceStructDefinition' or
                def.__type__ == 'EnumStructDefinition'
            ) then
            --- @cast def ClassStructDefinition|InterfaceStructDefinition|EnumStructDefinition

            LVM.stepIn();
            class = _G.lua.lang.Class.new(def);
            LVM.stepOut();

            LVM.CLASSES[path] = class;
        end
    end

    return class;
end

debugf(LVM.debug.internal, 'LVM: Loaded %i Modules.', LVM.moduleCount);
debugf(LVM.debug.internal, 'LVM: ROOT_PATH = ' .. ROOT_PATH);

debugf(LVM.debug.internal, '\n### LVM READY ###\n');

return LVM;
