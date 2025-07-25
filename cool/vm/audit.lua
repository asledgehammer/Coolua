---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;

local dump = require 'cool/dump'.any;

local utils = require 'cool/vm/utils';
local arrayContainsDuplicates = utils.arrayContainsDuplicates;
local isArray = utils.isArray;
local isValidName = utils.isValidName;

--- @type VM
local vm = nil;

local API = {

    __type__ = 'VMModule',

    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

-- --- @cast API VMAuditModule

function API.auditEntry(rd, ed)
    local errHeader = string.format('Record(%s):addEntry():', rd.name);

    API.auditName(ed.name, errHeader);

    if rd.declaredFields[ed.name] then
        errorf(2, '%s record already exists: %s', errHeader, ed.name);
    end

    -- Validate types:
    if not ed.types and not ed.type then
        errorf(2, '%s array property "types" or simplified string property "type" are not provided.', errHeader);
    elseif ed.types then
        if type(ed.types) ~= 'table' or not isArray(ed.types) then
            errorf(2, 'types is not an array. {type=%s, value=%s}',
                errHeader, type(ed.types), tostring(ed.types)
            );
        elseif #ed.types == 0 then
            errorf(2, '%s types is empty. (min=1)', errHeader);
        elseif arrayContainsDuplicates(ed.types) then
            errorf(2, '%s types contains duplicate types.', errHeader);
        end

        for i = 1, #ed.types do
            local tType = type(ed.types[i]);
            if tType == 'table' then
                if not ed.type['__type__'] then
                    errorf(2, '%s types[%i] is a table without a "string __type__" property.', errHeader, i);
                elseif type(ed.type['__type__']) ~= 'string' then
                    errorf(2, '%s types[%i].__type__ is not a string.');
                end
                ed.types[i] = type['__type__'];
            elseif tType == 'string' then
                if ed.types[i] == '' then
                    errorf(2, '%s types[%i] is an empty string.', errHeader, i);
                end
            else
                errorf(2, '%s: types[%i] is not a string or { __type__: string }. {type=%s, value=%s}',
                    errHeader, i, type(ed.type), tostring(ed.type)
                );
            end
        end
    else
        local tType = type(ed.type);
        if tType == 'table' then
            if not ed.type['__type__'] then
                errorf(2, '%s property "type" is a table without a "string __type__" property.', errHeader);
            elseif type(ed.type['__type__']) ~= 'string' then
                errorf(2, '%s type.__type__ is not a string.');
            end
            ed.type = ed.type['__type__'];
        elseif tType == 'string' then
            if ed.type == '' then
                errorf(2, '%s property "type" is an empty string.', errHeader);
            end
        else
            errorf(2, '%s: property "type" is not a string. {type=%s, value=%s}',
                errHeader, type(ed.type), tostring(ed.type)
            );
        end

        -- Set the types array and remove the simplified form.
        ed.types = { ed.type };
        ed.type = nil;
    end

    -- Validate value:
    if ed.value ~= vm.constants.UNINITIALIZED_VALUE then
        if not vm.type.isAssignableFromTypes(ed.value, ed.types) then
            errorf(2,
                '%s property "value" is not assignable from "types". {types = %s, value = {type = %s, value = %s}}',
                errHeader, dump(ed.types), type(ed.value), tostring(ed.value)
            );
        end
        ed.assignedOnce = true;
    else
        ed.assignedOnce = false;
    end
end

function API.auditField(cd, fd)
    local errHeader = string.format('Class(%s):addField():', cd.name);

    -- Validate name.
    API.auditName(fd.name, errHeader);

    if cd.declaredFields[fd.name] then
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
    if fd.value ~= vm.constants.UNINITIALIZED_VALUE then
        if not vm.type.isAssignableFromTypes(fd.value, fd.types) then
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
            errHeader, vm.type.getType(fd.final), tostring(fd.final)
        );
    end

    -- Validate static:
    if type(fd.static) ~= 'boolean' then
        errorf(2, '%s property "static" is not a boolean. {type = %s, value = %s}',
            errHeader, vm.type.getType(fd.static), tostring(fd.static)
        );
    end
end

function API.auditFinalFields(cd, o)
    local fields = cd.declaredFields;
    for name, fd in pairs(fields) do
        local fieldValue = o[name];
        if fd.final and fieldValue == vm.constants.UNINITIALIZED_VALUE then
            errorf(2, '%s Field is not initialized: %s (Check the FieldStructs and Constructors)',
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
        errorf(2, '%s Parameter #%i doesn\'t have a defined type or types array. (name = %s)',
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
    API.auditName(parameter.name, errHeader);
end

function API.auditParameters(parameters, errHeader)
    if parameters then
        if not parameters or type(parameters) ~= 'table' or not isArray(parameters) then
            errorf(2, '%s property "parameters" is not a ParameterStruct[]. {type=%s, value=%s}',
                errHeader, vm.type.getType(parameters), tostring(parameters)
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

function API.auditMethodReturnsProperty(returnTypes, errHeader)
    local types = {};
    -- Validate parameter type(s).
    if not returnTypes then
        types = { 'void' };
    elseif type(returnTypes) == 'table' then
        --- @cast returnTypes table
        if returnTypes.__type__ then
            if returnTypes.__type__ ~= 'ClassStruct' and returnTypes.__type__ ~= 'InterfaceStruct' then
                errorf(2,
                    '%s The property "returnTypes" is not an array of types, a class or interface.' ..
                    ' {type = %s, value = %s}',
                    errHeader, vm.type.getType(returnTypes), dump(returnTypes)
                );
            end
            types = { returnTypes };
        elseif not isArray(returnTypes) then
            errorf(2,
                '%s The property "returnTypes" is not an array of types, a class or interface.' ..
                ' {type = %s, value = %s}',
                errHeader, vm.type.getType(returnTypes), dump(returnTypes)
            );
        end
        --- @cast returnTypes string[]
        types = returnTypes;
    elseif type(returnTypes) == 'string' then
        --- @cast returnTypes string
        types = { returnTypes };
    end
    return types;
end

function API.auditMethodParamName(name, errHeader)
    API.auditName(name, errHeader);
    if name == 'super' then
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
    return propertyScope;
end

--- Audits and ensures that entities with name-contexts follows the Lua naming rules on characters, also checking for
--- empty, other-types, or missing definitions.
---
--- @param name string|nil
--- @param errHeader string
function API.auditName(name, errHeader)
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
            '%s property "name" is invalid. (value = %s) (Should only contain A-Z, a-z, 0-9, or _ characters, and cannot start with numbers)',
            errHeader, name
        );
    end
end

return API;
