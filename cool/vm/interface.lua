---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;

local utils = require 'cool/vm/utils';
local readonly = utils.readonly;

--- @type VM
local vm;

local API = {

    __type__ = 'VMModule',

    -- Method(s)
    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

-- Internal API
local IAPI = {};

function IAPI.applyStructMetatable(self)
    local mt = getmetatable(self) or {};
    local __properties = {};
    for k, v in pairs(self) do __properties[k] = v end
    -- mt.__metatable = false;
    mt.__tostring = function() return vm.print.printInterface(self) end

    local finalizing = false;

    mt.__index = function(_, field)
        -- Interfaces cannot be instantiated so access to anything requires finalization.
        if not finalizing and not self.__readonly__ then
            finalizing = true;
            self:finalize();
            finalizing = false;
        end

        return __properties[field];
    end

    mt.__newindex = function(tbl, field, value)
        -- TODO: Visibility scope analysis.
        -- TODO: Type-checking.

        if not self.__readonly__ then
            __properties[field] = value;
            return;
        end

        -- Interfaces cannot be instantiated so access to anything requires finalization.
        if not finalizing and not self.__readonly__ then
            finalizing = true;
            self:finalize();
            finalizing = false;
        end

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
            if vm.isOutside() then
                errorf(2, 'Cannot set inner struct explicitly. Use the API.');
            end

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

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            struct = self,
            element = fd,
            context = 'field-set',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if vm.flags.ENABLE_SCOPE then
            local classScopeAllowed = vm.scope.getScopeForCall(self, callInfo);

            -- Ensure that the interface is accessible from the scope.
            if not vm.scope.canAccessScope(self.scope, classScopeAllowed) then
                local sClass = self.path;
                local errMsg = string.format(
                    'IllegalAccessException: The interface "%s" is "%s".' ..
                    ' (Access Level from call: "%s")\n%s',
                    sClass,
                    self.scope, classScopeAllowed,
                    vm.stack.printStackTrace()
                );
                print(errMsg);
                error(errMsg, 2);
                return;
            end

            -- Next, ensure that the field is accessible from the scope.
            local fieldScopeAllowed = vm.scope.getScopeForCall(fd.struct, callInfo);
            if not vm.scope.canAccessScope(fd.scope, fieldScopeAllowed) then
                local errMsg = string.format(
                    'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                    self.name, fd.name,
                    fd.scope, fieldScopeAllowed,
                    vm.stack.printStackTrace()
                );
                vm.stack.popContext();
                print(errMsg);
                error('', 2);
                return;
            end
        end

        -- (Just in-case)
        if value == vm.constants.UNINITIALIZED_VALUE then
            local errMsg = string.format('%s Cannot set %s as UNINITIALIZED_VALUE. (Internal Error)\n%s',
                self.printHeader, field, vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            error(errMsg, 2);
            return;
        end

        if fd.final then
            local ste = vm.stack.getContext();
            if not ste then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of interface scope.', self.printHeader, field);
                return;
            end

            local context = ste:getContext();
            local class = ste:getCallingStruct();
            if class ~= self then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of interface scope.', self.printHeader, field);
                return;
            elseif context ~= 'constructor' then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', self.printHeader, field);
                return;
            elseif fd.assignedOnce then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s. (Already defined)', self.printHeader, field);
                return;
            end
        end

        -- Set the value.
        __properties[field] = value;

        vm.stack.popContext();

        -- Apply forward the value metrics.
        fd.assignedOnce = true;
        fd.value = value;
    end

    setmetatable(self, mt);
end

--- @cast API VMInterfaceModule

--- (Handles recursively going through sub-interfaces to see if a class is a sub-class)
---
--- @param subInterface InterfaceStruct
--- @param interfaceToEval InterfaceStruct
---
--- @return boolean result True if the interface to evaluate is a super-class of the subClass.
function IAPI.__recurseSubInterface(subInterface, interfaceToEval)
    local len = #subInterface.sub;
    for i = 1, len do
        local next = subInterface.sub[i];
        if next:isAssignableFromType(interfaceToEval) or IAPI.__recurseSubInterface(next, interfaceToEval) then
            return true;
        end
    end
    return false;
end

function API.newInterface(interfaceInput, outer)
    -- Grab path / package / name context.
    local locInfo = vm.struct.calcPathNamePackage(interfaceInput, outer);
    local path = locInfo.path;
    local interfaceName = locInfo.name;
    local pkg = locInfo.pkg;

    local _, file, folder = vm.scope.getRelativeFile();

    --- @type any
    local interfaceStruct = vm.STRUCTS[path] or {};

    local extends = interfaceInput.extends;

    -- * Internal Type * --
    interfaceStruct.__type__ = 'InterfaceStruct';

    -- * Struct Properties * --
    interfaceStruct.path = path;
    interfaceStruct.name = interfaceName;
    interfaceStruct.pkg = pkg;
    interfaceStruct.file = file;
    interfaceStruct.folder = folder;
    interfaceStruct.type = 'interface:' .. path;

    interfaceStruct.static = interfaceInput.static or false;

    -- * Scopable Properties * --
    interfaceStruct.scope = interfaceInput.scope or 'package';

    -- * Hierarchical Properties * --
    interfaceStruct.extends = extends;
    interfaceStruct.subClasses = {};

    -- * Enclosurable Properties * --
    interfaceStruct.outer = outer;
    interfaceStruct.inner = {};
    interfaceStruct.isChild = outer ~= nil;
    interfaceStruct.children = {};

    -- * Fieldable Properties * --
    interfaceStruct.declaredFields = {};

    -- * Methodable Properties * --
    interfaceStruct.declaredMethods = {};
    interfaceStruct.methods = {};
    interfaceStruct.methodCache = {};

    -- * Debug Properties * --
    interfaceStruct.printHeader = string.format('interface (%s):', path);

    interfaceStruct.__readonly__ = false;

    --- @cast interfaceStruct InterfaceStruct

    vm.STRUCTS[interfaceStruct.path] = interfaceStruct;

    -- Enclosurable: Add the definition to the enclosing struct.
    if outer then
        outer.inner[interfaceStruct.name] = interfaceStruct;
    end

    --- Set the class to be accessable from a global package reference.
    vm.stepIn();
    vm.package.addToPackageStruct(interfaceStruct);
    vm.stepOut();

    if extends then
        -- Grab where the call came from.
        local callInfo = vm.scope.getRelativeCall();

        if vm.flags.ENABLE_SCOPE then
            -- Check and see if the calling code can access the class.
            local scopeCalled = vm.scope.getScopeForCall(extends, callInfo, interfaceStruct);
            if not vm.scope.canAccessScope(extends.scope, scopeCalled) then
                local sClass = path;
                local sSuper = extends.path;
                local errMsg = string.format(
                    'IllegalAccessException: The interface "%s" cannot extend "%s". (access is %s).' ..
                    ' (Access Level from call: "%s")\n%s',
                    sClass, sSuper,
                    extends.scope, scopeCalled,
                    vm.stack.printStackTrace()
                );
                print(errMsg);
                error(errMsg, 2);
                return;
            end
        end
    end

    -- MARK: - Inner

    function interfaceStruct:addStaticStruct(struct)
        if struct.outer then
            error('TODO: Document', 2);
        end
        struct.static = true;
        struct:setOuterStruct(self);
    end

    function interfaceStruct:setOuterStruct(outer)
        if self.__readonly__ then
            errorf(2, '%s Cannot set enclosing struct. (Struct is finalized)');
        end

        if self.outer then
            self.outer.inner[self.name] = nil;
            self.outer = nil;
        end

        local outerStructLocInfo = vm.struct.calcPathNamePackage(interfaceInput, outer);
        self.path = outerStructLocInfo.path;
        self.name = outerStructLocInfo.name;
        self.pkg = outerStructLocInfo.pkg;

        if outer then
            outer.inner[self.name] = self;
            outer[self.name] = self;
        end
    end

    -- * General API * --
    function interfaceStruct:finalize()
        local errHeader = string.format('Interface(%s):finalize():', self.path);

        if self.__readonly__ then
            errorf(2, '%s Cannot finalize. (Interface is already finalized!)', errHeader);
        elseif self.super and (self.super.__type__ == 'ClassStruct' and not self.super.__readonly__) then
            errorf(2, '%s Cannot finalize. (Super-Interface %s is not finalized!)', errHeader, self.path);
        end

        -- If any auto-methods are defined for fields (get, set), create them before compiling class methods.
        vm.field.compileFieldAutoMethods(self);

        -- TODO: Audit everything.

        vm.executable.compileMethods(self);

        -- Change add methods.
        self.addMethod = function() errorf(2, '%s Cannot add methods. (Interface is final!)', errHeader) end

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
                        local sMethod = vm.print.printMethod(md);
                        errorf(2, '%s Method cannot override final method in super-class: %s',
                            errHeader,
                            md.super.struct.name,
                            sMethod
                        );
                        return self;
                        -- RULE: Cannot reduce scope of overrided super-method.
                    elseif not vm.scope.canAccessScope(md.scope, md.super.scope) then
                        local sMethod = vm.print.printMethod(md);
                        errorf(2, '%s Method cannot reduce scope of super-class: %s (super-scope = %s, scope = %s)',
                            errHeader,
                            sMethod, md.super.scope, md.scope
                        );
                        return self;
                        -- RULE: override Methods must either be consistently static (or not) with their super-method(s).
                    elseif md.static ~= md.super.static then
                        local sMethod = vm.print.printMethod(md);
                        errorf(2,
                            '%s All method(s) with identical signatures must either be static or not: %s (super.static = %s, static = %s)',
                            errHeader,
                            sMethod, tostring(md.super.static), tostring(md.static)
                        );
                        return self;
                    end
                end
            end
            self.__middleMethods[name] = vm.executable.createMiddleMethod(self, name, methods);
        end

        -- Add static method references.
        for methodName, mCluster in pairs(self.declaredMethods) do
            self[methodName] = self.__middleMethods[methodName];
        end

        local declaredFields = {};
        for k, v in pairs(self.declaredFields) do
            --- @params T: FieldStruct
            declaredFields[k] = readonly(v);
        end
        self.declaredFields = declaredFields;

        local declaredMethods = {};
        for methodName, v in pairs(self.declaredMethods) do
            declaredMethods[methodName] = {};
            for sig, methodStruct in pairs(v) do
                --- @params T: MethodStruct
                declaredMethods[methodName][sig] = readonly(methodStruct);
            end
        end
        self.declaredMethods = declaredMethods;

        self.__readonly__ = true;
        vm.STRUCTS[self.path] = self;

        -- Set class as child.
        if self.super then
            table.insert(self.super.sub, self);
        end

        -- Add a reference for global package and static code to enclosing struct.
        if self.outer then
            vm.stepIn();
            self.outer[self.name] = self;
            vm.stepOut();
        end

        return self;
    end

    -- * Fieldable API * --

    function interfaceStruct:addStaticField(fieldInput)
        --- @type FieldStruct
        local fieldStruct = {
            __type__ = 'FieldStruct',
            audited = false,
            struct = self,
            types = fieldInput.types,
            type = fieldInput.type,
            name = fieldInput.name,
            scope = 'public',
            static = true,
            final = true,
            value = fieldInput.value,
            get = fieldInput.get,
            set = fieldInput.set,
            assignedOnce = false,
        };

        vm.audit.auditField(self, fieldStruct);

        -- Ensure that all constants are defined.
        if not fieldStruct.value then
            errorf(2, '%s Cannot add interface field without a value: %s', self.printHeader, fieldStruct.name);
        end

        self.declaredFields[fieldStruct.name] = fieldStruct;

        return fieldStruct;
    end

    function interfaceStruct:getDeclaredField(fieldName)
        return self.declaredFields[fieldName];
    end

    function interfaceStruct:getField(fieldName)
        local fieldStruct = self:getDeclaredField(fieldName);
        if not fieldStruct and self.super then
            return self.super:getField(fieldName);
        end
        return fieldStruct;
    end

    function interfaceStruct:getFields()
        --- @type FieldStruct[]
        local array = {};

        local next = self;
        while next do
            for _, fieldStruct in pairs(next.declaredFields) do
                table.insert(array, fieldStruct);
            end
            next = next.super;
        end

        return array;
    end

    --- @param self InterfaceStruct
    --- @param MethodStruct InterfaceMethodStructInput
    ---
    --- @return MethodStruct
    function interfaceStruct:addMethod(MethodStruct)
        local errHeader = string.format('InterfaceStruct(%s):addMethod():', self.name);

        local body = MethodStruct.body;
        local bodyInfo = vm.executable.getExecutableInfo(body);

        local name = vm.audit.auditMethodParamName(MethodStruct.name, errHeader);
        local types = vm.audit.auditMethodReturnsProperty(MethodStruct.returnTypes, errHeader);
        local parameters = vm.audit.auditParameters(MethodStruct.parameters, errHeader);

        local md = {

            __type__ = 'MethodStruct',

            -- Base properties. --
            struct = self,
            name = name,
            returnTypes = types,
            parameters = parameters,
            body = body,

            -- Used for scope-visibility analysis. --
            scope = 'public',
            bodyInfo = bodyInfo,

            -- General method flags --
            static = false,
            final = false, -- Cannot define finals in a interface context.

            -- Compiled method flags --
            audited = false,
            override = false,
            super = nil,

            -- Interface definition. --
            interface = self, -- Lets the VM know this belongs to an interface.
            default = body ~= nil,

            -- Always falsify class flags in class method definitions. --
            abstract = false,
        };

        md.signature = vm.executable.createSignature(md);

        --- @cast md MethodStruct

        local methodCluster = self.declaredMethods[md.name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[md.name] = methodCluster;
        end
        methodCluster[md.signature] = md;

        return md;
    end

    function interfaceStruct:addStaticMethod(methodInput)
        local errHeader = string.format('InterfaceStruct(%s):addStaticMethod():', self.name);

        local body = methodInput.body;

        local scope = vm.audit.auditStructPropertyScope(self.scope, methodInput.scope, errHeader);
        local name = vm.audit.auditMethodParamName(methodInput.name, errHeader);
        local types = vm.audit.auditMethodReturnsProperty(methodInput.returnTypes, errHeader);
        local parameters = vm.audit.auditParameters(methodInput.parameters, errHeader);
        local bodyInfo = vm.executable.getExecutableInfo(body);

        local methodStruct = {

            __type__ = 'MethodStruct',

            -- Base properties. --
            struct = self,
            name = name,
            returnTypes = types,
            parameters = parameters,
            body = body,
            bodyInfo = bodyInfo,

            -- Used for scope-visibility analysis. --
            scope = scope,

            -- General method flags --
            static = true,
            final = false, -- Cannot define finals in a interface context.

            -- Compiled method flags --
            audited = false,
            override = false,
            super = nil,

            -- Interface struct. --
            interface = self, -- Lets the VM know this belongs to an interface.
            default = body ~= nil,

            -- Always falsify class flags in class method structs. --
            abstract = false,
        };

        methodStruct.signature = vm.executable.createSignature(methodStruct);

        --- @cast methodStruct MethodStruct

        local methodCluster = self.declaredMethods[methodStruct.name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[methodStruct.name] = methodCluster;
        end
        methodCluster[methodStruct.signature] = methodStruct;

        return methodStruct;
    end

    --- @param self InterfaceStruct
    --- @param line integer
    ---
    --- @return MethodStruct|nil methodStruct
    function interfaceStruct:getMethodFromLine(line)
        --- @type MethodStruct
        local methodStruct;
        for _, methodStructCluster in pairs(self.declaredMethods) do
            for i = 1, #methodStructCluster do
                methodStruct = methodStructCluster[i];
                if line >= methodStruct.lineRange.start and line <= methodStruct.lineRange.stop then
                    return methodStruct;
                end
            end
        end
        return nil;
    end

    function interfaceStruct:getDeclaredMethods(methodName)
        return self.declaredMethods[methodName];
    end

    function interfaceStruct:getMethod(methodName, args)
        return vm.executable.resolveMethod(self, methodName, self.methods[methodName], args);
    end

    function interfaceStruct:getDeclaredMethod(methodName, args)
        return vm.executable.resolveMethod(self, methodName, self.declaredMethods[methodName], args);
    end

    -- * Hierarchical API * --
    function interfaceStruct:isSuperInterface(interface)
        --- @type InterfaceStruct|nil
        local next = self.super;
        while next do
            if next == interface then return true end
            next = next.super;
        end
        return false;
    end

    function interfaceStruct:isSubInterface(subInterfaceStruct)
        if IAPI.__recurseSubInterface(self, subInterfaceStruct) then
            return true;
        end
        return false;
    end

    function interfaceStruct:isAssignableFromType(struct)
        if not struct or struct.__type__ ~= 'InterfaceStruct' then
            return false;
        end

        --- @cast struct InterfaceStruct

        return self == struct or self:isSuperInterface(struct);
    end

    function interfaceStruct:isFinalized()
        return self.__readonly__;
    end

    function interfaceStruct:getStruct()
        return self;
    end

    IAPI.applyStructMetatable(interfaceStruct);

    return interfaceStruct;
end

return API;
