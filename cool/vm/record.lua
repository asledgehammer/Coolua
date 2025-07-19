---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local dump = require 'cool/dump';

local PrintPlus = require 'cool/print';
local errorf = PrintPlus.errorf;
local debugf = PrintPlus.debugf;

local DebugUtils = require 'cool/debug';

local utils = require 'cool/vm/utils';
local isArray = utils.isArray;
local readonly = utils.readonly;

--- @type VM
local vm;

local API = {

    __type__ = 'VMModule',

    --- @param _vm VM
    setVM = function(_vm)
        vm = _vm;
        vm.moduleCount = vm.moduleCount + 1;
    end
};

--- @param struct RecordStruct
local function applyStructMetatable(struct)
    local mt = getmetatable(struct) or {};
    local __properties = {};
    for k, v in pairs(struct) do __properties[k] = v end
    -- mt.__metatable = false;
    mt.__tostring = function() return vm.print.printRecord(struct) end

    mt.__index = function(_, field)
        if vm.isInside() or field == 'super' then
            return __properties[field];
        end

        vm.stepIn();

        local fieldStruct = struct:getField(field);

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            struct = struct,
            element = fieldStruct,
            context = 'field-set',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if not fieldStruct then
            errorf(2, 'FieldNotFoundException: Cannot access field, method, or struct: %s.%s',
                struct.path, field
            );
            return;
        elseif not fieldStruct.static then
            errorf(2, 'StaticFieldException: Accessing non-static field, method, or struct in static context: %s.%s',
                struct.path, field
            );
            return;
        end

        vm.stack.pushContext({
            struct = struct,
            element = fieldStruct,
            context = 'field-set',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if vm.flags.ENABLE_SCOPE then
            -- Ensure that the record is accessible from the scope.
            local recordScopeAllowed = vm.scope.getScopeForCall(struct, callInfo);
            if not vm.scope.canAccessScope(struct.scope, recordScopeAllowed) then
                local sRecord = struct.path;
                local errMsg = string.format(
                    'IllegalAccessException: The record "%s" is "%s".' ..
                    ' (Access Level from call: "%s")\n%s',
                    sRecord,
                    struct.scope, recordScopeAllowed,
                    vm.stack.printStackTrace()
                );
                vm.stack.popContext();
                vm.stepOut();
                print(errMsg);
                error(errMsg, 2);
                return;
            end
        end

        -- Next, ensure that the field is accessible from the scope.
        local fieldScopeAllowed = vm.scope.getScopeForCall(fieldStruct.struct, callInfo);
        if not vm.scope.canAccessScope(fieldStruct.scope, fieldScopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                struct.name, fieldStruct.name,
                fieldStruct.scope, fieldScopeAllowed,
                vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            vm.stepOut();
            print(errMsg);
            error('', 2);
            return;
        end

        vm.stepOut();

        local value = __properties[field];

        -- (Just in-case)
        if value == vm.constants.UNINITIALIZED_VALUE then
            local errMsg = string.format('%s Cannot set %s as UNINITIALIZED_VALUE. (Internal Error)\n%s',
                struct.printHeader, field, vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            error(errMsg, 2);
            return;
        end

        vm.stack.popContext();

        -- Apply forward the value metrics.
        return value;
    end

    mt.__newindex = function(_, field, value)
        if field == 'super' or field == '__super__' then
            errorf(2, '%s Cannot set super. (Static context)', struct.printHeader);
            return;
        end

        -- Post-finalize assignment.
        if field == 'recordObj' and not __properties['recordObj'] then
            __properties['recordObj'] = value;
            return;
        end

        local fieldStruct = struct:getField(field);

        -- Internal bypass for struct construction.
        if vm.isInside() then
            -- Set the value.
            __properties[field] = value;

            -- Apply forward the value metrics. (If defined)
            if fieldStruct then
                fieldStruct.assignedOnce = true;
                fieldStruct.value = value;
            end

            return;
        end

        -- Inner record invocation.
        if struct.inner[field] then
            if vm.isOutside() then
                errorf(2, 'Cannot set inner record explicitly. Use the API.');
            end
            __properties[field] = value;
            return;
        end

        if not fieldStruct then
            errorf(2, 'FieldNotFoundException: Cannot set new field or method: %s.%s',
                struct.path, field
            );
            return;
        elseif not fieldStruct.static then
            errorf(2, 'StaticFieldException: Assigning non-static field in static context: %s.%s',
                struct.path, field
            );
            return;
        end

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            struct = struct,
            element = fieldStruct,
            context = 'field-set',
            line = callInfo.currentLine,
            path = callInfo.path,
            file = callInfo.file
        });

        if vm.flags.ENABLE_SCOPE then
            -- Ensure that the record is accessible from the scope.
            local recordScopeAllowed = vm.scope.getScopeForCall(struct, callInfo);
            if not vm.scope.canAccessScope(struct.scope, recordScopeAllowed) then
                local sRecord = struct.path;
                local errMsg = string.format(
                    'IllegalAccessException: The record "%s" is "%s".' ..
                    ' (Access Level from call: "%s")\n%s',
                    sRecord,
                    struct.scope, recordScopeAllowed,
                    vm.stack.printStackTrace()
                );
                vm.stack.popContext();
                print(errMsg);
                error(errMsg, 2);
                return;
            end
        end

        -- Next, ensure that the field is accessible from the scope.
        local fieldScopeAllowed = vm.scope.getScopeForCall(fieldStruct.struct, callInfo);
        if not vm.scope.canAccessScope(fieldStruct.scope, fieldScopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                struct.name, fieldStruct.name,
                fieldStruct.scope, fieldScopeAllowed,
                vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            print(errMsg);
            error('', 2);
            return;
        end

        -- (Just in-case)
        if value == vm.constants.UNINITIALIZED_VALUE then
            local errMsg = string.format('%s Cannot set %s as UNINITIALIZED_VALUE. (Internal Error)\n%s',
                struct.printHeader, field, vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            error(errMsg, 2);
            return;
        end

        if fieldStruct.final then
            local ste = vm.stack.getContext();
            if not ste then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Record scope.', struct.printHeader, field);
                return;
            end

            local context = ste:getContext();
            local record = ste:getCallingStruct();
            if record ~= struct then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Record scope.', struct.printHeader, field);
                return;
            elseif context ~= 'constructor' then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', struct.printHeader, field);
                return;
            elseif fieldStruct.assignedOnce then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s. (Already defined)', struct.printHeader, field);
                return;
            end
        end

        -- Set the value.
        __properties[field] = value;

        vm.stack.popContext();

        -- Apply forward the value metrics.
        fieldStruct.assignedOnce = true;
        fieldStruct.value = value;
    end

    setmetatable(struct, mt);
end

--- @cast API VMRecordModule

--- Defined for all recordes so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
function API.equals(a, b)
    return a:getClass():getStruct().__middleMethods['equals'](a, b);
end

-- For internal / bottom-level recordes, this will aid in providing methods for what's needed.
local function createPseudoRecordInstance(def)
    -- Prevent infinite loops.
    local __record__ = { getStruct = function() return def; end };
    local mt = {};
    function mt.__tostring()
        return '(Pseudo-Record): ' .. def.name;
    end

    setmetatable(__record__, mt);
    return __record__;
end

--- @param recordInput RecordStructInput|ChildRecordStructInput
--- @param outer Struct?
function API.newRecord(recordInput, outer)
    local locInfo = vm.struct.calcPathNamePackage(recordInput, outer);
    local _, file, folder = vm.scope.getRelativeFile();

    local path = locInfo.path;
    local name = locInfo.name;
    local pkg = locInfo.pkg;

    -- Grab where the call came from.
    local callInfo = vm.scope.getRelativeCall();

    local super = recordInput.extends;
    if super and super.final then
        errorf(2, 'Record cannot extend final Super-Record: %s extends final %s',
            path, super.path
        );
        return;
    end

    -- Prepare & validate interfaces array.
    --- @type InterfaceStruct[]
    local interfaces = {};
    if recordInput.implements then
        if type(recordInput.implements) == 'table' then
            if recordInput.implements.__type__ == 'InterfaceStruct' then
                if not recordInput.implements.__readonly__ then
                    recordInput.implements:finalize();
                end

                if vm.flags.ENABLE_SCOPE then
                    -- Check and see if the calling code can access the interface.
                    local scopeCalled = vm.scope.getScopeForCall(recordInput.implements, callInfo);
                    if not vm.scope.canAccessScope(recordInput.implements.scope, scopeCalled) then
                        local sRecord = path;
                        local sImplements = recordInput.implements.path;
                        local errMsg = string.format(
                            'IllegalAccessException: The record "%s" cannot implement "%s". (access is %s).' ..
                            ' (Access Level from call: "%s")\n%s',
                            sRecord, sImplements,
                            recordInput.implements.scope, scopeCalled,
                            vm.stack.printStackTrace()
                        );
                        print(errMsg);
                        error(errMsg, 2);
                        return;
                    end
                end

                table.insert(interfaces, recordInput.implements);
            else
                if not isArray(recordInput.implements) then
                    error('Not interface array', 2);
                end

                for i = 1, #recordInput.implements do
                    local interface = recordInput.implements[i];
                    if interface.__type__ ~= 'InterfaceStruct' then
                        errorf(2, '%s Implements argument #%i is not a Interface.', path, i);
                    end

                    if not interface.__readonly__ then
                        interface:finalize();
                    end

                    table.insert(interfaces, interface);
                end
            end
        end
    end

    -- Here we check to see if anything has referenced the record prior to initialization. We graft to that reference.
    local recordStruct = vm.STRUCTS[path];

    if not recordStruct then
        vm.STRUCTS[path] = recordStruct;
    end

    recordStruct = setmetatable({}, {
        __tostring = function(self)
            return vm.print.printRecord(self);
        end
    });

    --- @cast recordStruct any

    recordStruct.__type__ = 'RecordStruct';

    -- * Struct Properties * --
    recordStruct.pkg = pkg;
    recordStruct.path = path;
    recordStruct.file = file;
    recordStruct.folder = folder;
    recordStruct.name = name;

    recordStruct.static = recordInput.static or false;
    recordStruct.final = recordInput.final or false;

    -- * Scopable Properties * --
    recordStruct.scope = recordInput.scope or 'package';

    -- * Hierarchical Properties * --
    recordStruct.super = super;
    recordStruct.sub = {};

    -- * Enclosurable Properties * --
    recordStruct.outer = outer;
    recordStruct.inner = {};
    recordStruct.isChild = outer ~= nil;

    -- * Record-Specific Properties * --
    recordStruct.abstract = recordInput.abstract or false;
    recordStruct.interfaces = interfaces;

    -- * Method Properties * --
    recordStruct.methods = {};
    recordStruct.methodCache = {};

    recordStruct.type = recordStruct.path;
    recordStruct.printHeader = string.format('record (%s):', recordStruct.path);
    recordStruct.declaredFields = {};
    recordStruct.declaredMethods = {};
    recordStruct.declaredConstructors = {};
    recordStruct.__readonly__ = false;

    recordStruct.__middleConstructor = vm.executable.createMiddleConstructor(recordStruct);

    if not recordStruct.super and recordStruct.path ~= 'lua.lang.Object' then
        recordStruct.super = vm.getStruct('lua.lang.Object');
        if not recordStruct.super then
            errorf(2, '%s lua.lang.Object not defined!', recordStruct.printHeader);
        end
    end

    if outer then
        outer.inner[recordStruct.name] = recordStruct;
        if recordStruct.static then
            outer[recordStruct.name] = recordStruct;
        end
    end

    --- Set the record to be accessable from a global package reference.
    vm.stepIn();
    vm.package.addToPackageStruct(recordStruct);
    vm.stepOut();

    if super then
        -- Check and see if the calling code can access the record.
        local scopeCalled = vm.scope.getScopeForCall(super, callInfo, recordStruct);
        if not vm.scope.canAccessScope(super.scope, scopeCalled) then
            local sRecord = path;
            local sSuper = super.path;
            local errMsg = string.format(
                'IllegalAccessException: The record "%s" cannot extend "%s". (access is %s).' ..
                ' (Access Level from call: "%s")\n%s',
                sRecord, sSuper,
                super.scope, scopeCalled,
                vm.stack.printStackTrace()
            );
            print(errMsg);
            error(errMsg, 2);
            return;
        end
    end

    for i = 1, #recordStruct.interfaces do
        local interface = recordStruct.interfaces[i];

        -- Check and see if the calling code can access the interface.
        local scopeCalled = vm.scope.getScopeForCall(interface, callInfo, recordStruct);
        if not vm.scope.canAccessScope(interface.scope, scopeCalled) then
            local sRecord = path;
            local sImplements = interface.path;
            local errMsg = string.format(
                'IllegalAccessException: The record "%s" cannot implement "%s". (access is %s).' ..
                ' (Access Level from call: "%s")\n%s',
                sRecord, sImplements,
                interface.scope, scopeCalled,
                vm.stack.printStackTrace()
            );
            print(errMsg);
            error(errMsg, 2);
            return;
        end
    end

    --- @cast recordStruct RecordStruct

    -- MARK: - inner

    function recordStruct:addStaticStruct(struct)
        if struct.outer then
            error('TODO: Document', 2);
        end
        struct.static = true;
        struct:setOuterStruct(self);
    end

    function recordStruct:addInstanceStruct(struct)
        if struct.outer then
            error('TODO: Document', 2);
        end
        struct.static = false;
        struct:setOuterStruct(self);
    end

    function recordStruct:setOuterStruct(outerStruct)
        if self.__readonly__ then
            errorf(2, '%s Cannot set enclosing struct. (Struct is finalized)');
        end

        if self.outer then
            self.outer.inner[self.name] = nil;
            if self.static then
                self.outer[self.name] = nil;
            end
            self.outer = nil;
        end

        local outerLocInfo = vm.struct.calcPathNamePackage(recordInput, outerStruct);
        self.path = outerLocInfo.path;
        self.name = outerLocInfo.name;
        self.pkg = outerLocInfo.pkg;

        if outerStruct then
            outerStruct.inner[self.name] = self;
            if self.static then
                PrintPlus.printf('outer[%s] = %s', self.name, tostring(self));
                outerStruct[self.name] = self;
            end
        end
    end

    -- MARK: - new()

    function recordStruct.new(...)
        -- Make sure that the struct is finalized prior to any instancing.
        if not recordStruct.__readonly__ then
            recordStruct:finalize();
        end

        -- Check and see if the calling code can access the record.
        local newCallInfo = vm.scope.getRelativeCall();

        if vm.flags.ENABLE_SCOPE then
            local scopeCalled = vm.scope.getScopeForCall(recordStruct, newCallInfo);
            if not vm.scope.canAccessScope(recordStruct.scope, scopeCalled) then
                local sRecord = vm.print.printRecord(recordStruct);
                local errMsg = string.format(
                    'IllegalAccessException: The record %s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                    sRecord,
                    recordStruct.scope, scopeCalled,
                    vm.stack.printStackTrace()
                );
                print(errMsg);
                error(errMsg, 2);
                return;
            end
        end

        -- TODO: Check if package-record exists.

        local __record__;
        if recordStruct.path ~= 'lua.lang.Record' then -- Prevent infinite loops.
            __record__ = vm.forName(path);
        else
            __record__ = createPseudoRecordInstance(recordStruct);
        end

        local o = {
            __type__ = recordStruct.path,
            __record__ = __record__,
        };

        -- For native Lua table identity. Helps prevent infinite loops when checking self literally.
        o.__table_id__ = tostring(o);

        --- Assign the middle-functions to the object.
        for methodName, func in pairs(recordStruct.__middleMethods) do
            --- @diagnostic disable-next-line
            o[methodName] = func;
        end

        o.getRecord = function(self)
            if not self.__record__ then
                vm.stepIn();
                self.__record__ = vm.forName(recordStruct.path);
                vm.stepOut();
            end
            return self.__record__;
        end

        -- Assign non-static default values of fields.
        local fields = recordStruct:getFields();
        for i = 1, #fields do
            local fieldStruct = fields[i];
            if not fieldStruct.static then
                o[fieldStruct.name] = fieldStruct.value;
            end
        end

        local middleMethods = recordStruct.__middleMethods;
        for methodName, func in pairs(middleMethods) do
            --- @diagnostic disable-next-line
            o[methodName] = func;
        end

        -- Set instanced inner structs for record instances.
        for _, innerStruct in pairs(recordStruct.inner) do
            if not innerStruct.static then
                o[name] = innerStruct;
            end
        end

        vm.struct.createInstanceMetatable(recordStruct, o);

        -- Invoke constructor context.
        local args = { ... };
        local result, errMsg = xpcall(function()
            recordStruct.__middleConstructor(o, unpack(args));
        end, debug.traceback);

        if not result then error(errMsg, 2) end

        return o;
    end

    -- MARK: - Field

    --- @param fieldInput FieldStructInput
    ---
    --- @return FieldStruct
    function recordStruct:addField(fieldInput)
        --- @type FieldStruct
        local fieldStruct = {
            __type__ = 'FieldStruct',
            audited = false,
            struct = recordStruct,
            types = fieldInput.types,
            type = fieldInput.type,
            name = fieldInput.name,
            scope = fieldInput.scope or 'package',
            static = false,
            final = fieldInput.final or false,
            value = fieldInput.value or vm.constants.UNINITIALIZED_VALUE,
            get = fieldInput.get,
            set = fieldInput.set,
            assignedOnce = false,
        };

        vm.audit.auditField(self, fieldStruct);

        self.declaredFields[fieldStruct.name] = fieldStruct;

        return fieldStruct;
    end

    function recordStruct:addStaticField(fieldInput)
        --- @type FieldStruct
        local fieldStruct = {
            __type__ = 'FieldStruct',
            audited = false,
            struct = recordStruct,
            types = fieldInput.types,
            type = fieldInput.type,
            name = fieldInput.name,
            scope = fieldInput.scope or 'package',
            static = true,
            final = fieldInput.final or false,
            value = fieldInput.value or vm.constants.UNINITIALIZED_VALUE,
            get = fieldInput.get,
            set = fieldInput.set,
            assignedOnce = false,
        };

        vm.audit.auditField(self, fieldStruct);

        self.declaredFields[fieldStruct.name] = fieldStruct;

        return fieldStruct;
    end

    --- Attempts to resolve a FieldStruct in the RecordStruct. If the field isn't declared for the record
    --- level, the super-record(es) are checked.
    ---
    --- @param fieldName string
    ---
    --- @return FieldStruct? FieldStruct
    function recordStruct:getField(fieldName)
        local fd = recordStruct:getDeclaredField(fieldName);
        if not fd and recordStruct.super then
            return recordStruct.super:getField(fieldName);
        end
        return fd;
    end

    --- Attempts to resolve a FieldStruct in the RecordStruct. If the field isn't defined in the record, nil
    --- is returned.
    ---
    --- @param fieldName string
    ---
    --- @return FieldStruct? FieldStruct
    function recordStruct:getDeclaredField(fieldName)
        return recordStruct.declaredFields[fieldName];
    end

    function recordStruct:getFields()
        --- @type FieldStruct[]
        local array = {};

        local next = recordStruct;
        while next do
            for _, fieldStruct in pairs(next.declaredFields) do
                table.insert(array, fieldStruct);
            end
            next = next.super;
        end

        return array;
    end

    -- MARK: - Constructor

    --- @param constructorInput ConstructorStructInput
    ---
    --- @return ConstructorStruct
    function recordStruct:addConstructor(constructorInput)
        -- Some constructors are empty. Allow this to be optional.
        local body = constructorInput.body;
        if not body then body = function() end end

        -- If the super-call is not there, then write
        local _super = constructorInput.super;
        if not _super then _super = vm.executable.defaultSuperFunc end

        -- Friendly check for implementation.
        if not self or type(constructorInput) == 'function' then
            error(
                'Improper method call. (Not instanced) Use MyRecord:addConstructor() instead of MyRecord.addConstructor()',
                2
            );
        end

        local errHeader = string.format('RecordStruct(%s):addConstructor():', recordStruct.name);

        if not constructorInput then
            error(
                string.format(
                    '%s The constructor definition is not provided.',
                    errHeader
                ),
                2
            );
        end

        local parameters = vm.executable.compile(constructorInput);

        local constructorStruct = {

            __type__ = 'ConstructorStruct',

            audited = false,
            struct = recordStruct,
            scope = constructorInput.scope or 'package',
            parameters = parameters,

            -- * Function properties * --
            body = body,
            bodyInfo = vm.executable.getExecutableInfo(body),
            super = _super,
            superInfo = vm.executable.getExecutableInfo(_super),
        };

        constructorStruct.signature = vm.executable.createSignature(constructorStruct);

        --- @cast constructorStruct ConstructorStruct

        --- Validate function.
        if not constructorStruct.body then
            error(string.format('%s function not provided.', errHeader), 2);
        elseif type(constructorStruct.body) ~= 'function' then
            error(
                string.format(
                    '%s property "func" provided is not a function. {type = %s, value = %s}',
                    errHeader,
                    vm.type.getType(constructorStruct.body),
                    tostring(constructorStruct.body)
                ), 2);
        end

        if vm.debug.constructor then
            debugf(vm.debug.constructor, '[CONSTRUCTOR] :: %s Adding record constructor: %s.%s', self.printHeader,
                self.name,
                constructorStruct.signature);
        end

        table.insert(self.declaredConstructors, constructorStruct);

        return constructorStruct;
    end

    --- @param args any[]
    ---
    --- @return ConstructorStruct|nil constructorStruct
    function recordStruct:getConstructor(args)
        local constructor = self:getDeclaredConstructor(args);
        if not constructor and self.super then
            constructor = self.super:getConstructor(args);
        end
        return constructor;
    end

    --- @param args any[]
    ---
    --- @return ConstructorStruct|nil ConstructorStruct
    function recordStruct:getDeclaredConstructor(args)
        args = args or vm.constants.EMPTY_TABLE;
        return vm.executable.resolveConstructor(self.declaredConstructors, args);
    end

    -- MARK: - Method

    function recordStruct:addStaticMethod(MethodStruct)
        local errHeader = string.format('RecordStruct(%s):addMethod():', recordStruct.name);

        local body = MethodStruct.body;
        local bodyInfo = vm.executable.getExecutableInfo(body);

        local scope = vm.audit.auditStructPropertyScope(self.scope, MethodStruct.scope, errHeader);
        local methodName = vm.audit.auditMethodParamName(MethodStruct.name, errHeader);
        local types = vm.audit.auditMethodReturnsProperty(MethodStruct.returnTypes, errHeader);
        local parameters = vm.audit.auditParameters(MethodStruct.parameters, errHeader);

        local methodStruct = {

            __type__ = 'MethodStruct',

            -- Base properties. --
            struct = recordStruct,
            name = methodName,
            returnTypes = types,
            parameters = parameters,
            body = body,
            bodyInfo = bodyInfo,
            scope = scope,

            -- General method flags --
            static = true,
            final = false,
            abstract = false,

            -- Compiled method flags --
            audited = false,
            override = false,
            super = nil,

            -- Always falsify interface flags in record method structs. --
            interface = false,
            default = false,
        };

        methodStruct.signature = vm.executable.createSignature(methodStruct);

        --- @cast methodStruct MethodStruct

        if vm.debug.method then
            local callSyntax = ':';
            if methodStruct.static then callSyntax = '.' end
            debugf(vm.debug.method, '[METHOD] :: %s Adding static method: %s%s%s',
                self.printHeader,
                self.name, callSyntax, methodStruct.signature
            );
        end

        -- Add the definition to the cluster array for the method's name.
        local methodCluster = self.declaredMethods[methodStruct.name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[methodStruct.name] = methodCluster;
        end
        methodCluster[methodStruct.signature] = methodStruct;

        return methodStruct;
    end

    function recordStruct:addAbstractMethod(methodInput)
        local errHeader = string.format('RecordStruct(%s):addAbstractMethod():', recordStruct.name);

        local bodyInfo = vm.executable.getExecutableInfo();

        local scope = vm.audit.auditStructPropertyScope(self.scope, methodInput.scope, errHeader);
        local name = vm.audit.auditMethodParamName(methodInput.name, errHeader);
        local types = vm.audit.auditMethodReturnsProperty(methodInput.returnTypes, errHeader);
        local parameters = vm.audit.auditParameters(methodInput.parameters, errHeader);

        local methodStruct = {
            __type__ = 'MethodStruct',

            -- Base properties. --
            struct = recordStruct,
            name = name,
            returnTypes = types,
            parameters = parameters,
            body = nil,
            bodyInfo = bodyInfo,
            scope = scope,

            -- General method flags --
            static = false,
            final = false,
            abstract = true,

            -- Compiled method flags --
            audited = false,
            override = false,
            super = nil,

            -- Always falsify interface flags in record method structs. --
            interface = false,
            default = false,
        };

        methodStruct.signature = vm.executable.createSignature(methodStruct);

        --- @cast methodStruct MethodStruct

        if vm.debug.method then
            local callSyntax = ':';
            if methodStruct.static then callSyntax = '.' end
            debugf(vm.debug.method, '[METHOD] :: %s Adding abstract method: %s%s%s',
                self.printHeader,
                self.name, callSyntax, methodStruct.signature
            );
        end

        -- Add the struct to the cluster array for the method's name.
        local methodCluster = self.declaredMethods[methodStruct.name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[methodStruct.name] = methodCluster;
        end
        methodCluster[methodStruct.signature] = methodStruct;

        return methodStruct;
    end

    function recordStruct:addMethod(methodInput)
        local body = methodInput.body;
        local bodyInfo = vm.executable.getExecutableInfo(body);
        local errHeader = string.format('RecordStruct(%s):addMethod():', recordStruct.name);
        local scope = vm.audit.auditStructPropertyScope(self.scope, methodInput.scope, errHeader);
        local name = vm.audit.auditMethodParamName(methodInput.name, errHeader);
        local types = vm.audit.auditMethodReturnsProperty(methodInput.returnTypes, errHeader);
        local parameters = vm.audit.auditParameters(methodInput.parameters, errHeader);

        local methodStruct = {

            __type__ = 'MethodStruct',

            -- Base properties. --
            struct = recordStruct,
            name = name,
            returnTypes = types,
            parameters = parameters,
            body = body,
            bodyInfo = bodyInfo,
            scope = scope,

            -- General method flags --
            static = false,
            final = methodInput.final or false,
            abstract = false,

            -- Compiled method flags --
            audited = false,
            override = false,
            super = nil,

            -- Always falsify interface flags in record method structs. --
            interface = false,
            default = false,
        };

        methodStruct.signature = vm.executable.createSignature(methodStruct);

        --- @cast methodStruct MethodStruct

        if vm.debug.method then
            local callSyntax = ':';
            if methodStruct.static then callSyntax = '.' end
            debugf(vm.debug.method, '[METHOD] :: %s Adding instance method: %s%s%s',
                self.printHeader,
                self.name, callSyntax, methodStruct.signature
            );
        end

        -- Add the struct to the cluster array for the method's name.
        local methodCluster = self.declaredMethods[methodStruct.name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[methodStruct.name] = methodCluster;
        end
        methodCluster[methodStruct.signature] = methodStruct;

        return methodStruct;
    end

    --- Attempts to resolve a MethodStruct in the RecordStruct. If the method isn't defined in the record,
    --- `nil` is returned.
    ---
    --- @param methodName string
    ---
    --- @return MethodStruct[]? methods
    function recordStruct:getDeclaredMethods(methodName)
        return recordStruct.declaredMethods[methodName];
    end

    --- @param methodName string
    --- @param args any[]
    ---
    --- @return MethodStruct|nil MethodStruct
    function recordStruct:getMethod(methodName, args)
        return vm.executable.resolveMethod(self, methodName, self.methods[methodName], args);
    end

    --- @param methodName string
    --- @param args any[]
    ---
    --- @return MethodStruct|nil MethodStruct
    function recordStruct:getDeclaredMethod(methodName, args)
        return vm.executable.resolveMethod(self, methodName, self.declaredMethods[methodName], args);
    end

    -- MARK: - finalize()

    --- @return RecordStruct record
    function recordStruct:finalize()
        local errHeader = string.format('Record(%s):finalize():', recordStruct.path);

        if self.__readonly__ then
            errorf(2, '%s Cannot finalize. (Record is already finalized!)', errHeader);
        end

        -- Finalize superrecord.
        if recordStruct.super and not recordStruct.super.__readonly__ then
            recordStruct.super:finalize();
        end

        -- Finalize any interface(s).
        for i = 1, #recordStruct.interfaces do
            if not recordStruct.interfaces[i] then
                recordStruct.interfaces[i]:finalize();
            end
        end

        -- If any auto-methods are defined for fields (get, set), create them before compiling record methods.
        vm.field.compileFieldAutoMethods(self);

        -- TODO: Audit everything.

        --- @type table<string, MethodStruct[]>
        vm.executable.compileMethods(self);

        -- If no constructors are provided, create a default, no-args public constructor.
        if #self.declaredConstructors == 0 then
            self:addConstructor {
                scope = 'public'
            };
        end

        -- Change add methods.
        self.addMethod = function() errorf(2, '%s Cannot add methods. (Record is final!)', errHeader) end
        self.addField = function() errorf(2, '%s Cannot add fields. (Record is final!)', errHeader) end
        self.addConstructor = function() errorf(2, '%s Cannot add constructors. (Record is final!)', errHeader) end

        -- Set default value(s) for recordes.
        for iname, icd in pairs(recordStruct.inner) do
            if icd.static then
                recordStruct[name] = icd;
            end
        end

        -- Set default value(s) for static fields.
        for name, fd in pairs(recordStruct.declaredFields) do
            if fd.static then
                recordStruct[name] = fd.value;
            end
        end

        self.__supertable__ = vm.super.createSuperTable(recordStruct);
        vm.executable.createMiddleMethods(self);
        applyStructMetatable(self);

        for k, v in pairs(self.declaredFields) do
            --- @params T: FieldStruct
            self.declaredFields[k] = readonly(v);
        end
        for _, v in pairs(self.declaredMethods) do
            for sig, method in pairs(v) do
                --- @params T: MethodStruct
                v[sig] = readonly(method);
            end
        end
        for i = 1, #self.declaredConstructors do
            local next = self.declaredConstructors[i];
            --- @params T: ConstructorStruct
            self.declaredConstructors[i] = readonly(next);
        end

        self.__readonly__ = true;
        vm.STRUCTS[recordStruct.path] = recordStruct;

        -- Set record as child.
        if recordStruct.super then
            table.insert(recordStruct.super.sub, recordStruct);
        end

        -- Add a reference for global package and static code.
        if outer then
            vm.stepIn();
            outer[recordStruct.name] = recordStruct;
            vm.stepOut();
        end

        return recordStruct;
    end

    function recordStruct:isSuperRecord(record)
        --- @type Hierarchical|nil
        local next = self.super;
        while next do
            if next == record then return true end
            next = next.super;
        end
        return false;
    end

    --- (Handles recursively going through sub-recordes to see if a record is a sub-record)
    ---
    --- @param subRecord RecordStruct
    --- @param recordToEval RecordStruct
    ---
    --- @return boolean result True if the record to evaluate is a super-record of the subRecord.
    local function __recurseSubRecord(subRecord, recordToEval)
        local subLen = #recordStruct.sub;
        for i = 1, subLen do
            local next = recordStruct.sub[i];
            if next:isAssignableFromType(recordToEval) or __recurseSubRecord(next, recordToEval) then
                return true;
            end
        end
        return false;
    end

    function recordStruct:isSubRecord(record)
        if __recurseSubRecord(recordStruct, record) then
            return true;
        end
        return false;
    end

    --- @param superInterface InterfaceStruct
    ---
    --- @return boolean
    function recordStruct:isSuperInterface(superInterface)
        for i = 1, #self.interfaces do
            local interface = self.interfaces[i];
            if superInterface == interface then
                return true;
            end
        end

        if recordStruct.super then
            return recordStruct.super:isSuperInterface(superInterface);
        end

        return false;
    end

    function recordStruct:isAssignableFromType(superStruct)
        if not superStruct then return false end

        if superStruct.__type__ == 'RecordStruct' then
            return self == superStruct or self:isSuperRecord(superStruct);
        elseif superStruct.__type__ == 'InterfaceStruct' then
            return self:isSuperInterface(superStruct);
        end

        return false;
    end

    function recordStruct:isFinalized()
        return self.__readonly__;
    end

    return recordStruct;
end

return API;
