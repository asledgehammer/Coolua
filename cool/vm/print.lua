---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;

local isArray = require 'cool/vm/utils'.isArray;

--- @type VM
local VM;

--- @type VMPrintModule
local API = {

    __type__ = 'VMModule',

    --- @param vm VM
    setVM = function(vm)
        VM = vm;
        VM.moduleCount = VM.moduleCount + 1;
    end
};

function API.printGenericType(def)
    -- Make sure the def is valid.
    VM.audit.auditGenericType(def);

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
        local argS = string.format('%i: %s', i, VM.type.getType(args[i]));
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

    local callSyntax;
    if def.static then
        callSyntax = '.';
    else
        callSyntax = ':';
    end

    return string.format('%s%s%s%s%s%s', sStatic, sFinal, sGenerics, def.class.name, callSyntax, def.signature);
end

function API.printInterface(def)
    local sScope = def.scope .. ' ';
    local sStatic = '';
    local sPkg = def.pkg;
    local sName = def.name;
    local sExtends = '';

    if def.static then sStatic = 'static ' end
    if sPkg ~= '' then sPkg = sPkg .. '.' end

    if def.super then
        local sSuperPkg = '';
        if def.super.pkg then sSuperPkg = def.super.pkg .. '.' end
        sExtends = string.format(' extends %s%s', sSuperPkg, def.super.name);
    end

    return string.format('%s%sinterface %s%s%s',
        sScope, sStatic, sPkg, sName, sExtends
    );
end

function API.printStruct(def)
    
    if def.__type__ == 'ClassStructDefinition' then
        return API.printClass(def);
    elseif def.__type__ == 'InterfaceStructDefinition' then
        return API.printInterface(def);
    end

    errorf(2, 'Unknown StructDefinition type: %s', def.__type__);
    return nil;
end

function API.printClass(def)
    local sScope = def.scope .. ' ';
    local sStatic = '';
    local sFinal = '';
    local sAbstract = '';
    local sPath = def.path;
    local sExtends = '';
    local sImplements = '';

    if def.abstract then sAbstract = 'abstract ' end
    if def.final then sFinal = 'final ' end
    if def.static then sStatic = 'static ' end

    if def.super and def.super.path ~= 'lua.lang.Object' then
        local sSuperPkg = '';
        if def.super.pkg then sSuperPkg = def.super.pkg .. '.' end
        sExtends = string.format(' extends %s%s', sSuperPkg, def.super.path);
    end

    if def.interfaces then
        for i = 1, #def.interfaces do
            local interface = def.interfaces[i];
            local sInterfacePkg = '';
            if interface.pkg then sInterfacePkg = interface.pkg .. '.' end
            local sInterface = string.format('%s%s', sInterfacePkg, interface.path);
            if sImplements == '' then
                sImplements = sInterface;
            else
                sImplements = sImplements .. ', ' .. sInterface;
            end
        end
        if sImplements ~= '' then
            sImplements = ' implements ' .. sImplements;
        end
    end

    return string.format('%s%s%s%sclass %s%s%s',
        sScope, sStatic, sAbstract, sFinal, sPath, sExtends, sImplements
    );
end

return API;
