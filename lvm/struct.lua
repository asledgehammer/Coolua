local DebugUtils = require 'DebugUtils';

--- @type LVM
local LVM;

--- @type LVMStructModule
local API = {

    __type__ = 'LVMModule',

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
};

function API.calcPathNamePackage(definition, enclosingDefinition)
    local _, path;
    local name;
    local pkg;

if enclosingDefinition then
        path = enclosingDefinition.path .. '$' .. enclosingDefinition.name;
        pkg = definition.pkg or enclosingDefinition.pkg;
        if not definition.name then
            error('Name not defined for child class.', 3);
        end
        name = definition.name;
    else
        -- Generate the path to use.
        _, path = LVM.scope.getRelativePath();
        -- path = DebugUtils.getPath(4, LVM.ROOT_PATH, true);
        local split = path:split('.');
        name = table.remove(split, #split);
        pkg = table.join(split, '.');

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

return API;
