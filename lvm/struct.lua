--- @type LVM
local LVM;

--- @type LVMStructModule
local API = {

    __type__ = 'LVMModule',

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

function API.calcPathNamePackage(definition, enclosingDefinition)
    local path;
    local name;
    local package;

if enclosingDefinition then
        path = enclosingDefinition.path .. '$' .. enclosingDefinition.name;

        package = definition.pkg or enclosingDefinition.package;

        if not definition.name then
            error('Name not defined for child class.', 2);
        end
        name = definition.name;
    else
        -- Generate the path to use.
        path = DebugUtils.getPath(3, LVM.ROOT_PATH, true);
        local split = path:split('.');
        name = table.remove(split, #split);
        package = table.join(split, '.');

        if definition.pkg then
            package = definition.pkg;
        end

        if definition.name then
            name = definition.name;
        end

        path = package .. '.' .. name;
    end

    return {
        path = path,
        name = name,
        package = package
    };
end

return API;
