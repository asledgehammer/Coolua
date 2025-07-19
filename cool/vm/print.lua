---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;

local isArray = require 'cool/vm/utils'.isArray;

--- @type VM
local vm;

--- @type VMPrintModule
local API = {

    __type__ = 'VMModule',

    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

function API.argsToString(args)
    local argsLen = #args;
    if argsLen == 0 then
        return '{}';
    end
    local s = '';
    for i = 1, argsLen do
        local argS = string.format('%i: %s', i, vm.type.getType(args[i]));
        if s == '' then
            s = argS;
        else
            s = s .. ',\n\t' .. argS;
        end
    end
    return string.format('{\n\t%s\n}', s);
end

function API.printExecutable(def)
    if def.__type__ == 'MethodStruct' then
        return API.printMethod(def);
    elseif def.__type__ == 'ConstructorStruct' then
        return API.printConstructor(def);
    else
        errorf(2, 'Unknown ExecutableStruct type: %s', def.__type__);
    end
end

function API.printMethod(def)
    local sStatic = '';
    if def.static then sStatic = 'static ' end
    local sFinal = '';
    if def.final then sFinal = 'final ' end


    local callSyntax;
    if def.static then
        callSyntax = '.';
    else
        callSyntax = ':';
    end

    return string.format('%s%s%s%s%s', sStatic, sFinal, def.struct.name, callSyntax, def.signature);
end

function API.printConstructor(def)
    return string.format('%s:%s', def.struct.name, def.signature);
end

function API.printStruct(def)
    if def.__type__ == 'ClassStruct' then
        return API.printClass(def);
    elseif def.__type__ == 'InterfaceStruct' then
        return API.printInterface(def);
    elseif def.__type__ == 'RecordStruct' then
        return API.printRecord(def);
    end

    errorf(2, 'Unknown Struct type: %s', def.__type__);
    return nil;
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

function API.printClass(def)
    local sScope = '';
    local sStatic = '';
    local sFinal = '';
    local sAbstract = '';
    local sPath = def.path;
    local sExtends = '';
    local sImplements = '';

    if def.scope ~= 'package' then sScope = def.scope .. ' ' end
    if def.abstract then sAbstract = 'abstract ' end
    if def.final then sFinal = 'final ' end
    if def.static then sStatic = 'static ' end

    if def.super and def.super.path ~= 'lua.lang.Object' then
        sExtends = string.format(' extends %s', def.super.path);
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

function API.printRecord(def)
    local sScope = '';
    local sStatic = '';
    local sPath = def.path;
    local sImplements = '';

    if def.scope ~= 'package' then sScope = def.scope .. ' ' end
    if def.static then sStatic = 'static ' end


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

    return string.format('%s%srecord %s%s',
        sScope, sStatic, sPath, sImplements
    );
end

return API;
