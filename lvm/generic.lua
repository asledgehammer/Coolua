---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;
local isArray = LVMUtils.isArray;

--- @type LVM
local LVM;

--- @type LVMGenericModule
local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

function API.compileGenericTypesDefinition(cd, gdefParam)
    -- Check Generics definition.
    local generics = {};
    if gdefParam then
        for i = 1, #gdefParam do
            local gDefParam = gdefParam[i];

            -- Audit & compile name string.
            local name = gDefParam.name;
            if not name then
                errorf(2, '%s Generic parameter #%i has no name.', cd.printHeader);
            end

            -- Audit & compile types table.
            local types = {};
            if gDefParam.type and gDefParam.types then
                errorf(2, '%s Generic parameter #%i has both "type" and "types" defined. (Can only have one)',
                    cd.printHeader);
            elseif gDefParam.types then
                if type(gDefParam.types) ~= 'table' or not isArray(gDefParam.types) then
                    errorf(2, '%s Generic parameter %i types is not array. {type = %s, value = %s}',
                        cd.printHeader, i,
                        LVM.type.getType(gDefParam.types), tostring(gDefParam.types)
                    );
                elseif #gDefParam.types == 0 then
                    errorf(2, '%s Generic parameter %i types is empty array.', cd.printHeader, i);
                end

                types = gDefParam.types;
            elseif gDefParam.type then
                types = { gDefParam.type };
            else
                errorf(2, '%s Generic parameter %i doesn\'t have a defined type or types.',
                    cd.printHeader,
                    i
                );
            end

            -- Set the compiled generics table.
            generics[name] = { name, types };
        end
    end
    return generics;
end

return API;
