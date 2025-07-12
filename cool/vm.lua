---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

-- Require this to load injected functions to basic Lua types.
require 'cool/plus';

local utils = require 'cool/vm/utils';

local PrintPlus = require 'cool/print';
local debugf = PrintPlus.debugf;

--- @type VM
local VM;

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

VM = {

    __type__ = 'VM',

    moduleCount = 0,

    ROOT_PATH = ROOT_PATH,

    DEFINITIONS = {},
    CLASSES = {},

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
    meta = require 'cool/vm/meta',
    stack = require 'cool/vm/stack',
    super = require 'cool/vm/super',
    field = require 'cool/vm/field',
    executable = require 'cool/vm/executable',
    class = require 'cool/vm/class',
    struct = require 'cool/vm/struct',
    interface = require 'cool/vm/interface',

    isInside = function()
        return VM.flags.internal ~= 0;
    end,

    isOutside = function()
        return VM.flags.internal == 0;
    end,

    stepIn = function()
        VM.flags.internal = VM.flags.internal + 1;
    end,

    stepOut = function()
        if VM.isOutside() then
            error('Cannot step out of internal VM. (Already outside)', 2);
        end
        VM.flags.internal = VM.flags.internal - 1;
    end
};

utils.setVM(VM);
VM.debug.setVM(VM);
VM.enum.setVM(VM);
VM.constants.setVM(VM);
VM.flags.setVM(VM);
VM.print.setVM(VM);
VM.type.setVM(VM);
VM.scope.setVM(VM);
VM.audit.setVM(VM);
VM.package.setVM(VM);
VM.generic.setVM(VM);
VM.meta.setVM(VM);
VM.stack.setVM(VM);
VM.super.setVM(VM);
VM.field.setVM(VM);
VM.executable.setVM(VM);
VM.class.setVM(VM);
VM.struct.setVM(VM);
VM.interface.setVM(VM);

function VM.import(path)

    local def = VM.DEFINITIONS[path];

    if not def then
        pcall(function()
            def = require(string.gsub(path, '%.', '/'));
        end);
    end

    if not def then
        debugf(VM.debug.scope, '[SCOPE] :: Could not resolve struct: %s (Creating StructReference)');
        def = VM.struct.newReference(path);
        VM.DEFINITIONS[path] = def;
    end

    return def;
end

--- @param path string
---
--- @return StructDefinition|nil
function VM.forNameDef(path)
    return VM.DEFINITIONS[path];
end

function VM.forName(path)
    --- @type Class?
    local class = VM.CLASSES[path];

    if not class then
        local def = VM.DEFINITIONS[path];
        if def and (
                def.__type__ == 'ClassStructDefinition' or
                def.__type__ == 'InterfaceStructDefinition' or
                def.__type__ == 'EnumStructDefinition'
            ) then
            --- @cast def ClassStructDefinition|InterfaceStructDefinition|EnumStructDefinition

            VM.stepIn();
            class = VM.package.packages.lua.lang.Class.new(def);
            VM.stepOut();

            VM.CLASSES[path] = class;
        end
    end

    return class;
end

debugf(VM.debug.internal, '[VM] :: Loaded %i Modules.', VM.moduleCount);
debugf(VM.debug.internal, '[VM] :: ROOT_PATH = ' .. ROOT_PATH);

debugf(VM.debug.internal, '\n### VM READY ###\n');

return VM;
