---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local DebugUtils = require 'DebugUtils';

local LVMUtils = require 'LVMUtils';
local arrayContains = LVMUtils.arrayContains;
local errorf = LVMUtils.errorf;
local debugf = LVMUtils.debugf;
local paramsToString = LVMUtils.paramsToString;

--- @type LVM
local LVM;

local API;
API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
        API.defaultSuperFuncInfo = API.getExecutableInfo(API.defaultSuperFunc);
    end
};

function API.getExecutableInfo(func)
    if not func then
        return { start = -1, stop = -1, path = '' };
    end
    local info = DebugUtils.getFuncInfo(func, LVM.ROOT_PATH, true);
    return { start = info.start, stop = info.stop, path = info.path };
end

--- @cast API LVMExecutableModule

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
        table.insert(tArgs, LVM.type.getType(args[i]));
    end
    return tArgs;
end

function API.resolveMethod(struct, name, methods, args)
    local callSignature = LVM.executable.createCallSignature(name, args);

    --- @type MethodDefinition|nil
    local md;

    -- Check the cache.
    -- md = struct.methodCache[callSignature];
    -- if md then return md end

    debugf(LVM.debug.methodCache, '%s No cache found for method %s call signature: %s',
        struct.printHeader,
        name,
        callSignature
    );

    -- Attempt to resolve the method using exact method signature checks.
    local md = methods[callSignature];
    if md then
        debugf(LVM.debug.methodCache, '%s Caching exact method %s call signature: %s',
            struct.printHeader,
            LVM.print.printMethod(md),
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
        debugf(LVM.debug.methodCache, '%s Caching method %s call signature: %s',
            struct.printHeader,
            LVM.print.printMethod(md),
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
                if not LVM.type.isAssignableFromType(arg, parameter.types) then
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
                if not LVM.executable.isVararg(lastType) then
                    md = nil;
                    -- If the varArg range doesn't match.
                elseif paramLen > argsLen then
                    md = nil;
                else
                    local varArgTypes = LVM.executable.getVarargTypes(lastType);
                    -- Check normal parameters.
                    for p = 1, paramLen - 1 do
                        local arg = args[p];
                        local parameter = parameters[p];
                        if not LVM.type.isAssignableFromType(arg, parameter.types) then
                            md = nil;
                            break;
                        end
                    end
                    -- Check vararg parameters.
                    for p = paramLen, argsLen do
                        local arg = args[p];
                        if not LVM.type.isAssignableFromType(arg, varArgTypes) then
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

function API.createMiddleMethod(cd, name, methods)
    --- @param o ClassInstance
    return function(o, ...)
        local args = { ... };
        local md = API.resolveMethod(cd, name, methods, args);

        local errHeader = string.format('Class(%s):%s():', cd.name, name);

        if not md then
            errorf(2, '%s No method signature exists: %s', errHeader, LVM.print.argsToString(args));
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

        local lastWho;
        local lastSuper;
        if o then
            --- Apply super.
            LVM.stepIn();
            lastSuper = o.super;
            o.super = cd.__supertable__;
            lastWho = o.super.__who__;
            o.super.__who__ = md;
            LVM.stepOut();
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
            LVM.stepIn();
            o.super.__who__ = lastWho;
            o.super = lastSuper;
            LVM.stepOut();
        end

        -- Audit void type methods.
        if retVal ~= nil and md.returns == 'void' then
            local errMsg = string.format('Invoked Method is void and returned value: {type = %s, value = %s}',
                type(retVal),
                tostring(retVal)
            );
            print(errMsg);
            LVM.stack.popContext();
            error('', 2);
            return;
        end

        LVM.stack.popContext();

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
            local sParameter = table.concat(parameter.types, '|');
            if s == '' then
                s = sParameter;
            else
                s = s .. ', ' .. sParameter;
            end
        end
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
                if interface.methods[name] then
                    local imCluster = interface.methods[name];

                    for imSignature, imd in pairs(imCluster) do
                        -- Here we ignore re-applied interface methods since they're already applied.
                        if not combCluster[name] and not imd.default then
                            debugf(LVM.debug.method, '%s IGNORING re-applied interface method in hierarchy: %s',
                                def.printHeader,
                                LVM.print.printMethod(imd)
                            );
                        else
                            debugf(LVM.debug.method, '%s Applying interface method in hierarchy: %s',
                                def.printHeader,
                                LVM.print.printMethod(imd)
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
                decMethod.override = true;
                decMethod.super = combCluster[decSig];

                debugf(LVM.debug.method, '%s OVERRIDING class method %s in hierarchy: %s',
                    def.printHeader,
                    LVM.print.printMethod(combCluster[decSig]),
                    LVM.print.printMethod(decMethod)
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
    debugf(LVM.debug.method, '%s Compiling method(s)..', self.printHeader);

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
                        self.printHeader, LVM.print.printMethod(method)
                    );
                    print(errMsg);
                    error(errMsg, 3);
                elseif method.interface and not method.default then
                    local errMsg = string.format('%s Interface method not implemented: %s',
                        self.printHeader, LVM.print.printMethod(method)
                    );
                    print(errMsg);
                    error(errMsg, 3);
                end
                count = count + 1;
            end
        end
    end

    debugf(LVM.debug.method, '%s Compiled %i method(s).', self.printHeader, count);
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
        ed = LVM.executable.getConstructorFromLine(self, path, line);
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
                if not LVM.executable.isVararg(lastType) then
                    consDef = nil;
                    -- If the varArg range doesn't match.
                elseif paramLen > argsLen then
                    consDef = nil;
                else
                    local varArgTypes = LVM.executable.getVarargTypes(lastType);
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
        if o.__type__ == 'SuperTable' then
            error('ClassInstance was not passed and instead the SuperTable.', 2);
        end

        local args = { ... } or {};
        local cons = classDef:getDeclaredConstructor(args);

        if not cons then
            local errMsg = string.format('%s No constructor signature exists: %s',
                classDef.printHeader, LVM.print.argsToString(args)
            );
            print(errMsg);
            error(errMsg, 2);
            return;
        end

        local level, relPath = LVM.scope.getRelativePath();

        LVM.stack.pushContext({
            class = classDef,
            element = cons,
            context = 'constructor',
            line = DebugUtils.getCurrentLine(level),
            path = DebugUtils.getPath(level)
        });

        local callInfo = DebugUtils.getCallInfo(3, LVM.ROOT_PATH, true);
        callInfo.path = relPath;
        local scopeAllowed = LVM.scope.getScopeForCall(cons.class, callInfo);

        if LVM.isOutside() and not LVM.scope.canAccessScope(cons.scope, scopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The constructor %s.new(%s) is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cons.class.name, paramsToString(cons.parameters),
                cons.scope, scopeAllowed,
                LVM.stack.printStackTrace()
            );
            LVM.stack.popContext();
            print(errMsg);
            error(errMsg, 2);
            return;
        end

        --- Apply super.
        LVM.stepIn();
        local lastSuper = o.super;
        o.super = classDef.__supertable__;
        LVM.stepOut();

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

                LVM.stepIn();
                cons.__super_flag__ = false;
                local lastWho = o.super.__who__;
                o.super.__who__ = cons;
                LVM.stepOut();

                retValue = cons.super(o, unpack(args));

                -- Reset super-invoke flags.
                LVM.stepIn();
                cons.__super_flag__ = false;
                o.super.__who__ = lastWho;
                LVM.stepOut();

                -- Make sure that constructors don't return anything.
                if retValue ~= nil then
                    errorf(2, '%s Constructor super function returned non-nil value: {type = %s, value = %s}',
                        classDef.printHeader,
                        LVM.type.getType(retValue), tostring(retValue)
                    );
                    return;
                end
            end, debug.traceback);

            -- If the constructor super function fails.
            if not result then
                LVM.stack.popContext();
                error(errMsg, 2);
            end
        end

        result, errMsg = xpcall(function()
            local retValue = cons.body(o, unpack(args));

            -- Make sure that constructors don't return anything.
            if retValue ~= nil then
                local errMsg = string.format('%s Constructor returned non-nil value: {type = %s, value = %s}',
                    classDef.printHeader,
                    LVM.type.getType(retValue), tostring(retValue)
                );
                LVM.stack.popContext();
                error(errMsg, 2);
                return;
            end

            -- Make sure that final fields are initialized post-constructor.
            LVM.audit.auditFinalFields(classDef, o);
        end, debug.traceback);

        --- Revert super.
        LVM.stepIn();
        o.super = lastSuper;
        LVM.stepOut();

        LVM.stack.popContext();
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
        if not LVM.type.anyCanCastToTypes(a.types, b.types) then
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
            if not param.name and not LVM.executable.isVararg(param.types[1]) then
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
