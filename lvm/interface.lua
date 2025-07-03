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

--- @param self InterfaceStructDefinition
--- @param methodDefinition InterfaceMethodDefinitionParameter
--- @param func function?
---
--- @return MethodDefinition
function API.addMethod(self, methodDefinition, func)
    local errHeader = string.format('InterfaceStructDefinition(%s):addMethod():', self.name);

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

    -- TODO: Implement all definition property checks.
    local lineStart, lineStop = -1, -1;
    if func then
        lineStart, lineStop = DebugUtils.getFuncRange(func);
    end

    --- @type MethodDefinition
    local md = {

        __type__ = 'MethodDefinition',

        -- Base properties. --
        class = self,
        name = methodDefinition.name,
        returns = types,
        parameters = methodDefinition.parameters or {},
        func = func,

        -- Used for scope-visibility analysis. --
        scope = methodDefinition.scope or 'package',
        lineRange = { start = lineStart, stop = lineStop },

        -- General method flags --
        static = methodDefinition.static or false,
        final = false, -- Cannot define finals in a interface context.

        -- Compiled method flags --
        audited = false,
        override = false,
        super = nil,

        -- Interface definition. --
        interface = true, -- Lets the LVM know this belongs to an interface.
        default = func ~= nil,

        -- Always falsify class flags in class method definitions. --
        abstract = false,
    };

    if md.parameters then
        if type(md.parameters) ~= 'table' or not isArray(md.parameters) then
            errorf(2, '%s property "parameters" is not a ParameterDefinition[]. {type=%s, value=%s}',
                errHeader, LVM.type.getType(md.parameters), tostring(md.parameters)
            );
        end

        -- Convert any simplified type declarations.
        local paramLen = #md.parameters;
        if paramLen then
            for i = 1, paramLen do
                local param = md.parameters[i];

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
        md.parameters = {};
    end

    local methodCluster = self.declaredMethods[md.name];
    if not methodCluster then
        methodCluster = {};
        self.declaredMethods[md.name] = methodCluster;
    end
    table.insert(methodCluster, md);

    return md;
end

--- @param self InterfaceStructDefinition
function API.compileMethods(self)
    debugf(LVM.debug.method, '%s Compiling method(s)..', self.printHeader);

    --- @type table<string, MethodDefinition[]>
    self.methods = {};

    local methodNames = LVM.method.getMethodNames(self);
    for i = 1, #methodNames do
        API.compileMethod(self, methodNames[i]);
    end

    local keysCount = 0;
    for _, _ in pairs(self.methods) do
        keysCount = keysCount + 1;
    end

    debugf(LVM.debug.method, '%s Compiled %i method(s).', self.printHeader, keysCount);
end

--- @param self InterfaceStructDefinition
--- @param name string
function API.compileMethod(self, name)
    local debugName = self.name .. '.' .. name .. '(...)';

    if not self.super then
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
        self.methods[name] = LVMUtils.copyArray(self.super.methods[name]);
        return;
    end

    -- In this case, all methods with this name are original.
    if not self.super.methods[name] then
        debugf(LVM.debug.method, '%s \tUsing class declaration array: %s', self.printHeader, debugName);
        self.methods[name] = LVMUtils.copyArray(decMethods);
        return;
    end

    --- @type table<string, MethodDefinition[]>
    local methods = LVMUtils.copyArray(self.super.methods[name]);

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
                            self.printHeader, LVM.print.printMethod(method)
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
--- @param self InterfaceStructDefinition
--- @param name string
---
--- @return MethodDefinition[]? methods
function API.getDeclaredMethods(self, name)
    return self.declaredMethods[name];
end

--- @param self InterfaceStructDefinition
--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function API.getMethod(self, name, args)
    local method = self:getDeclaredMethod(name, args);
    if not method and self.super then
        method = self.super:getMethod(name, args);
    end
    return method;
end

--- @param self InterfaceStructDefinition
--- @param name string
--- @param args any[]
---
--- @return MethodDefinition|nil methodDefinition
function API.getDeclaredMethod(self, name, args)
    local argsLen = #args;
    local methods = self.declaredMethods[name];

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

--- @param self InterfaceStructDefinition
--- @param line integer
---
--- @return MethodDefinition|nil method
function API.getMethodFromLine(self, line)
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

--- @param self InterfaceStructDefinition
---
--- @return InterfaceStructDefinition interfaceDef
function API.finalize(self)
    local errHeader = string.format('Class(%s):finalize():', self.path);

    if self.lock then
        errorf(2, '%s Cannot finalize. (Class is already finalized!)', errHeader);
    elseif self.super and (self.super.__type__ == 'ClassStructDefinition' and not self.super.lock) then
        errorf(2, '%s Cannot finalize. (Super-Class %s is not finalized!)', errHeader, self.path);
    end

    -- TODO: Audit everything.

    API.compileMethods(self);

    -- Change add methods.
    self.addMethod = function() errorf(2, '%s Cannot add methods. (Class is final!)', errHeader) end
    self.addField = function() errorf(2, '%s Cannot add fields. (Class is final!)', errHeader) end

    -- Set default value(s) for static fields.
    for name, fd in pairs(self.declaredFields) do
        if fd.static then
            self[name] = fd.value;
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
                    return self;
                    -- RULE: Cannot reduce scope of overrided super-method.
                elseif not LVM.scope.canAccessScope(md.scope, md.super.scope) then
                    local sMethod = LVM.print.printMethod(md);
                    errorf(2, '%s Method cannot reduce scope of super-class: %s (super-scope = %s, class-scope = %s)',
                        errHeader,
                        sMethod, md.super.scope, md.scope
                    );
                    return self;
                    -- RULE: override Methods must either be consistently static (or not) with their super-method(s).
                elseif md.static ~= md.super.static then
                    local sMethod = LVM.print.printMethod(md);
                    errorf(2,
                        '%s All method(s) with identical signatures must either be static or not: %s (super.static = %s, class.static = %s)',
                        errHeader,
                        sMethod, tostring(md.super.static), tostring(md.static)
                    );
                    return self;
                end
            end
        end
        self.__middleMethods[name] = LVM.method.createMiddleMethod(self, name, methods);
    end

    local mt = getmetatable(self) or {};
    local __properties = {};
    for k, v in pairs(self) do __properties[k] = v end
    mt.__metatable = false;
    mt.__index = __properties;
    mt.__tostring = function() return 'Class ' .. self.path end

    mt.__index = __properties;

    mt.__newindex = function(tbl, field, value)
        -- TODO: Visibility scope analysis.
        -- TODO: Type-checking.

        if field == 'super' or field == '__super__' then
            errorf(2, '%s Cannot set super. (Static context)', self.printHeader);
            return;
        end

        -- Post-finalize assignment.
        if field == 'classObj' and not __properties['classObj'] then
            __properties['classObj'] = value;
            return;
        end

        local fd = self:getField(field);

        -- Inner class invocation.
        if self.children[field] then
            if LVM.isOutside() then
                errorf(2, 'Cannot set inner class explicitly. Use the API.');
            end

            -- print('setting inner-class: ', field, tostring(value));
            __properties[field] = value;

            return;
        end

        if not fd then
            errorf(2, 'FieldNotFoundException: Cannot set new field or method: %s.%s',
                self.path, field
            );
            return;
        elseif not fd.static then
            errorf(2, 'StaticFieldException: Assigning non-static field in static context: %s.%s',
                self.path, field
            );
            return;
        end

        local level, relPath = LVM.scope.getRelativePath();

        LVM.stack.pushContext({
            class = self,
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
                self.name, fd.name,
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
                self.printHeader, field, LVM.stack.printStackTrace()
            );
            LVM.stack.popContext();
            error(errMsg, 2);
            return;
        end

        if fd.final then
            local ste = LVM.stack.getContext();
            if not ste then
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', self.printHeader, field);
                return;
            end

            local context = ste:getContext();
            local class = ste:getCallingClass();
            if class ~= self then
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', self.printHeader, field);
            elseif context ~= 'constructor' then
                errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', self.printHeader, field);
            elseif fd.assignedOnce then
                errorf(2, '%s Attempt to assign final field %s. (Already defined)', self.printHeader, field);
            end
        end

        -- Set the value.
        __properties[field] = value;

        -- Apply forward the value metrics.
        fd.assignedOnce = true;
        fd.value = value;
    end

    setmetatable(self, mt);

    self.lock = true;
    LVM.DEFINITIONS[self.path] = self;

    -- Set class as child.
    if self.super then
        table.insert(self.super.sub, self);
    end

    --- Set the class to be accessable from a global package reference.
    LVM.flags.allowPackageStructModifications = true;
    LVM.package.addToPackageStruct(self);
    LVM.flags.allowPackageStructModifications = false;

    -- Add a reference for global package and static code to enclosing struct.
    if self.outer then
        LVM.stepIn();
        self.outer[self.name] = self;
        LVM.stepOut();
    end

    return self;
end

--- (Handles recursively going through sub-interfaces to see if a class is a sub-class)
---
--- @param subClass InterfaceStructDefinition
--- @param classToEval InterfaceStructDefinition
---
--- @return boolean result True if the interface to evaluate is a super-class of the subClass.
function API.__recurseSubInterface(subClass, classToEval)
    local subLen = #subClass.sub;
    for i = 1, subLen do
        local next = subClass.sub[i];
        if API.isAssignableFromType(next, classToEval) or API.__recurseSubInterface(next, classToEval) then
            return true;
        end
    end
    return false;
end

--- @param interface InterfaceStructDefinition The interface to evaulate.
---
--- @return boolean result True if the interface to evaluate is a super-interface of the sub-interface.
function API:isSubInterface(self, interface)
    if API.__recurseSubClass(self, interface) then
        return true;
    end
    return false;
end

--- @param self InterfaceStructDefinition
--- @param struct StructDefinition
---
--- @return boolean
function API.isAssignableFromType(self, struct)
    if struct.__type__ ~= 'InterfaceStructDefinition' then
        return false;
    end

    --- @cast struct InterfaceStructDefinition

    return self == struct or API.isSuperInterface(self, struct);
end

--- @param interface InterfaceStructDefinition?
---
--- @return boolean
function API.isSuperInterface(self, interface)
    --- @type InterfaceStructDefinition|nil
    local next = self.super;
    while next do
        if next == interface then return true end
        next = next.super;
    end
    return false;
end

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
        pkg = pkg,

        super = definition.extends,
        subClasses = {},
        isChild = enclosingStruct ~= nil,
        outer = enclosingStruct,
        children = {},
        static = definition.static or false,

    };

    -- Make sure that no class is made twice.
    if LVM.forNameDef(id.path) then
        errorf(2, 'Struct is already defined: %s', id.path);
        return id; -- NOTE: Useless return. Makes sure the method doesn't say it'll define something as nil.
    end

    LVM.DEFINITIONS[id.path] = id;

    id.type = 'interface:' .. id.path;
    id.printHeader = string.format('Interface(%s):', id.path);
    id.declaredFields = {};
    id.declaredMethods = {};
    id.lock = false;

    -- Compile the generic parameters for the class.
    id.generics = LVM.generic.compileGenericTypesDefinition(id, definition.generics);

    if enclosingStruct then
        enclosingStruct.children[id.name] = id;
    end

    -- * General API * --
    id.finalize = API.finalize;

    -- * Methodable API * --
    id.addMethod = API.addMethod;
    id.compileMethods = API.compileMethods;
    id.compileMethod = API.compileMethod;
    id.getDeclaredMethods = API.getDeclaredMethods;
    id.getMethod = API.getMethod;
    id.getDeclaredMethod = API.getDeclaredMethod;
    id.getMethodFromLine = API.getMethodFromLine;

    -- * Hierarchical API * --
    id.isSuperInterface = API.isSuperInterface;
    id.isSubInterface = API.isSubInterface;
    id.isAssignableFromType = API.isAssignableFromType;

    return id;
end

--- @cast API LVMInterfaceModule

return API;
