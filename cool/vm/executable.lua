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

    --- @param vm VM
    setVM = function(vm)
        vm = vm;
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

--- @param name string The name of the method called.
--- @param args any[] The arguments passed to the middle-function.
---
--- @return string callSignature The simulated method signature.
function API.createCallSignature(name, args)
    local tArgs = API.argsToTypes(args);
    local s = '';
    for i = 1, #args do
        if s == '' then
            s = tArgs[i];
        else
            s = s .. ', ' .. tArgs[i];
        end
    end
    return string.format('%s(%s)', name, s);
end

function API.argsToTypes(args)
    local tArgs = {};
    for i = 1, #args do
        table.insert(tArgs, vm.type.getType(args[i]));
    end
    return tArgs;
end

function API.resolveMethod(struct, name, methods, args)
    local callSignature = vm.executable.createCallSignature(name, args);

    --- @type MethodDefinition|nil
    local md;

    -- Check the cache.
    -- md = struct.methodCache[callSignature];
    -- if md then return md end

    debugf(vm.debug.methodCache, '[METHOD_CACHE] :: %s No cache found for method %s call signature: %s',
        struct.printHeader,
        name,
        callSignature
    );

    -- Attempt to resolve the method using exact method signature checks.
    --- @type MethodDefinition?
    local md = methods[callSignature];
    if md then
        debugf(vm.debug.methodCache, '[METHOD_CACHE] :: %s Caching exact method %s call signature: %s',
            struct.printHeader,
            vm.print.printMethod(md),
            callSignature
        );

        -- Cache the result.
        struct.methodCache[callSignature] = md;

        return md;
    end

    -- If the method still isn't identified, look into each argument and match.
    if not md then
        md = API.resolveMethodDeep(methods, args);
    end

    if md then
        debugf(vm.debug.methodCache, '[METHOD_CACHE] :: %s Caching method %s call signature: %s',
            struct.printHeader,
            vm.print.printMethod(md),
            callSignature
        );

        -- Cache the result.
        struct.methodCache[callSignature] = md;
    end

    return md;
end

--- @param methods table<string, MethodDefinition>
--- @param args any[]
---
--- @return MethodDefinition|nil
function API.resolveMethodDeep(methods, args)
    local argsLen = #args;

    --- @type MethodDefinition?
    local md = nil;

    -- Try to find the method without varargs first.
    for _, method in pairs(methods) do
        if md then break end
        md = method;
        local parameters = md.parameters or {};
        local paramLen = #parameters;
        if argsLen == paramLen then
            for p = 1, paramLen do
                local arg = args[p];
                local parameter = parameters[p];
                if not vm.type.isAssignableFromType(arg, parameter.types) then
                    md = nil;
                    break;
                end
            end
        else
            md = nil;
        end
    end

    -- Check and see if a vararg method exists.
    if not md then
        for _, method in pairs(methods) do
            if md then break end
            md = method;
            local parameters = md.parameters or {};
            local paramLen = #parameters;
            if paramLen ~= 0 then
                local lastParameter = parameters[paramLen];
                local lastType = lastParameter.types[i];
                if not vm.executable.isVararg(lastType) then
                    md = nil;
                    -- If the varArg range doesn't match.
                elseif paramLen > argsLen then
                    md = nil;
                else
                    local varArgTypes = vm.executable.getVarargTypes(lastType);
                    -- Check normal parameters.
                    for p = 1, paramLen - 1 do
                        local arg = args[p];
                        local parameter = parameters[p];
                        if not vm.type.isAssignableFromType(arg, parameter.types) then
                            md = nil;
                            break;
                        end
                    end
                    -- Check vararg parameters.
                    for p = paramLen, argsLen do
                        local arg = args[p];
                        if not vm.type.isAssignableFromType(arg, varArgTypes) then
                            md = nil;
                            break;
                        end
                    end
                end
            end
        end
    end
    return md;
end

--- @param struct StructDefinition
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
                        md.super.class.name,
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

        local errHeader = string.format('Class(%s):%s():', cd.name, name);

        if not md then
            errorf(2, '%s No method signature exists: %s', errHeader, vm.print.argsToString(args));
            return;
        end

        vm.stack.pushContext({
            class = cd,
            element = md,
            context = 'method',
            line = DebugUtils.getCurrentLine(3),
            path = DebugUtils.getPath(3)
        });

        local level, relPath = vm.scope.getRelativePath();

        local callInfo = DebugUtils.getCallInfo(level, vm.ROOT_PATH, true);
        callInfo.path = relPath;
        local scopeAllowed = vm.scope.getScopeForCall(md.class, callInfo);

        if not vm.scope.canAccessScope(md.scope, scopeAllowed) then
            local sMethod = vm.print.printMethod(md);
            local errMsg = string.format(
                'IllegalAccessException: The method %s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                sMethod,
                md.scope, scopeAllowed,
                vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            print(errMsg);
            error(errMsg, 2);
            return;
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

        -- Audit void type methods.
        if retVal ~= nil and md.returnTypes == 'void' then
            local errMsg = string.format('Invoked Method is void and returned value: {type = %s, value = %s}',
                type(retVal),
                tostring(retVal)
            );
            print(errMsg);
            vm.stack.popContext();
            error('', 2);
            return;
        end

        vm.stack.popContext();

        -- Throw the error after applying context.
        if not result then error(tostring(errMsg) or '') end

        return retVal;
    end;
end

function API.createSignature(definition)
    local name;

    if definition.__type__ == 'ConstructorDefinition' then
        name = 'new';
    else
        name = definition.name;
    end

    local parameterLen = #definition.parameters;
    if parameterLen ~= 0 then
        local s = '';
        for i = 1, parameterLen do
            local parameter = definition.parameters[i];

            local sParameter = '';
            for i = 1, #parameter.types do
                local next = parameter.types[i];
                local sNext;
                if type(next) == 'table' then
                    --- @cast next StructDefinition
                    sNext = next.path;
                elseif type(next) == 'string' then
                    sNext = next;
                end

                if sParameter == '' then
                    sParameter = sNext;
                else
                    sParameter = sParameter .. '|' .. sNext;
                end
            end

            -- local sParameter = table.concat(parameter.types, '|');
            if s == '' then
                s = sParameter;
            else
                s = s .. ', ' .. sParameter;
            end
        end
        print(string.format('%s(%s)', name, s));
        return string.format('%s(%s)', name, s);
    end

    return name .. '()';
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

    -- Grab any super-struct declarations.
    if classDef['super'] then
        --- @cast classDef ClassStructDefinition|InterfaceStructDefinition
        API.getMethodNames(classDef.super, methodNames);
    end

    -- Grab any interface declarations.
    if classDef['interfaces'] then
        --- @cast classDef ClassStructDefinition|EnumStructDefinition
        local interfaceLen = #classDef.interfaces;
        if interfaceLen ~= 0 then
            for i = 1, interfaceLen do
                API.getMethodNames(classDef.interfaces[i], methodNames);
            end
        end
    end

    -- Get struct-specific declarations.
    API.getDeclaredMethodNames(classDef, methodNames);

    return methodNames;
end

--- @param def StructDefinition
--- @param name string
--- @param comb table<string, table<MethodDefinition>>
function API.combineAllMethods(def, name, comb)
    comb = comb or {};

    local combCluster = comb[name];
    if not combCluster then
        combCluster = {};
        comb[name] = combCluster;
    end

    -- Grab all the super-context methods first.
    if def['super'] then
        --- @cast def ClassStructDefinition|InterfaceStructDefinition
        API.combineAllMethods(def.super, name, comb);
    end

    if def['interfaces'] then
        --- @cast def ClassStructDefinition|EnumStructDefinition
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

--- @param self StructDefinition
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
    if self.__type__ ~= 'InterfaceStructDefinition' and not self['abstract'] then
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

--- @param self StructDefinition
--- @param path string
--- @param line integer
---
--- @return MethodDefinition|nil method
function API.getDeclaredMethodFromLine(self, path, line)
    for _, mCluster in pairs(self.declaredMethods) do
        for _, md in pairs(mCluster) do
            if path == md.bodyInfo.path and line >= md.bodyInfo.start and line <= md.bodyInfo.stop then
                return md;
            end
        end
    end
    return nil;
end

--- @param self ClassStructDefinition|InterfaceStructDefinition
--- @param path string
--- @param line number
---
--- @return ExecutableDefinition|nil
function API.getExecutableFromLine(self, path, line)
    --- @type ExecutableDefinition|nil
    local ed = API.getDeclaredMethodFromLine(self, path, line);
    if not ed and self.__type__ == 'ClassStructDefinition' then
        ed = vm.executable.getConstructorFromLine(self, path, line);
    end
    return ed;
end

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
                if not vm.type.isAssignableFromType(arg, parameter.types) then
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
                if not vm.executable.isVararg(lastType) then
                    consDef = nil;
                    -- If the varArg range doesn't match.
                elseif paramLen > argsLen then
                    consDef = nil;
                else
                    local varArgTypes = vm.executable.getVarargTypes(lastType);
                    -- Check normal parameters.
                    for p = 1, paramLen - 1 do
                        local arg = args[p];
                        local parameter = parameters[p];
                        if not vm.type.isAssignableFromType(arg, parameter.types) then
                            consDef = nil;
                            break;
                        end
                    end
                    -- Check vararg parameters.
                    for p = paramLen, argsLen do
                        local arg = args[p];
                        if not vm.type.isAssignableFromType(arg, varArgTypes) then
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

        local level, relPath = vm.scope.getRelativePath();

        vm.stack.pushContext({
            class = classDef,
            element = cons,
            context = 'constructor',
            line = DebugUtils.getCurrentLine(level),
            path = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(3, vm.ROOT_PATH, true);
        callInfo.path = relPath;
        local scopeAllowed = vm.scope.getScopeForCall(cons.class, callInfo);

        if vm.isOutside() and not vm.scope.canAccessScope(cons.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The constructor %s.new(%s) is set as "%s" access level.' ..
                ' (Access Level from call: "%s")\n%s',
                cons.class.name, dump(cons.parameters),
                cons.scope, scopeAllowed,
                vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            print(errMsg);
            error(errMsg, 2);
            return;
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
--- @return ConstructorDefinition|nil method
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

--- @param paramsA ParameterDefinition[]
--- @param paramsB ParameterDefinition[]
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

function API.getVarargTypes(arg)
    if not API.isVararg(arg) then
        errorf(2, 'Type is not vararg: %s', arg);
    end
    return arg:sub(1, #arg - 3):split('|');
end

function API.isVararg(arg)
    local len = #arg;
    if len < 3 then return false end
    return string.sub(arg, len - 2, len) == '...';
end

function API.compile(defParams)
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
            if not param.name and not vm.executable.isVararg(param.types[1]) then
                errorf(2, 'Parameter #%i doesn\'t have a defined name string.', i);
            elseif param.name == '' then
                errorf(2, 'Parameter #%i has an empty name string.', i);
            end
        end
    end

    return defParams;
end

--- @param self Object
function API.defaultSuperFunc(self)
    self:super();
end

return API;
