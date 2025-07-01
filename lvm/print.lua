---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;
local isArray = LVMUtils.isArray;
local paramsToString = LVMUtils.paramsToString;

--- @type LVM
local LVM;

--- @type LVMPrintModule
local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

function API.printGenericType(def)
    -- Make sure the def is valid.
    LVM.audit.auditGenericType(def);

    local name = def.name;
    local typesS = table.concat(def.types, '|');
    return string.format('%s: %s', name, typesS);
end

function API.printGenericTypes(def)
    -- Audit array parameter.
    if not def then
        error('Parameter is nil.', 2);
    elseif type(def) ~= 'table' or not isArray(def) then
        errorf(2, 'Parameter is not GenericsTypesDefinition[]. {type = %s, value = %s}',
            type(def),
            tostring(def)
        );
    end

    local defLen = #def;

    if defLen == 0 then return '<>' end

    local s = '';

    for i = 1, defLen do
        local next = defLen[i];
        local nextS = API.printGenericType(next);
        if s == '' then
            s = nextS;
        else
            s = s .. ', ' .. nextS;
        end
    end

    return string.format('<%s>', s);
end

function API.argsToString(args)
    local argsLen = #args;
    if argsLen == 0 then
        return '{}';
    end
    local s = '';
    for i = 1, argsLen do
        local argS = string.format('%i: %s', i, LVM.type.getType(args[i]));
        if s == '' then
            s = argS;
        else
            s = s .. ',\n\t' .. argS;
        end
    end
    return string.format('{\n\t%s\n}', s);
end

function API.printMethod(def)
    local sStatic = '';
    if def.static then sStatic = 'static ' end
    local sFinal = '';
    if def.final then sFinal = 'final ' end

    local sGenerics = '';
    if def.generics then
        -- TODO: Implement printing generics.
        sGenerics = API.printGenericTypes(def.generics);
    end

    local sParams;
    local callSyntax;
    if def.static then
        sParams = paramsToString(def.parameters);
        callSyntax = '.';
    else
        sParams = paramsToString(def.parameters);
        callSyntax = ':';
    end
    return string.format('%s%s%s%s%s%s(%s)', sStatic, sFinal, sGenerics, def.class.name, callSyntax, def.name, sParams);
end

return API;
