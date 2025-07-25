---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local dump = require 'cool/dump'.any;

local DebugUtils = require 'cool/debug';

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;
local debugf = PrintPlus.debugf;

--- @type VM
local vm;

local arrayContains = require 'cool/vm/utils'.arrayContains;

local API;
API = {

    __type__ = 'VMModule',

    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
        API.defaultSuperFuncInfo = API.getExecutableInfo(API.defaultSuperFunc);
    end
};

function API.getExecutableInfo(func)
    if not func then
        return { start = -1, stop = -1, path = '' };
    end
    local info = DebugUtils.getFuncInfo(func, vm.ROOT_PATH, true);
    return { start = info.start, stop = info.stop, path = info.path };
end

--- @cast API VMExecutableModule

function API.argsToTypes(args)
    local tArgs = {};
    for i = 1, #args do
        table.insert(tArgs, vm.type.getType(args[i]));
    end
    return tArgs;
end

function API.resolveMethod(struct, name, methods, args)
    local callSignature = vm.executable.createCallSignature(name, args);

    --- @type MethodStruct|nil
    local md;

    -- Check the cache.
    md = struct.methodCache[callSignature];
    if md then return md end

    debugf(vm.debug.executableCache, '[EXECUTABLE_CACHE] :: %s NO cache found for method %s call signature: %s',
        struct.printHeader,
        name,
        callSignature
    );

    -- Attempt to resolve the method using exact method signature checks.
    --- @type MethodStruct?
    md = methods[callSignature];
    if md then
        debugf(vm.debug.executableCache, '[EXECUTABLE_CACHE] :: %s Caching exact method %s call signature: %s',
            struct.printHeader,
            vm.print.printMethod(md),
            callSignature
        );

        -- Cache the result.
        struct.methodCache[callSignature] = md;
    end

    -- If the method still isn't identified, look into each argument and match.
    if not md then
        md = API.resolveMethodDeep(methods, args);
    end

    if md then
        debugf(vm.debug.executableCache, '[EXECUTABLE_CACHE] :: %s Caching method %s call signature: %s',
            struct.printHeader,
            vm.print.printMethod(md),
            callSignature
        );

        -- Cache the result.
        struct.methodCache[callSignature] = md;
    end

    return md;
end

--- @param methods table<string, MethodStruct>
--- @param args any[]
---
--- @return MethodStruct|nil
function API.resolveMethodDeep(methods, args)
    --- @type MethodStruct?
    local md = nil;

    -- Try to find the method without varargs first.
    for _, method in pairs(methods) do
        if API.checkArguments(method, args) then
            md = method;
            break;
        end
    end

    return md;
end

--- @param struct Struct
function API.createMiddleMethods(struct)
    struct.__middleMethods = {};

    -- Insert boilerplate method invoker function.
    for mName, methodCluster in pairs(struct.methods) do
        for _, md in pairs(methodCluster) do
            if md.override then
                -- RULE: Cannot override method if super-method is final.
                if md.super.final then
                    local sMethod = vm.print.printMethod(md);
                    errorf(2, '%s Method cannot override final method in super-class: %s.%s',
                        struct.printHeader,
                        md.super.struct.name,
                        mName,
                        sMethod
                    );
                    return struct;
                    -- RULE: Cannot reduce scope of overrided super-method.
                elseif not vm.scope.canAccessScope(md.scope, md.super.scope) then
                    local sMethod = vm.print.printMethod(md);
                    errorf(2, '%s Method cannot reduce scope of super-class: %s (super-scope = %s, struct-scope = %s)',
                        struct.printHeader,
                        sMethod, md.super.scope, md.scope
                    );
                    return struct;
                    -- RULE: override Methods must either be consistently static (or not) with their super-method(s).
                elseif md.static ~= md.super.static then
                    local sMethod = vm.print.printMethod(md);
                    errorf(2,
                        '%s All method(s) with identical signatures must either be static or not: %s (super.static = %s, struct.static = %s)',
                        struct.printHeader,
                        sMethod, tostring(md.super.static), tostring(md.static)
                    );
                    return struct;
                end
            end
        end
        struct.__middleMethods[mName] = vm.executable.createMiddleMethod(struct, mName, methodCluster);
    end
end

function API.createMiddleMethod(cd, name, methods)
    --- @param o ClassInstance
    return function(o, ...)
        if not cd.__readonly__ then
            cd:finalize();
        end

        local args = { ... };

        local md = API.resolveMethod(cd, name, methods, args);
        if not md then
            if #args ~= 0 and o.__table_id__ == args[1].__table_id__ then
                table.remove(args, 1);
                md = API.resolveMethod(cd, name, methods, args);
            end
        end

        local errHeader = string.format('Class(%s):%s():', cd.path, name);

        if not md then
            errorf(2, '%s No method signature exists: %s', errHeader, vm.print.argsToString(args));
            return;
        end

        errHeader = string.format('Class(%s):%s():', cd.path, md.signature);

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            struct = cd,
            element = md,
            context = 'method',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if vm.flags.ENABLE_SCOPE then
            -- Ensure that the class is accessible from the scope.
            local classScopeAllowed = vm.scope.getScopeForCall(cd, callInfo);
            if not vm.scope.canAccessScope(cd.scope, classScopeAllowed) then
                local sClass = cd.path;
                local errMsg = string.format(
                    'IllegalAccessException: The class "%s" is "%s".' ..
                    ' (Access Level from call: "%s")\n%s',
                    sClass,
                    cd.scope, classScopeAllowed,
                    vm.stack.printStackTrace()
                );
                print(errMsg);
                error(errMsg, 2);
                return;
            end

            local methodScopeAllowed = vm.scope.getScopeForCall(cd, callInfo);
            if not vm.scope.canAccessScope(md.scope, methodScopeAllowed) then
                local sMethod = vm.print.printMethod(md);
                local errMsg = string.format(
                    'IllegalAccessException: The method %s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                    sMethod,
                    md.scope, methodScopeAllowed,
                    vm.stack.printStackTrace()
                );
                vm.stack.popContext();
                print(errMsg);
                error(errMsg, 2);
                return;
            end
        end

        local lastWho;
        local lastSuper;
        if o then
            --- Apply super.
            vm.stepIn();
            lastSuper = o.super;
            o.super = cd.__supertable__;
            lastWho = o.super.__who__;
            o.super.__who__ = md;
            vm.stepOut();
        end

        local retVal = nil;
        local result, errMsg = xpcall(function()
            if md.static then
                retVal = md.body(unpack(args));
            else
                retVal = md.body(o, unpack(args));
            end
            -- TODO: Check type-cast of returned value.
        end, debug.traceback);

        if o then
            --- Revert super.
            vm.stepIn();
            o.super.__who__ = lastWho;
            o.super = lastSuper;
            vm.stepOut();
        end

        -- Throw the error after applying context.
        if not result then error(tostring(errMsg) or '', 2) end

        -- Audit void type methods.
        if retVal ~= nil and md.returnTypes == 'void' then
            errMsg = string.format('Invoked Method is void and returned value: {type = %s, value = %s}',
                type(retVal),
                tostring(retVal)
            );
            print(errMsg);
            vm.stack.popContext();
            error(errMsg, 2);
            return;
        end

        -- Audit return-type methods.

        if not vm.type.isAssignableFromTypes(retVal, md.returnTypes) then
            errMsg = string.format('%s: Invalid type for returned value: {type = "%s", value = %s}'
                .. ' (Allowed type(s): %s)',
                md.signature,
                type(retVal),
                dump(retVal),
                dump(md.returnTypes)
            );
            print(errMsg);
            vm.stack.popContext();
            error(errMsg, 2);
            return;
        end

        vm.stack.popContext();

        return retVal;
    end;
end

function API.createParameterSignatureFragment(parameters)
    local parameterLen = #parameters;
    if parameterLen == 0 then return '()' end

    local s = '';
    for i = 1, parameterLen do
        local sParameter = API.combineParameterTypes(parameters[i]);
        if s == '' then
            s = sParameter;
        else
            s = string.format('%s, %s', s, sParameter);
        end
    end

    return string.format('(%s)', s);
end

function API.getDeclaredMethodNames(struct, array)
    --- @type string[]
    array = array or {};

    local decMethods = struct.declaredMethods;
    for name, _ in pairs(decMethods) do
        if not arrayContains(array, name) then
            table.insert(array, name);
        end
    end

    return array;
end

function API.getMethodNames(classDef, methodNames)
    methodNames = methodNames or {};

    vm.stepIn();
    -- Grab any super-struct declarations.
    if classDef['super'] then
        --- @cast classDef ClassStruct|InterfaceStruct
        API.getMethodNames(classDef.super, methodNames);
    end

    -- Grab any interface declarations.
    if classDef['interfaces'] then
        --- @cast classDef ClassStruct
        local interfaceLen = #classDef.interfaces;
        if interfaceLen ~= 0 then
            for i = 1, interfaceLen do
                API.getMethodNames(classDef.interfaces[i], methodNames);
            end
        end
    end

    vm.stepOut();

    -- Get struct-specific declarations.
    API.getDeclaredMethodNames(classDef, methodNames);

    return methodNames;
end

--- @param def Struct
--- @param name string
--- @param comb table<string, MethodStruct[]>
function API.combineAllMethods(def, name, comb)
    comb = comb or {};

    local combCluster = comb[name];
    if not combCluster then
        combCluster = {};
        comb[name] = combCluster;
    end

    vm.stepIn();
    -- Grab all the super-context methods first.
    if def['super'] then
        --- @cast def ClassStruct|InterfaceStruct
        API.combineAllMethods(def.super, name, comb);
    end

    if def['interfaces'] then
        --- @cast def ClassStruct
        -- Copy any interface method array.
        local interfaceLen = #def.interfaces;
        if interfaceLen ~= 0 then
            for i = 1, interfaceLen do
                local interface = def.interfaces[i];

                API.combineAllMethods(interface, name, comb);

                if interface.methods[name] then
                    local imCluster = interface.methods[name];

                    for imSignature, imd in pairs(imCluster) do
                        -- Here we ignore re-applied interface methods since they're already applied.
                        if not combCluster[name] and not imd.default then
                            debugf(vm.debug.method,
                                '[METHOD] :: %s IGNORING re-applied interface method in hierarchy: %s',
                                def.printHeader,
                                vm.print.printMethod(imd)
                            );
                        else
                            debugf(vm.debug.method, '[METHOD] :: %s Applying interface method in hierarchy: %s',
                                def.printHeader,
                                vm.print.printMethod(imd)
                            );
                        end
                        combCluster[imSignature] = imd;
                    end
                end
            end
        end
    end

    vm.stepOut();

    local decCluster = def.declaredMethods[name];

    if decCluster then
        -- Go through each declaration and try to find a super-class one.
        for decSig, decMethod in pairs(decCluster) do
            -- If signatures match, an override is detected.
            if combCluster[decSig] then
                vm.stepIn();
                decMethod.override = true;
                decMethod.super = combCluster[decSig];
                vm.stepOut();

                debugf(vm.debug.method, '[METHOD] :: %s OVERRIDING class method %s in hierarchy: %s',
                    def.printHeader,
                    vm.print.printMethod(combCluster[decSig]),
                    vm.print.printMethod(decMethod)
                );
            end
            -- Assign the top-most class method definition.
            combCluster[decSig] = decMethod;
        end
    end

    return comb;
end

--- @param self Struct
function API.compileMethods(self)
    debugf(vm.debug.method, '[METHOD] :: %s Compiling method(s)..', self.printHeader);

    self.methods = {};

    local methodNames = API.getMethodNames(self);
    for i = 1, #methodNames do
        local mName = methodNames[i];
        -- Ignore constructors.
        if mName ~= 'new' then
            API.combineAllMethods(self, mName, self.methods);
        end
    end

    local count = 0;

    -- Make sure that all methods exposed are not abstract in non-abstract classes.
    if self.__type__ ~= 'InterfaceStruct' and not self['abstract'] then
        for _, methodCluster in pairs(self.methods) do
            -- Ignore constructors.
            for _, method in pairs(methodCluster) do
                -- Ignore constructors.
                if method.abstract then
                    local errMsg = string.format('%s Abstract method not implemented: %s',
                        self.printHeader, vm.print.printMethod(method)
                    );
                    print(errMsg);
                    error(errMsg, 3);
                elseif method.interface and not method.default then
                    local errMsg = string.format('%s Interface method not implemented: %s',
                        self.printHeader, vm.print.printMethod(method)
                    );
                    print(errMsg);
                    error(errMsg, 3);
                end
                count = count + 1;
            end
        end
    end

    debugf(vm.debug.method, '[METHOD] :: %s Compiled %i method(s).', self.printHeader, count);
end

function API.getDeclaredMethodFromLine(struct, path, line)
    for _, mCluster in pairs(struct.declaredMethods) do
        for _, md in pairs(mCluster) do
            if path == md.bodyInfo.path and line >= md.bodyInfo.start and line <= md.bodyInfo.stop then
                return md;
            end
        end
    end
    return nil;
end

--- @param struct ClassStruct|InterfaceStruct
--- @param path string
--- @param line number
---
--- @return ExecutableStruct|nil
function API.getExecutableFromLine(struct, path, line)
    --- @type ExecutableStruct|nil
    local ed = API.getDeclaredMethodFromLine(struct, path, line);
    if not ed and struct.__type__ == 'ClassStruct' then
        ed = vm.executable.getConstructorFromLine(struct, path, line);
    end
    return ed;
end

--- @param self Object
function API.defaultSuperFunc(self)
    self:super();
end

function API.checkArguments(executable, args)
    local argsLen = #args;
    local valid = true;

    -- Try to find the method without varargs first.
    local parameters = executable.parameters;
    local paramLen = #parameters;
    local parameter;
    local arg;

    if executable.vararg then
        local lastParameter;
        local varArgTypes;

        parameters = executable.parameters;
        paramLen = #parameters;
        if paramLen ~= 0 then
            lastParameter = parameters[paramLen];
            -- Subtract 1 because varargs can be empty.
            if paramLen - 1 > argsLen then
                valid = false;
            else
                varArgTypes = lastParameter.types;

                -- Check normal parameters.
                for p = 1, paramLen - 1 do
                    arg = args[p];
                    parameter = parameters[p];
                    if not vm.type.isAssignableFromTypes(arg, parameter.types) then
                        valid = false;
                        break;
                    end
                end

                -- Check vararg parameters.
                if valid then
                    for p = paramLen, argsLen do
                        arg = args[p];
                        if not vm.type.isAssignableFromTypes(arg, varArgTypes) then
                            valid = false;
                            break;
                        end
                    end
                end
            end
        end
    else
        if argsLen == paramLen then
            for p = 1, paramLen do
                arg = args[p];
                parameter = parameters[p];
                if not vm.type.isAssignableFromTypes(arg, parameter.types) then
                    valid = false;
                    break;
                end
            end
        else
            valid = false;
        end
    end

    if vm.debug.executable then
        vm.stepIn();
        -- All this does is compile useful debug arguments array as a string.
        local argsS = '';
        for i = 1, argsLen do
            arg = args[i];
            local argS;
            if type(arg) == 'table' then
                if arg.__struct__ then
                    argS = '<ClassInstance:' .. arg.__struct__.path .. '>';
                elseif arg.__type__ then
                    argS = '<' .. arg.__type__ .. ':' .. arg.__type__ .. '>';
                end
            else
                argS = tostring(arg);
            end
            if argsS == '' then
                argsS = argS;
            else
                argsS = argsS .. ', ' .. argS;
            end
        end
        argsS = '[' .. argsS .. ']';
        vm.stepOut();
        PrintPlus.printf('[EXECUTABLE] :: executable.checkArguments(%s, %s) = %s',
            vm.print.printExecutable(executable), argsS, tostring(valid)
        );
    end


    return valid;
end

-- MARK: - <constructor>

--- @param struct Struct
--- @param constructors ConstructorStruct[]
--- @param args any[]
---
--- @return ConstructorStruct|nil
function API.resolveConstructor(struct, constructors, args)
    local callSignature = vm.executable.createCallSignature('(constructor)', args);

    --- @type ConstructorStruct|nil
    local cd;

    -- Check the cache.
    cd = struct.methodCache[callSignature];
    if cd then return cd end

    debugf(vm.debug.executableCache, '[EXECUTABLE_CACHE] :: %s No cache found for call signature: %s',
        struct.printHeader,
        '(constructor)',
        callSignature
    );

    -- Attempt to resolve the method using exact method signature checks.
    --- @type ConstructorStruct?
    cd = constructors[callSignature];
    if cd then
        debugf(vm.debug.executableCache, '[EXECUTABLE_CACHE] :: %s Caching exact constructor %s call signature: %s',
            struct.printHeader,
            vm.print.printConstructor(cd),
            callSignature
        );

        -- Cache the result.
        struct.methodCache[callSignature] = cd;
    end

    -- If the method still isn't identified, look into each argument and match.
    if not cd then
        cd = API.resolveConstructorDeep(constructors, args);
    end

    if cd then
        debugf(vm.debug.executableCache, '[EXECUTABLE_CACHE] :: %s Caching constructor %s call signature: %s',
            struct.printHeader,
            vm.print.printConstructor(cd),
            callSignature
        );

        -- Cache the result.
        struct.methodCache[callSignature] = cd;
    end

    return cd;
end

function API.resolveConstructorDeep(constructors, args)
    local argsLen = #args;

    --- @type ConstructorStruct?
    local consDef = nil;

    -- Try to find the method without varargs first.
    for i = 1, #constructors do
        if consDef then break end
        consDef = constructors[i];
        local parameters = consDef.parameters or {};
        local paramLen = #parameters;
        if argsLen == paramLen then
            for p = 1, paramLen do
                local arg = args[p];
                local parameter = parameters[p];
                if not vm.type.isAssignableFromTypes(arg, parameter.types) then
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
        for i = 1, #constructors do
            if consDef then break end
            consDef = constructors[i];
            local parameters = consDef.parameters or {};
            local paramLen = #parameters;
            if paramLen ~= 0 then
                local lastParameter = parameters[paramLen];
                if not consDef.vararg then
                    consDef = nil;
                    -- If the varArg range doesn't match.
                elseif paramLen > argsLen then
                    consDef = nil;
                else
                    local varArgTypes = lastParameter.types;
                    -- Check normal parameters.
                    for p = 1, paramLen - 1 do
                        local arg = args[p];
                        local parameter = parameters[p];
                        if not vm.type.isAssignableFromTypes(arg, parameter.types) then
                            consDef = nil;
                            break;
                        end
                    end
                    -- Check vararg parameters.
                    for p = paramLen, argsLen do
                        local arg = args[p];
                        if not vm.type.isAssignableFromTypes(arg, varArgTypes) then
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
        if o.__type__ == 'SuperTable' then
            error('ClassInstance was not passed and instead the SuperTable.', 2);
        end

        local args = { ... } or {};

        local cons = classDef:getDeclaredConstructor(args);

        if not cons then
            local errMsg = string.format('%s No constructor signature exists: %s',
                classDef.printHeader, vm.print.argsToString(args)
            );
            print(errMsg);
            error(errMsg, 2);
            return;
        end

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            struct = classDef,
            element = cons,
            context = 'constructor',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if vm.flags.ENABLE_SCOPE then
            -- Ensure that the class is accessible from the scope.
            local classScopeAllowed = vm.scope.getScopeForCall(classDef, callInfo);
            if not vm.scope.canAccessScope(classDef.scope, classScopeAllowed) then
                local sClass = classDef.path;
                local errMsg = string.format(
                    'IllegalAccessException: The class "%s" is "%s".' ..
                    ' (Access Level from call: "%s")\n%s',
                    sClass,
                    classDef.scope, classScopeAllowed,
                    vm.stack.printStackTrace()
                );
                print(errMsg);
                error(errMsg, 2);
                return;
            end

            local scopeAllowed = vm.scope.getScopeForCall(cons.struct, callInfo);
            if vm.isOutside() and not vm.scope.canAccessScope(cons.scope, scopeAllowed) then
                local errMsg = string.format(
                    'IllegalAccessException: The constructor %s.new(%s) is set as "%s" access level.' ..
                    ' (Access Level from call: "%s")\n%s',
                    cons.struct.name, dump(cons.parameters),
                    cons.scope, scopeAllowed,
                    vm.stack.printStackTrace()
                );
                vm.stack.popContext();
                print(errMsg);
                error(errMsg, 2);
                return;
            end
        end

        --- Apply super.
        vm.stepIn();
        local lastSuper = o.super;
        o.super = classDef.__supertable__;
        vm.stepOut();

        local result, errMsg;

        -- This will always fail if ran. (No super context at root)
        --
        -- DEV NOTE: I explicitly check the path instead of `if not cd.super then .. end` to prevent deep errors
        --           where the possibility of a nil-super class is not pointing to lua.lang.Object in which they
        --           SHOULD. - Jab
        --
        if classDef.path ~= 'lua.lang.Object' then
            result, errMsg = xpcall(function()
                local retValue;

                vm.stepIn();
                local currentSuperCount = o.super.__call_count__;
                local lastWho = o.super.__who__;
                o.super.__who__ = cons;
                vm.stepOut();

                retValue = cons.super(o, unpack(args));

                -- Make sure that super was invoked once.
                if o.super.__call_count__ == currentSuperCount + 1 then
                    o.super.__call_count__ = currentSuperCount;
                elseif o.super.__call_count__ > currentSuperCount + 1 then
                    o.super.__call_count__ = currentSuperCount;
                    vm.stack.popContext();
                    errorf(2, '%s The super-block of the constructor called self:super() more than once.',
                        classDef.printHeader
                    );
                else
                    o.super.__call_count__ = currentSuperCount;
                    vm.stack.popContext();
                    errorf(2, '%s The super-block of the constructor did not call self:super().',
                        classDef.printHeader
                    );
                end

                -- Reset super-invoke flags.
                vm.stepIn();
                cons.__super_flag__ = false;
                o.super.__who__ = lastWho;
                vm.stepOut();

                -- Make sure that constructors don't return anything.
                if retValue ~= nil then
                    vm.stack.popContext();
                    errorf(2, '%s Constructor super function returned non-nil value: {type = %s, value = %s}',
                        classDef.printHeader,
                        vm.type.getType(retValue), tostring(retValue)
                    );
                    return;
                end
            end, debug.traceback);

            -- If the constructor super function fails.
            if not result then
                vm.stack.popContext();
                error(errMsg, 2);
            end
        end

        result, errMsg = xpcall(function()
            local retValue = cons.body(o, unpack(args));

            -- Make sure that constructors don't return anything.
            if retValue ~= nil then
                local errMsg = string.format('%s Constructor returned non-nil value: {type = %s, value = %s}',
                    classDef.printHeader,
                    vm.type.getType(retValue), tostring(retValue)
                );
                vm.stack.popContext();
                error(errMsg, 2);
                return;
            end

            -- Make sure that final fields are initialized post-constructor.
            vm.audit.auditFinalFields(classDef, o);
        end, debug.traceback);

        --- Revert super.
        vm.stepIn();
        o.super = lastSuper;
        vm.stepOut();

        vm.stack.popContext();
        if not result then error(errMsg) end
    end
end

--- @param self Constructable
--- @param path string
--- @param line integer
---
--- @return ConstructorStruct|nil method
function API.getConstructorFromLine(self, path, line)
    for _, consDef in pairs(self.declaredConstructors) do
        if path == consDef.bodyInfo.path and
            (line >= consDef.bodyInfo.start and line <= consDef.bodyInfo.stop) or
            (line >= consDef.superInfo.start and line <= consDef.superInfo.stop) then
            return consDef;
        end
    end
    return nil;
end

-- MARK: - <signature>

function API.createCallSignature(name, args)
    local tArgs = API.argsToTypes(args);
    local s = '';
    for i = 1, #args do
        if s == '' then
            s = tArgs[i];
        else
            s = string.format('%s, %s', s, tArgs[i]);
        end
    end
    return string.format('%s(%s)', name, s);
end

function API.createSignature(definition)
    -- Process name.
    local name;
    if definition.__type__ == 'ConstructorStruct' then
        name = 'new';
    else
        name = definition.name;
    end

    -- Process parameter(s).
    local parameters = definition.parameters;
    local parameterLen = #parameters;

    if parameterLen == 0 then
        return string.format('%s()', name);
    end

    local s = '';
    for i = 1, parameterLen do
        local sParameter = API.combineParameterTypes(parameters[i]);
        if s == '' then
            s = sParameter;
        else
            s = string.format('%s, %s', s, sParameter);
        end
    end
    return string.format('%s(%s)', name, s);
end

function API.combineParameterTypes(parameter)
    local s = '';
    local types = parameter.types;
    for i = 1, #types do
        local type = types[i];
        local sType = vm.type.getType(type);
        if sType == 'string' then
            --- @cast type string
            sType = type;
        end
        if s == '' then
            s = sType;
        else
            s = string.format('%s|%s', s, sType);
        end
    end
    return s;
end

-- MARK: <parameter>

--- @param paramsA ParameterStruct[]
--- @param paramsB ParameterStruct[]
---
--- @return boolean
function API.areCompatible(paramsA, paramsB)
    if #paramsA ~= #paramsB then
        print(string.format('Params length mismatch: #a = %i, #b = %i', #paramsA, #paramsB));
        return false;
    end

    for i = 1, #paramsA do
        local a = paramsA[i];
        local b = paramsB[i];
        if not vm.type.anyCanCastToTypes(a.types, b.types) then
            return false;
        end
    end

    return true;
end

function API.compile(def)
    local defParams = def.parameters;
    if not defParams then return {} end

    -- Convert any simplified type declarations.
    local paramLen = #defParams;
    if paramLen then
        for i = 1, paramLen do
            local param = defParams[i];

            -- Validate parameter type(s).
            if not param.type and not param.types then
                errorf(2, 'Parameter #%i doesn\'t have a defined type string or types string[]. (name = %s)',
                    i, param.name
                );
            else
                if param.type and not param.types then
                    param.types = { param.type };
                    --- @diagnostic disable-next-line
                    param.type = nil;
                end
            end

            -- Validate parameter name.
            if param.name == '' then
                errorf(2, 'Parameter #%i has an empty name string.', i);
            elseif not param.name then
                param.name = 'arg_' .. tostring(i);
            end
        end
    end

    return defParams;
end

return API;
