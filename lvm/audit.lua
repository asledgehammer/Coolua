---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVMUtils = require 'LVMUtils';
local isArray = LVMUtils.isArray;
local isValidName = LVMUtils.isValidName;
local errorf = LVMUtils.errorf;

--- @type LVM
local LVM = nil;

--- @type LVMAuditModule
local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

--- @param def ParameterDefinition
function API.auditParameter(def)
    if not def then
        error('Parameter is nil.', 2);
    elseif def.__type__ ~= 'ParameterDefinition' then
        errorf(2, 'Parameter is not a ParameterDefinition. {type = %s, value = %s}',
            LVM.type.getType(def),
            tostring(def)
        );
    end

    -- Audit name.
    if not def.name then
        error('The parameter doesn\'t have a name.', 2);
    elseif def.name == '' then
        error('The parameter has an empty name.', 2);
    elseif isValidName(def.name) then
        errorf(2, 'The parameter has a name with invalid characters: %s (Valid characters: [A-Z, a,z, 0-9, $, _, -])');
    end

    -- Audit types.
    if not def.types then
        errorf(2, 'The parameter "%s" has no type(s).', def.name);
    elseif #def.types == 0 then
        errorf(2, 'The parameter "%s" has no type(s).', def.name);
    end

    LVM.flags.canSetAudit = true;
    def.audited = true;
    LVM.flags.canSetAudit = false;
end

--- @param def GenericTypeDefinition
function API.auditGenericType(def)
    if not def.__type__ ~= 'GenericTypeDefinition' then
        errorf(2, 'Parameter is not a GenericTypeDefinition. {type = %s, value = %s}',
            LVM.type.getType(def),
            tostring(def)
        );
    end

    if not def.name then
        errorf(2, 'Property "name" is nil. (Must be a non-empty string)');
    elseif def.name == '' then
        errorf(2, 'Property "name" is an empty string. (Must be a non-empty string)');
    end

    if not def.types then
        errorf(2, 'Property "types" is nil. (Must be an array))');
    elseif type(def.types) == 'table' or not isArray(def.types) then
        errorf(2, 'Property "types" is not an array. {type = %s, value = %s}',
            LVM.type.getType(def),
            tostring(def)
        );
    end
end

function API.auditFinalFields(cd, o)
    local fields = cd.declaredFields;
    for name, fd in pairs(fields) do
        local fieldValue = o[name];
        if fd.final and fieldValue == LVM.constants.UNINITIALIZED_VALUE then
            errorf(2, '%s Field is not initialized: %s (Check the FieldDefinitions and Constructors)',
                cd.printHeader, name
            );
        end
    end
end

function API.auditConstructor(def)

end

return API;
