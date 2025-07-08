---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'PrintPlus';
local errorf = PrintPlus.errorf;
local debugf = PrintPlus.debugf;

local dump = require 'dump'.any;

local DebugUtils = require 'DebugUtils';

--- @type LVM
local LVM;

--- @type LVMSuperModule
local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
};

function API.createSuperTable(cd)
    local super = {
        __type__ = 'SuperTable',
        __flag__ = false,
        __call_count__ = 0
    };

    local mt = getmetatable(super) or {};

    -- Assign all middle-functions for the super-class here.
    local properties = {};

    mt.__tostring = function()
        return string.format('SuperTable(%s)', cd.path);
    end

    mt.__index = function(tbl, field)
        -- Ignore Object in super and numeric fields to inspect for array-like checks.
        if cd.path == 'lua.lang.Object' or type(field) == 'number' then
            return nil;
        end

        if LVM.isInside() then
            return rawget(tbl, field);
        else
            if not properties.__middleMethods or not properties.__middleMethods[field] then
                errorf(2, '%s No super-method exists: %s', cd.printHeader, tostring(field));
            end
        end
        -- return properties.__middleMethods[field];
    end;

    -- Make SuperTables readonly.

    function mt.__newindex(tbl, field, value)
        if LVM.isInside() then
            rawset(tbl, field, value);
        else
            errorf(2, '%s Cannot modify SuperTable. (readonly)', cd.printHeader);
        end
    end

    local superClass = cd.super;
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
    properties.__middleConstructor = superClass.__middleConstructor;

    -- Copy middle-methods.
    properties.__middleMethods = superClass.__middleMethods;

    -- Assign / discover the inferred method in the super-class.

    local function __callConstructor(o, args)
        if cd.path ~= 'lua.lang.StackTraceElement' then
            debugf(LVM.debug.super, '[SUPER] :: %s Entering super constructor context', cd.printHeader);
        end

        if cd.path == 'lua.lang.Object' then
            debugf(LVM.debug.super, '[SUPER] :: IGNORING object super call in chain.');
            return;
        end

        local constructorDefinition = superClass:getConstructor(args);
        if not constructorDefinition then
            errorf(2, '%s Unknown super-constructor: %s', cd.printHeader, dump(args));
            return;
        end

        local level, relPath = LVM.scope.getRelativePath();

        LVM.stack.pushContext({
            class = cd,
            element = constructorDefinition,
            context = 'constructor',
            line = DebugUtils.getCurrentLine(level),
            path = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(level, LVM.ROOT_PATH, true);
        callInfo.path = relPath;
        local scopeAllowed = LVM.scope.getScopeForCall(constructorDefinition.class, callInfo);

        if not LVM.scope.canAccessScope(constructorDefinition.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The constructor %s.new(%s) is set as "%s" access level. (Access Level from call: "%s")\n%s',
                constructorDefinition.class.name, dump(constructorDefinition.parameters),
                constructorDefinition.scope, scopeAllowed,
                LVM.stack.printStackTrace()
            );
            LVM.stack.popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        LVM.stepIn();
        if super.__who__ then
            super.__who__.__super_flag__ = true;
        else
            LVM.stack.popContext();
            error('super.__who__ is nil!', 2);
        end
        LVM.stepOut();

        LVM.stack.popContext();

        --- ClassInstance is below the Object layer.
        if cd.path ~= 'lua.lang.Object' then
            return superClass.__middleConstructor(o, unpack(args));
        end
    end

    local function __callMethod(o, name, args)
        if cd.path ~= 'lua.lang.StackTraceElement' then
            debugf(LVM.debug.super, '[SUPER] :: %s Entering super method context', cd.printHeader);
        end

        --- @type MethodDefinition|nil
        local md = superClass:getMethod(name, args);

        if not md then
            errorf(2, '%s Unknown super-method: %s %s', cd.printHeader, name, dump(args));
            return;
        end

        local level, relPath = LVM.scope.getRelativePath();

        LVM.stack.pushContext({
            class = cd,
            element = md,
            context = 'method',
            line = DebugUtils.getCurrentLine(level),
            path = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(level, LVM.ROOT_PATH, true);
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
                retVal = md.body(unpack(args));
            else
                retVal = md.body(o, unpack(args));
            end
            -- TODO: Check type-cast of returned value.
        end, debug.traceback);

        LVM.stack.popContext();

        if not result then error(errMsg) end

        return retVal;
    end

    function mt.__call(o, ...)
        local args = { ... };

        -- Not sure what's causing this situation. If the first arg is the supertable,
        --   remove it.
        if o.__type__ == 'SuperTable' then
            o = table.remove(args, 1);
        end

        if cd.path ~= 'lua.lang.StackTraceElement' then
            debugf(LVM.debug.super, '[SUPER] :: %s Entering super context via call', cd.printHeader);
        end


        local args = { ... };
        table.remove(args, 1);

        -- TODO: Write `__who__` for methods.

        LVM.stepIn();
        local who = super.__who__;
        LVM.stepOut();

        if who then
            if who.__type__ == 'ConstructorDefinition' then
                -- Let upstream calls know super was invoked.
                LVM.stepIn();
                super.__call_count__ = super.__call_count__ + 1;
                LVM.stepOut();

                return __callConstructor(o, args);
            elseif who.__type__ == 'MethodDefinition' then
                return __callMethod(o, who.name, args);
            end
        end

        errorf(2, '%s No who context for super.', cd.name);
    end

    setmetatable(super, mt);
    return super;
end

return API;
