local DebugUtils = require 'asledgehammer/util/DebugUtils';

local OOPUtils = require 'asledgehammer/util/OOPUtils';
local errorf = OOPUtils.errorf;
local paramsToString = OOPUtils.paramsToString;

--- @type LVM
local LVM;

--- @type LVMConstructorModule
local API = {

    __type__ = 'LVMModule',

    setLVM = function(lvm) LVM = lvm end
};

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

        if not LVM.scope.canAccessScope(cons.scope, scopeAllowed) then
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
