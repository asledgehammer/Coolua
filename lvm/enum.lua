---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @type LVM
local LVM;

--- @type LVMEnumModule
local API = {

    __type__ = 'LVMModule',

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

function API.newEnum(definition)

    local ed = {
        -- Internal Type --
        __type__ = 'EnumStructDefinition'

        

    };

    return definition;
end

return API;
