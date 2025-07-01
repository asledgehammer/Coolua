---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local DebugUtils = require 'asledgehammer/util/DebugUtils';

local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;
local paramsToString = LVMUtils.paramsToString;

--- @type LVM
local LVM;

--- @type LVMConstructorModule
local API = {

    __type__ = 'LVMModule',

    setLVM = function(lvm) LVM = lvm end
};

function API.resolveConstructor(cons, args)
    
    local argsLen = #args;

    --- @type ConstructorDefinition?
    local consDef = nil;

    -- Try to find the method without varargs first.
    for i = 1, #cons do
        if consDef then break end
        consDef = cons[i];
        local parameters = consDef.parameters or {};
        local paramLen = #parameters;
        if argsLen == paramLen then
            for p = 1, paramLen do
                local arg = args[p];
                local parameter = parameters[p];
                if not LVM.type.isAssignableFromType(arg, parameter.types) then
                    consDef = nil;
                    break;
                end
            end
        else
            consDef = nil;
        end
    end

    -- Check and see if a vararg method exists.
    if not consDef then
        for i = 1, #cons do
            if consDef then break end
            consDef = cons[i];
            local parameters = consDef.parameters or {};
            local paramLen = #parameters;
            if paramLen ~= 0 then
                local lastParameter = parameters[paramLen];
                local lastType = lastParameter.types[i];
                if not LVM.parameter.isVararg(lastType) then
                    consDef = nil;
                    -- If the varArg range doesn't match.
                elseif paramLen > argsLen then
                    consDef = nil;
                else
                    local varArgTypes = LVM.parameter.getVarargTypes(lastType);
                    -- Check normal parameters.
                    for p = 1, paramLen - 1 do
                        local arg = args[p];
                        local parameter = parameters[p];
                        if not LVM.type.isAssignableFromType(arg, parameter.types) then
                            consDef = nil;
                            break;
                        end
                    end
                    -- Check vararg parameters.
                    for p = paramLen, argsLen do
                        local arg = args[p];
                        if not LVM.type.isAssignableFromType(arg, varArgTypes) then
                            consDef = nil;
                            break;
                        end
                    end
                end
            end
        end
    end
    return consDef;
end

function API.createMiddleConstructor(classDef)
    return function(o, ...)
        local args = { ... } or {};
        local cons = classDef:getDeclaredConstructor(args);

        if not cons then
            errorf(2, '%s No constructor signature exists: %s', classDef.printHeader, LVM.print.argsToString(args));
            return;
        end

        LVM.stack.pushContext({
            class = classDef,
            element = cons,
            context = 'constructor',
            line = DebugUtils.getCurrentLine(3),
            path = DebugUtils.getPath(3)
        });

        local level, relPath = LVM.scope.getRelativePath();

        local callInfo = DebugUtils.getCallInfo(3, true);
        callInfo.path = relPath;
        local scopeAllowed = LVM.scope.getScopeForCall(cons.class, callInfo);

        if not LVM.flags.bypassFieldSet and not LVM.scope.canAccessScope(cons.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The constructor %s.new(%s) is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cons.class.name, paramsToString(cons.parameters),
                cons.scope, scopeAllowed,
                LVM.stack.printStackTrace()
            );
            LVM.stack.popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        --- Apply super.
        LVM.flags.canGetSuper = true;
        LVM.flags.canSetSuper = true;
        local lastSuper = o.super;
        o.super = o.__super__;
        LVM.flags.canGetSuper = false;
        LVM.flags.canSetSuper = false;

        local result, errMsg = xpcall(function()
            local retValue = cons.func(o, unpack(args));

            -- Make sure that constructors don't return anything.
            if retValue ~= nil then
                errorf(2, '%s Constructor returned non-nil value: {type = %s, value = %s}',
                    classDef.printHeader,
                    LVM.type.getType(retValue), tostring(retValue)
                );
                return;
            end

            -- Make sure that final fields are initialized post-constructor.
            LVM.audit.auditFinalFields(classDef, o);
        end, debug.traceback);

        --- Revert super.
        LVM.flags.canSetSuper = true;
        o.super = lastSuper;
        LVM.flags.canSetSuper = false;

        LVM.stack.popContext();
        if not result then error(errMsg) end
    end
end

return API;
