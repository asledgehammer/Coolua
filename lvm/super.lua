---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local DebugUtils = require 'asledgehammer/util/DebugUtils';

local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;
local paramsToString = LVMUtils.paramsToString;
local argsToString = LVMUtils.arrayToString;

--- @type LVM
local LVM;

--- @type LVMSuperModule
local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

function API.createSuperTable(cd, o)
    local super = {};
    local mt = getmetatable(super) or {};

    -- Assign all middle-functions for the super-class here.
    local properties = {};

    mt.__tostring = function()
        return string.format('SuperTable(%s)', cd.path);
    end

    mt.__index = function(_, key)
        if not properties.__middleMethods[key] then
            errorf(2, '%s No super-method exists: %s', cd.printHeader, tostring(key));
        end
        return properties.__middleMethods[key];
    end;

    -- Make SuperTables readonly.

    function mt.__newindex()
        errorf(2, '%s Cannot modify SuperTable. (readonly)', cd.printHeader);
    end

    local superClass = cd.superClass;
    -- This would only apply to `lua.lang.Object` and any modifications made to it.
    if not superClass then
        -- Nothing to call. Let the implementation know.
        function mt.__call()
            errorf(2, '%s No superclass.', cd.printHeader);
        end

        setmetatable(super, mt);
        return super;
    end

    -- Copy middle-constructor.
    properties.super = super;
    properties.__middleConstructor = cd.__middleConstructor;

    -- Copy middle-methods.
    properties.__middleMethods = {};
    local ssd = superClass;
    while ssd do
        for k, v in pairs(cd.superClass.__middleMethods) do
            properties.__middleMethods[k] = v;
        end
        ssd = ssd.superClass;
    end

    -- Assign / discover the inferred method in the super-class.

    local function __callConstructor(o, args)
        local constructorDefinition = superClass:getConstructor(args);
        if not constructorDefinition then
            errorf(2, '%s Unknown super-constructor: %s', cd.printHeader, argsToString(args));
            return;
        end

        LVM.stack.pushContext({
            class = cd,
            element = constructorDefinition,
            context = 'constructor',
            line = DebugUtils.getCurrentLine(3),
            path = DebugUtils.getPath(3)
        });

        local level, relPath = LVM.scope.getRelativePath();

        local callInfo = DebugUtils.getCallInfo(3, LVM.ROOT_PATH, true);
        callInfo.path = relPath;
        local scopeAllowed = LVM.scope.getScopeForCall(constructorDefinition.class, callInfo);

        if not LVM.scope.canAccessScope(constructorDefinition.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The constructor %s.new(%s) is set as "%s" access level. (Access Level from call: "%s")\n%s',
                constructorDefinition.class.name, paramsToString(constructorDefinition.parameters),
                constructorDefinition.scope, scopeAllowed,
                LVM.stack.printStackTrace()
            );
            LVM.stack.popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        local result, errMsg = xpcall(function()
            local retValue = constructorDefinition.func(o, unpack(args));

            -- Make sure that constructors don't return anything.
            if retValue ~= nil then
                errorf(2, '%s Constructor returned non-nil value: {type = %s, value = %s}',
                    cd.printHeader,
                    LVM.type.getType(retValue), tostring(retValue)
                );
                return;
            end

            -- Make sure that final fields are initialized post-constructor.
            LVM.audit.auditFinalFields(cd, o);
        end, debug.traceback);

        LVM.stack.popContext();
        if not result then error(errMsg) end
    end

    local function __callMethod(name, args)
        --- @type MethodDefinition|nil
        local md = superClass:getMethod(name, args);

        if not md then
            errorf(2, '%s Unknown super-method: %s %s', cd.printHeader, name, argsToString(args));
            return;
        end

        LVM.stack.pushContext({
            class = cd,
            element = md,
            context = 'method',
            line = DebugUtils.getCurrentLine(3),
            path = DebugUtils.getPath(3)
        });

        local level, relPath = LVM.scope.getRelativePath();

        local callInfo = DebugUtils.getCallInfo(3, LVM.ROOT_PATH, true);
        callInfo.path = relPath;
        local scopeAllowed = LVM.scope.getScopeForCall(md.class, callInfo);

        if not LVM.scope.canAccessScope(md.scope, scopeAllowed) then
            local sMethod = LVM.print.printMethod(md);
            local errMsg = string.format(
                'IllegalAccessException: The method %s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                sMethod,
                md.scope, scopeAllowed,
                LVM.stack.printStackTrace()
            );
            LVM.stack.popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        local retVal;
        local result, errMsg = xpcall(function()
            if md.static then
                retVal = md.func(unpack(args));
            else
                retVal = md.func(o, unpack(args));
            end
            -- TODO: Check type-cast of returned value.
        end, debug.traceback);

        LVM.stack.popContext();
        if not result then error(errMsg) end

        return retVal;
    end

    function mt.__call(_, ...)
        local args = { ... };
        table.remove(args, 1);

        local ste = LVM.stack.getContext();

        -- Make sure that super can only be called in the context of the class.
        if not ste then
            errorf(2, '%s No super context.', cd.printHeader);
            return;
        end

        local context = ste:getContext();

        if context == 'constructor' then
            __callConstructor(o, args);
        elseif context == 'method' then
            local element = ste:getElement();
            return __callMethod(element.name, args);
        end
    end

    setmetatable(super, mt);
    return super;
end

return API;
