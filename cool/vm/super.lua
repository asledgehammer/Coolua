---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;
local debugf = PrintPlus.debugf;

local dump = require 'cool/dump'.any;

local DebugUtils = require 'cool/debug';

--- @type VM
local vm;

--- @type VMSuperModule
local API = {

    __type__ = 'VMModule',

    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
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

        if vm.isInside() then
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
        if vm.isInside() then
            rawset(tbl, field, value);
        else
            errorf(2, '%s Cannot modify SuperTable. (readonly)', cd.printHeader);
        end
    end

    local superStruct = cd.super;
    -- This would only apply to `lua.lang.Object` and any modifications made to it.
    if not superStruct then
        -- Nothing to call. Let the implementation know.
        function mt.__call()
            errorf(2, '%s No superclass.', cd.printHeader);
        end

        setmetatable(super, mt);
        return super;
    end

    -- Copy middle-constructor.
    properties.super = super;
    properties.__middleConstructor = superStruct.__middleConstructor;

    -- Copy middle-methods.
    properties.__middleMethods = superStruct.__middleMethods;

    -- Assign / discover the inferred method in the super-class.

    local function __callConstructor(o, args)
        if cd.path ~= 'lua.lang.StackTraceElement' then
            debugf(vm.debug.super, '[SUPER] :: %s Entering super constructor context', cd.printHeader);
        end

        if cd.path == 'lua.lang.Object' then
            debugf(vm.debug.super, '[SUPER] :: IGNORING object super call in chain.');
            return;
        end

        local constructorStruct = superStruct:getConstructor(args);
        if not constructorStruct then
            errorf(2, '%s Unknown super-constructor: %s', cd.printHeader, dump(args));
            return;
        end

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            struct = cd,
            element = constructorStruct,
            context = 'constructor',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if vm.flags.ENABLE_SCOPE then
            local scopeAllowed = vm.scope.getScopeForCall(constructorStruct.struct, callInfo);
            if not vm.scope.canAccessScope(constructorStruct.scope, scopeAllowed) then
                local errMsg = string.format(
                    'IllegalAccessException: The constructor %s.new(%s) is set as "%s" access level. (Access Level from call: "%s")\n%s',
                    constructorStruct.struct.name, dump(constructorStruct.parameters),
                    constructorStruct.scope, scopeAllowed,
                    vm.stack.printStackTrace()
                );
                vm.stack.popContext();
                print(errMsg);
                error('', 2);
                return;
            end
        end

        vm.stepIn();
        if super.__who__ then
            super.__who__.__super_flag__ = true;
        else
            vm.stack.popContext();
            error('super.__who__ is nil!', 2);
        end
        vm.stepOut();

        vm.stack.popContext();

        --- ClassInstance is below the Object layer.
        if cd.path ~= 'lua.lang.Object' then
            return superStruct.__middleConstructor(o, unpack(args));
        end
    end

    local function __callMethod(o, name, args)
        if cd.path ~= 'lua.lang.StackTraceElement' then
            debugf(vm.debug.super, '[SUPER] :: %s Entering super method context', cd.printHeader);
        end

        --- @type MethodStruct|nil
        local methodStruct = superStruct:getMethod(name, args);

        if not methodStruct then
            errorf(2, '%s Unknown super-method: %s %s', cd.printHeader, name, dump(args));
            return;
        end

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            struct = cd,
            element = methodStruct,
            context = 'method',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if vm.flags.ENABLE_SCOPE then
            local scopeAllowed = vm.scope.getScopeForCall(methodStruct.struct, callInfo);
            if not vm.scope.canAccessScope(methodStruct.scope, scopeAllowed) then
                local sMethod = vm.print.printMethod(methodStruct);
                local errMsg = string.format(
                    'IllegalAccessException: The method %s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                    sMethod,
                    methodStruct.scope, scopeAllowed,
                    vm.stack.printStackTrace()
                );
                vm.stack.popContext();
                print(errMsg);
                error('', 2);
                return;
            end
        end

        local retVal;
        local result, errMsg = xpcall(function()
            if methodStruct.static then
                retVal = methodStruct.body(unpack(args));
            else
                retVal = methodStruct.body(o, unpack(args));
            end
            -- TODO: Check type-cast of returned value.
        end, debug.traceback);

        vm.stack.popContext();

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
            debugf(vm.debug.super, '[SUPER] :: %s Entering super context via call', cd.printHeader);
        end


        local args = { ... };
        table.remove(args, 1);

        -- TODO: Write `__who__` for methods.

        vm.stepIn();
        local who = super.__who__;
        vm.stepOut();

        if who then
            if who.__type__ == 'ConstructorStruct' then
                -- Let upstream calls know super was invoked.
                vm.stepIn();
                super.__call_count__ = super.__call_count__ + 1;
                vm.stepOut();

                return __callConstructor(o, args);
            elseif who.__type__ == 'MethodStruct' then
                return __callMethod(o, who.name, args);
            end
        end

        errorf(2, '%s No who context for super.', cd.name);
    end

    setmetatable(super, mt);
    return super;
end

return API;
