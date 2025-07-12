---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;

local DebugUtils = require 'cool/debug';

--- @type VM
local VM;

--- @type VMStructModule
local API = {

    __type__ = 'VMModule',

    -- Method(s)
    --- @param vm VM
    setVM = function(vm)
        VM = vm;
        VM.moduleCount = VM.moduleCount + 1;
    end
};

function API.calcPathNamePackage(definition, enclosingDefinition)
    local _, path;
    local name;
    local pkg;

    if enclosingDefinition then
        path = enclosingDefinition.path .. '$' .. definition.name;
        pkg = definition.pkg or enclosingDefinition.pkg;
        if not definition.name then
            error('Name not defined for child class.', 3);
        end
        name = definition.name;
    else
        -- Generate the path to use.
        _, path = VM.scope.getRelativePath();

        -- path = DebugUtils.getPath(4, VM.ROOT_PATH, true);
        local split = path:split('.');
        name = table.remove(split, #split);
        pkg = table.concat(split, '.');

        if definition.pkg then pkg = definition.pkg end
        if definition.name then name = definition.name end

        path = pkg .. '.' .. name;
    end

    return {
        path = path,
        name = name,
        pkg = pkg
    };
end

local mt_reference = {
    __tostring = function(self)
        return string.format('Reference(%s)', self.path);
    end,
    -- __index = function(self)
    --     errorf(2, 'Definition is not initialized: %s', self.path);
    -- end,
    __newindex = function(self)
        errorf(2, 'Definition is not initialized: %s', self.path);
    end,
};

function API.newReference(path)
    return setmetatable({ __type__ = 'StructReference', path = path }, mt_reference);
end

return API;
