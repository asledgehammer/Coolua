---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;

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

local ROOT_PATH = getRootPath();
print('LVM.ROOT_PATH = ' .. ROOT_PATH);

LVM = {

    __type__ = 'LVM',

    ROOT_PATH = ROOT_PATH,

    debug = require 'lvm/debug',
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
    parameter = require 'lvm/parameter',
    constructor = require 'lvm/constructor',
    method = require 'lvm/method',
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
LVM.parameter.setLVM(LVM);
LVM.constructor.setLVM(LVM);
LVM.method.setLVM(LVM);
LVM.class.setLVM(LVM);
LVM.struct.setLVM(LVM);
LVM.interface.setLVM(LVM);

return LVM;
