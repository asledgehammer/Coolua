---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local DebugUtils = require 'DebugUtils';
local LVMUtils = require 'LVMUtils';
local debugf = LVMUtils.debugf;
local printf = LVMUtils.printf;
local errorf = LVMUtils.errorf;
local isValidName = LVMUtils.isValidName;
local isArray = LVMUtils.isArray;
local readonly = LVMUtils.readonly;

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    -- Method(s)
    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

function API.newInterface(definition, enclosingStruct)

    local locInfo = LVM.struct.calcPathNamePackage(definition, enclosingStruct);
    local path = locInfo.path;
    local name = locInfo.name;
    local pkg = locInfo.pkg;

    local id = {
        -- Internal Type --
        __type__ = 'InterfaceStructDefinition',

        path = path,
        name = name,
        pkg = pkg
    };

    --- @param methodDefinition MethodDefinitionParameter
    --- @param func function
    function id:addMethod(methodDefinition, func)
        -- Friendly check for implementation.
        if not self or type(methodDefinition) == 'function' then
            error(
                'Improper method call. (Not instanced) Use MyClass:addMethod() instead of MyClass.addMethod()',
                2
            );
        end

        local errHeader = string.format('InterfaceStructDefinition(%s):addMethod():', id.name);

        local types = {};
        local returns = methodDefinition.returns;

        -- Validate name.
        if not methodDefinition.name then
            errorf(2, '%s string property "name" is not provided.', errHeader);
        elseif type(methodDefinition.name) ~= 'string' then
            errorf(2, '%s property "name" is not a valid string. {type=%s, value=%s}',
                errHeader, type(methodDefinition.name), tostring(methodDefinition.name)
            );
        elseif methodDefinition.name == '' then
            errorf(2, '%s property "name" is an empty string.', errHeader);
        elseif not isValidName(methodDefinition.name) then
            errorf(2,
                '%s property "name" is invalid. (value = %s) (Should only contain A-Z, a-z, 0-9, _, or $ characters)',
                errHeader, methodDefinition.name
            );
        elseif methodDefinition.name == 'super' then
            errorf(2, '%s cannot name method "super".', errHeader);
        end

        -- Validate parameter type(s).
        if not returns then
            types = { 'void' };
        elseif type(returns) == 'table' then
            --- @cast returns table
            if not isArray(returns) then
                errorf(2, '%s The property "returns" is not a string[] or string[]. {type = %s, value = %s}',
                    errHeader, LVM.type.getType(returns), tostring(returns)
                );
            end
            --- @cast returns string[]
            types = returns;
        elseif type(methodDefinition.returns) == 'string' then
            --- @cast returns string
            types = { returns };
        end

        -- Validate abstract flag.
        if methodDefinition.abstract then
            if not id.abstract then
                errorf(2, '%s The method cannot be abstract when the class is not: %s.%s',
                    errHeader, id.name, methodDefinition.name
                );
                return;
            elseif func then
                errorf(2, '%s The method cannot be abstract and have a defined function block: %s.%s',
                    errHeader, id.name, methodDefinition.name
                );
                return;
            end
        end

        -- TODO: Implement all definition property checks.
        local lineStart, lineStop = -1, -1;
        if func then
            lineStart, lineStop = DebugUtils.getFuncRange(func);
        end

        --- @type MethodDefinition
        local args = {
            __type__ = 'MethodDefinition',
            audited = false,
            class = id,
            scope = methodDefinition.scope or 'package',
            static = methodDefinition.static or false,
            final = methodDefinition.final or false,
            parameters = methodDefinition.parameters or {},
            name = methodDefinition.name,
            returns = types,
            override = false,
            super = nil,
            func = func,
            abstract = methodDefinition.abstract or false,
            lineRange = { start = lineStart, stop = lineStop },
        };

        if args.parameters then
            if type(args.parameters) ~= 'table' or not isArray(args.parameters) then
                errorf(2, '%s property "parameters" is not a ParameterDefinition[]. {type=%s, value=%s}',
                    errHeader, LVM.type.getType(args.parameters), tostring(args.parameters)
                );
            end

            -- Convert any simplified type declarations.
            local paramLen = #args.parameters;
            if paramLen then
                for i = 1, paramLen do
                    local param = args.parameters[i];

                    -- Validate parameter type(s).
                    if not param.type and not param.types then
                        errorf(2, '%s Parameter #%i doesn\'t have a defined type string or types string[]. (name = %s)',
                            errHeader, i, param.name
                        );
                    else
                        if param.type and not param.types then
                            param.types = { param.type };
                            --- @diagnostic disable-next-line
                            param.type = nil;
                        end
                    end

                    -- Validate parameter name.
                    if not param.name and not LVM.parameter.isVararg(param.types[1]) then
                        errorf(2, '%s Parameter #%i doesn\'t have a defined name string.', errHeader, i);
                    elseif param.name == '' then
                        errorf(2, '%s Parameter #%i has an empty name string.', errHeader, i);
                    end
                end
            end
        else
            args.parameters = {};
        end

        local name = args.name;
        local methodCluster = self.declaredMethods[name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[name] = methodCluster;
        end
        table.insert(methodCluster, args);

        return args;
    end

    function id:compileMethods()
        debugf(LVM.debug.method, '%s Compiling method(s)..', self.printHeader);

        --- @type table<string, MethodDefinition[]>
        self.methods = {};

        local methodNames = LVM.method.getMethodNames(id);
        for i = 1, #methodNames do
            self:compileMethod(methodNames[i]);
        end

        local keysCount = 0;
        for _, _ in pairs(self.methods) do
            keysCount = keysCount + 1;
        end

        debugf(LVM.debug.method, '%s Compiled %i method(s).', self.printHeader, keysCount);
    end

    function id:compileMethod(name)
        local debugName = self.name .. '.' .. name .. '(...)';

        if not self.superClass then
            debugf(LVM.debug.method, '%s Compiling original method(s): %s', self.printHeader, debugName);
            self.methods[name] = LVMUtils.copyArray(self.declaredMethods[name]);
            return;
        end

        debugf(LVM.debug.method, '%s Compiling compound method(s): %s', self.printHeader, debugName);

        local decMethods = self.declaredMethods[name];

        -- The current class doesn't have any definitions at all.
        if not decMethods then
            debugf(LVM.debug.method, '%s \tUsing super-class array: %s', self.printHeader, debugName);

            -- Copy the super-class array.
            self.methods[name] = LVMUtils.copyArray(self.superClass.methods[name]);
            return;
        end

        -- In this case, all methods with this name are original.
        if not id.superClass.methods[name] then
            debugf(LVM.debug.method, '%s \tUsing class declaration array: %s', self.printHeader, debugName);
            self.methods[name] = LVMUtils.copyArray(decMethods);
            return;
        end

        --- @type table<string, MethodDefinition[]>
        local methods = LVMUtils.copyArray(id.superClass.methods[name]);

        if decMethods then
            for i = 1, #decMethods do
                local decMethod = decMethods[i];

                local isOverride = false;

                -- Go through each super-class method.
                for j = 1, #methods do
                    local method = methods[j];

                    if LVM.parameter.areCompatible(decMethod.parameters, method.parameters) then
                        debugf(LVM.debug.method, '%s \t\t@override detected: %s', self.printHeader, debugName);

                        -- Cannot override final methods.
                        if method.final then
                            errorf(2, '%s Class method cannot override super-method because it is final: %s',
                                id.printHeader, LVM.print.printMethod(method)
                            );
                        end

                        -- Overrided methods must maintain static / non-static with exact signatures.
                        -- if method.static ~= decMethod.static then
                        -- TODO: Implement.
                        -- end

                        isOverride = true;
                        decMethod.super = method;
                        decMethod.override = true;
                        methods[j] = decMethod;
                        break;
                    end
                end

                --- No overrided method. Add it instead.
                if not isOverride then
                    debugf(LVM.debug.method, '%s \t\tAdding class method: %s', self.printHeader, debugName);
                    table.insert(methods, decMethod);
                end
            end
        end
        self.methods[name] = methods;
    end

    --- Attempts to resolve a MethodDefinition in the ClassStructDefinition. If the method isn't defined in the class,
    --- `nil` is returned.
    ---
    --- @param name string
    ---
    --- @return MethodDefinition[]? methods
    function id:getDeclaredMethods(name)
        return id.declaredMethods[name];
    end

    --- @param name string
    --- @param args any[]
    ---
    --- @return MethodDefinition|nil methodDefinition
    function id:getMethod(name, args)
        local method = self:getDeclaredMethod(name, args);
        if not method and self.superClass then
            method = self.superClass:getMethod(name, args);
        end
        return method;
    end

    --- @param name string
    --- @param args any[]
    ---
    --- @return MethodDefinition|nil methodDefinition
    function id:getDeclaredMethod(name, args)
        local argsLen = #args;
        local methods = id.declaredMethods[name];

        -- No declared methods with name.
        if not methods then
            return nil;
        end

        for i = 1, #methods do
            local method = methods[i];
            local methodParams = method.parameters;
            local paramsLen = #methodParams;
            if argsLen == paramsLen then
                --- Empty args methods.
                if argsLen == 0 then
                    return method;
                else
                    for j = 1, #methodParams do
                        local arg = args[j];
                        local parameter = methodParams[j];
                        if not LVM.type.isAssignableFromType(arg, parameter.types) then
                            method = nil;
                            break;
                        end
                    end
                    if method then return method end
                end
            end
        end
        return nil;
    end

    --- @param line integer
    ---
    --- @return MethodDefinition|nil method
    function id:getMethodFromLine(line)
        --- @type MethodDefinition
        local md;
        for _, mdc in pairs(self.declaredMethods) do
            for i = 1, #mdc do
                md = mdc[i];
                if line >= md.lineRange.start and line <= md.lineRange.stop then
                    return md;
                end
            end
        end
        return nil;
    end

    -- MARK: - finalize()

    --- @return ClassStructDefinition class
    function id:finalize()
        local errHeader = string.format('Class(%s):finalize():', id.path);

        if self.lock then
            errorf(2, '%s Cannot finalize. (Class is already finalized!)', errHeader);
        elseif id.superClass and (id.superClass.__type__ == 'ClassStructDefinition' and not id.superClass.lock) then
            errorf(2, '%s Cannot finalize. (SuperClass %s is not finalized!)', errHeader, path);
        end

        -- If any auto-methods are defined for fields (get, set), create them before compiling class methods.
        self:compileFieldAutoMethods();

        -- TODO: Audit everything.

        --- @type table<string, MethodDefinition[]>
        self:compileMethods();

        -- Change add methods.
        self.addMethod = function() errorf(2, '%s Cannot add methods. (Class is final!)', errHeader) end
        self.addField = function() errorf(2, '%s Cannot add fields. (Class is final!)', errHeader) end
        self.addConstructor = function() errorf(2, '%s Cannot add constructors. (Class is final!)', errHeader) end

        -- Set default value(s) for static fields.
        for name, fd in pairs(id.declaredFields) do
            if fd.static then
                id[name] = fd.value;
            end
        end

        --- @type table<ParameterDefinition[], function>
        self.__constructors = {};

        -- Set all definitions as read-only.
        local constructorsLen = #self.declaredConstructors;
        if constructorsLen ~= 0 then
            for i = 1, constructorsLen do
                --- @type ConstructorDefinition
                local constructor = self.declaredConstructors[i];
                self.__constructors[constructor.parameters] = constructor.func;

                -- Set read-only.
                self.declaredConstructors[i] = readonly(constructor);
            end
        end

        self.__middleMethods = {};

        -- Insert boilerplate method invoker function.
        for name, methods in pairs(self.methods) do
            for i, md in pairs(methods) do
                if md.override then
                    -- RULE: Cannot override method if super-method is final.
                    if md.super.final then
                        local sMethod = LVM.print.printMethod(md);
                        errorf(2, '%s Method cannot override final method in super-class: %s',
                            errHeader,
                            md.super.class.name,
                            sMethod
                        );
                        return id;
                        -- RULE: Cannot reduce scope of overrided super-method.
                    elseif not LVM.scope.canAccessScope(md.scope, md.super.scope) then
                        local sMethod = LVM.print.printMethod(md);
                        errorf(2, '%s Method cannot reduce scope of super-class: %s (super-scope = %s, class-scope = %s)',
                            errHeader,
                            sMethod, md.super.scope, md.scope
                        );
                        return id;
                        -- RULE: override Methods must either be consistently static (or not) with their super-method(s).
                    elseif md.static ~= md.super.static then
                        local sMethod = LVM.print.printMethod(md);
                        errorf(2,
                            '%s All method(s) with identical signatures must either be static or not: %s (super.static = %s, class.static = %s)',
                            errHeader,
                            sMethod, tostring(md.super.static), tostring(md.static)
                        );
                        return id;
                    end
                end
            end
            self.__middleMethods[name] = LVM.method.createMiddleMethod(id, name, methods);
        end

        local mt = getmetatable(id) or {};
        local __properties = {};
        for k, v in pairs(id) do __properties[k] = v end
        mt.__metatable = false;
        mt.__index = __properties;
        mt.__tostring = function() return 'Class ' .. id.path end

        mt.__index = __properties;

        mt.__newindex = function(tbl, field, value)
            -- TODO: Visibility scope analysis.
            -- TODO: Type-checking.

            if field == 'super' or field == '__super__' then
                errorf(2, '%s Cannot set super. (Static context)', id.printHeader);
                return;
            end

            -- Post-finalize assignment.
            if field == 'classObj' and not __properties['classObj'] then
                __properties['classObj'] = value;
                return;
            end

            local fd = id:getField(field);

            -- Inner class invocation.
            if id.children[field] then
                if LVM.isOutside() then
                    errorf(2, 'Cannot set inner class explicitly. Use the API.');
                end

                print('setting inner-class: ', field, tostring(value));
                __properties[field] = value;

                return;
            end

            if not fd then
                errorf(2, 'FieldNotFoundException: Cannot set new field or method: %s.%s',
                    id.path, field
                );
                return;
            elseif not fd.static then
                errorf(2, 'StaticFieldException: Assigning non-static field in static context: %s.%s',
                    id.path, field
                );
                return;
            end

            local level, relPath = LVM.scope.getRelativePath();

            LVM.stack.pushContext({
                class = id,
                element = fd,
                context = 'field-set',
                line = DebugUtils.getCurrentLine(level),
                path = DebugUtils.getPath(level)
            });

            local callInfo = DebugUtils.getCallInfo(level, nil, true);
            callInfo.path = relPath;
            local scopeAllowed = LVM.scope.getScopeForCall(fd.class, callInfo);

            if not LVM.scope.canAccessScope(fd.scope, scopeAllowed) then
                local errMsg = string.format(
                    'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                    id.name, fd.name,
                    fd.scope, scopeAllowed,
                    LVM.stack.printStackTrace()
                );
                LVM.stack.popContext();
                print(errMsg);
                error('', 2);
                return;
            end

            -- (Just in-case)
            if value == LVM.constants.UNINITIALIZED_VALUE then
                local errMsg = string.format('%s Cannot set %s as UNINITIALIZED_VALUE. (Internal Error)\n%s',
                    id.printHeader, field, LVM.stack.printStackTrace()
                );
                LVM.stack.popContext();
                error(errMsg, 2);
                return;
            end

            if fd.final then
                local ste = LVM.stack.getContext();
                if not ste then
                    errorf(2, '%s Attempt to assign final field %s outside of Class scope.', id.printHeader, field);
                    return;
                end

                local context = ste:getContext();
                local class = ste:getCallingClass();
                if class ~= id then
                    errorf(2, '%s Attempt to assign final field %s outside of Class scope.', id.printHeader, field);
                elseif context ~= 'constructor' then
                    errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', id.printHeader, field);
                elseif fd.assignedOnce then
                    errorf(2, '%s Attempt to assign final field %s. (Already defined)', id.printHeader, field);
                end
            end

            -- Set the value.
            __properties[field] = value;

            -- Apply forward the value metrics.
            fd.assignedOnce = true;
            fd.value = value;
        end

        setmetatable(id, mt);

        self.lock = true;
        CLASS_DEFS[id.path] = id;

        -- Set class as child.
        if id.superClass then
            table.insert(id.superClass.subClasses, id);
        end

        --- Set the class to be accessable from a global package reference.
        LVM.flags.allowPackageStructModifications = true;
        LVM.package.addToPackageStruct(id);
        LVM.flags.allowPackageStructModifications = false;

        -- Add a reference for global package and static code.
        if enclosingStruct then
            LVM.stepIn();
            enclosingStruct[id.name] = id;
            LVM.stepOut();
        end

        return id;
    end

    return id;
end

--- @cast API LVMInterfaceModule

return API;
