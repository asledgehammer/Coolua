---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'PrintPlus';
local errorf = PrintPlus.errorf;

local dump = require 'dump'.any;

local LVMUtils = require 'LVMUtils';
local isArray = LVMUtils.isArray;
local isValidName = LVMUtils.isValidName;
local arrayContainsDuplicates = LVMUtils.arrayContainsDuplicates;

--- @type LVM
local LVM = nil;

local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
};

-- --- @cast API LVMAuditModule

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

function API.auditField(cd, fd)
local errHeader = string.format('Class(%s):addField():', cd.name);

    -- Validate name.
    if not fd.name then
        errorf(2, '%s string property "name" is not provided.', errHeader);
    elseif type(fd.name) ~= 'string' then
        errorf(2, '%s property "name" is not a valid string. {type=%s, value=%s}',
            errHeader, type(fd.name), tostring(fd.name)
        );
    elseif fd.name == '' then
        errorf(2, '%s property "name" is an empty string.', errHeader);
    elseif not isValidName(fd.name) then
        errorf(2,
            '%s property "name" is invalid. (value = %s) (Should only contain A-Z, a-z, 0-9, _, or $ characters)',
            errHeader, fd.name
        );
    elseif cd.declaredFields[fd.name] then
        errorf(2, '%s field already exists: %s', errHeader, fd.name);
    end

    -- Validate types:
    if not fd.types and not fd.type then
        errorf(2, '%s array property "types" or simplified string property "type" are not provided.', errHeader);
    elseif fd.types then
        if type(fd.types) ~= 'table' or not isArray(fd.types) then
            errorf(2, 'types is not an array. {type=%s, value=%s}',
                errHeader, type(fd.types), tostring(fd.types)
            );
        elseif #fd.types == 0 then
            errorf(2, '%s types is empty. (min=1)', errHeader);
        elseif arrayContainsDuplicates(fd.types) then
            errorf(2, '%s types contains duplicate types.', errHeader);
        end

        for i = 1, #fd.types do
            local tType = type(fd.types[i]);
            if tType == 'table' then
                if not fd.type['__type__'] then
                    errorf(2, '%s types[%i] is a table without a "string __type__" property.', errHeader, i);
                elseif type(fd.type['__type__']) ~= 'string' then
                    errorf(2, '%s types[%i].__type__ is not a string.');
                end
                fd.types[i] = type['__type__'];
            elseif tType == 'string' then
                if fd.types[i] == '' then
                    errorf(2, '%s types[%i] is an empty string.', errHeader, i);
                end
            else
                errorf(2, '%s: types[%i] is not a string or { __type__: string }. {type=%s, value=%s}',
                    errHeader, i, type(fd.type), tostring(fd.type)
                );
            end
        end
    else
        local tType = type(fd.type);
        if tType == 'table' then
            if not fd.type['__type__'] then
                errorf(2, '%s property "type" is a table without a "string __type__" property.', errHeader);
            elseif type(fd.type['__type__']) ~= 'string' then
                errorf(2, '%s type.__type__ is not a string.');
            end
            fd.type = fd.type['__type__'];
        elseif tType == 'string' then
            if fd.type == '' then
                errorf(2, '%s property "type" is an empty string.', errHeader);
            end
        else
            errorf(2, '%s: property "type" is not a string. {type=%s, value=%s}',
                errHeader, type(fd.type), tostring(fd.type)
            );
        end

        -- Set the types array and remove the simplified form.
        fd.types = { fd.type };
        fd.type = nil;
    end

    -- Validate value:
    if fd.value ~= LVM.constants.UNINITIALIZED_VALUE then
        if not LVM.type.isAssignableFromType(fd.value, fd.types) then
            errorf(2,
                '%s property "value" is not assignable from "types". {types = %s, value = {type = %s, value = %s}}',
                errHeader, dump(fd.types), type(fd.value), tostring(fd.value)
            );
        end
        fd.assignedOnce = true;
    else
        fd.assignedOnce = false;
    end

    -- Validate scope:
    if fd.scope ~= 'private' and fd.scope ~= 'protected' and fd.scope ~= 'package' and fd.scope ~= 'public' then
        errorf(2,
            '%s The property "scope" given invalid: %s (Can only be: "private", "protected", "package", or "public")',
            errHeader, fd.scope
        );
    end

    -- Validate final:
    if type(fd.final) ~= 'boolean' then
        errorf(2, '%s property "final" is not a boolean. {type = %s, value = %s}',
            errHeader, LVM.type.getType(fd.final), tostring(fd.final)
        );
    end

    -- Validate static:
    if type(fd.static) ~= 'boolean' then
        errorf(2, '%s property "static" is not a boolean. {type = %s, value = %s}',
            errHeader, LVM.type.getType(fd.static), tostring(fd.static)
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

function API.auditParameter(parameter, i, errHeader)
    -- Validate parameter type(s).
    if not parameter.type and not parameter.types then
        errorf(2, '%s Parameter #%i doesn\'t have a defined type string or types string[]. (name = %s)',
            errHeader, i, parameter.name
        );
    else
        if parameter.type and not parameter.types then
            parameter.types = { parameter.type };
            --- @diagnostic disable-next-line
            parameter.type = nil;
        end
    end

    -- Validate parameter name.
    if not parameter.name and not LVM.executable.isVararg(parameter.types[1]) then
        errorf(2, '%s Parameter #%i doesn\'t have a defined name string.', errHeader, i);
    elseif parameter.name == '' then
        errorf(2, '%s Parameter #%i has an empty name string.', errHeader, i);
    end
end

function API.auditParameters(parameters, errHeader)
    if parameters then
        if type(parameters) ~= 'table' or not isArray(parameters) then
            errorf(2, '%s property "parameters" is not a ParameterDefinition[]. {type=%s, value=%s}',
                errHeader, LVM.type.getType(parameters), tostring(parameters)
            );
        end
        -- Convert any simplified type declarations.
        local paramLen = #parameters;
        if paramLen then
            for i = 1, paramLen do
                local param = parameters[i];
                API.auditParameter(param, i, errHeader);
            end
        end
    else
        parameters = {};
    end
    return parameters;
end

function API.auditMethodReturnsProperty(returns, errHeader)
    local types = {};
    -- Validate parameter type(s).
    if not returns then
        types = { 'void' };
    elseif type(returns) == 'table' then
        --- @cast returns table
        if not isArray(returns) then
            errorf(2, '%s The property "returns" is not a any or any[]. {type = %s, value = %s}',
                errHeader, LVM.type.getType(returns), tostring(returns)
            );
        end
        --- @cast returns string[]
        types = returns;
    elseif type(returns) == 'string' then
        --- @cast returns string
        types = { returns };
    end
    return types;
end

function API.auditMethodParamName(name, errHeader)
    -- Validate name.
    if not name then
        errorf(2, '%s string property "name" is not provided.', errHeader);
    elseif type(name) ~= 'string' then
        errorf(2, '%s property "name" is not a valid string. {type=%s, value=%s}',
            errHeader, type(name), tostring(name)
        );
    elseif name == '' then
        errorf(2, '%s property "name" is an empty string.', errHeader);
    elseif not isValidName(name) then
        errorf(2,
            '%s property "name" is invalid. (value = %s) (Should only contain A-Z, a-z, 0-9, _, or $ characters)',
            errHeader, name
        );
    elseif name == 'super' then
        errorf(2, '%s cannot name method "super".', errHeader);
    end

    return name;
end

function API.auditStructPropertyScope(structScope, propertyScope, errHeader)
    if not propertyScope then
        if structScope == 'protected' then
            return 'protected';
        elseif structScope == 'private' then
            return 'private';
        else
            return 'package';
        end
    end

    local invalid = false;
    if structScope == 'package' and propertyScope == 'public' then
        invalid = true;
    elseif structScope == 'protected' and propertyScope == 'public' or propertyScope == 'package' then
        invalid = true;
    elseif structScope == 'private' and propertyScope ~= 'private' then
        invalid = true;
    end
    if invalid then
        errorf(2, '%s Property scope is invalid: {structScope = %s, propertyScope = %s}',
            errHeader, structScope, propertyScope
        );
    end

    return propertyScope;
end

return API;
