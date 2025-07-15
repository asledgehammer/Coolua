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

local function applyStructMetatable(cd)
    local mt = getmetatable(cd) or {};
    local __properties = {};
    for k, v in pairs(cd) do __properties[k] = v end
    -- mt.__metatable = false;
    mt.__tostring = function() return vm.print.printClass(cd) end

    mt.__index = function(self, field)
        if vm.isInside() or field == 'super' then
            return __properties[field];
        end

        vm.stepIn();

        local fd = cd:getField(field);

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            class = cd,
            element = fd,
            context = 'field-set',
            line = callInfo.currentLine,
            path = callInfo.path
        });

        if not fd then
            errorf(2, 'FieldNotFoundException: Cannot access field, method, or struct: %s.%s',
                cd.path, field
            );
            return;
        elseif not fd.static then
            errorf(2, 'StaticFieldException: Accessing non-static field, method, or struct in static context: %s.%s',
                cd.path, field
            );
            return;
        end

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            class = cd,
            element = fd,
            context = 'field-set',
            line = callInfo.currentLine,
            path = callInfo.path
        });

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
            vm.stack.popContext();
            vm.stepOut();
            print(errMsg);
            error(errMsg, 2);
            return;
        end

        -- Next, ensure that the field is accessible from the scope.
        local fieldScopeAllowed = vm.scope.getScopeForCall(fd.class, callInfo);
        if not vm.scope.canAccessScope(fd.scope, fieldScopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cd.name, fd.name,
                fd.scope, fieldScopeAllowed,
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
                cd.printHeader, field, vm.stack.printStackTrace()
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
        -- TODO: Visibility scope analysis.
        -- TODO: Type-checking.

        if field == 'super' or field == '__super__' then
            errorf(2, '%s Cannot set super. (Static context)', cd.printHeader);
            return;
        end

        -- Post-finalize assignment.
        if field == 'classObj' and not __properties['classObj'] then
            __properties['classObj'] = value;
            return;
        end

        local fd = cd:getField(field);

        -- Internal bypass for struct construction.
        if vm.isInside() then
            -- Set the value.
            __properties[field] = value;

            -- Apply forward the value metrics. (If defined)
            if fd then
                fd.assignedOnce = true;
                fd.value = value;
            end

            return;
        end

        -- Inner class invocation.
        if cd.inner[field] then
            if vm.isOutside() then
                errorf(2, 'Cannot set inner class explicitly. Use the API.');
            end
            __properties[field] = value;
            return;
        end

        if not fd then
            errorf(2, 'FieldNotFoundException: Cannot set new field or method: %s.%s',
                cd.path, field
            );
            return;
        elseif not fd.static then
            errorf(2, 'StaticFieldException: Assigning non-static field in static context: %s.%s',
                cd.path, field
            );
            return;
        end

        local callInfo = vm.scope.getRelativeCall();

        vm.stack.pushContext({
            class = cd,
            element = fd,
            context = 'field-set',
            line = callInfo.currentLine,
            path = callInfo.path
        });

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
            vm.stack.popContext();
            print(errMsg);
            error(errMsg, 2);
            return;
        end

        -- Next, ensure that the field is accessible from the scope.
        local fieldScopeAllowed = vm.scope.getScopeForCall(fd.class, callInfo);
        if not vm.scope.canAccessScope(fd.scope, fieldScopeAllowed) then
            local errMsg = string.format(
                'IllegalAccessException: The field %s.%s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                cd.name, fd.name,
                fd.scope, fieldScopeAllowed,
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
                cd.printHeader, field, vm.stack.printStackTrace()
            );
            vm.stack.popContext();
            error(errMsg, 2);
            return;
        end

        if fd.final then
            local ste = vm.stack.getContext();
            if not ste then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                return;
            end

            local context = ste:getContext();
            local class = ste:getCallingClass();
            if class ~= cd then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                return;
            elseif context ~= 'constructor' then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', cd.printHeader, field);
                return;
            elseif fd.assignedOnce then
                vm.stack.popContext();
                errorf(2, '%s Attempt to assign final field %s. (Already defined)', cd.printHeader, field);
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

    setmetatable(cd, mt);
end

--- @cast API VMClassModule

--- Defined for all classes so that __eq actually fires.
--- Reference: http://lua-users.org/wiki/MetatableEvents
---
--- @param a Object
--- @param b any
---
--- @return boolean result
function API.equals(a, b)
    return a:getClass():getDefinition().__middleMethods['equals'](a, b);
end

-- For internal / bottom-level classes, this will aid in providing methods for what's needed.
local function createPseudoClassInstance(def)
    -- Prevent infinite loops.
    local __class__ = { getDefinition = function() return def; end };
    local mt = {};
    function mt.__tostring()
        return '(Pseudo-Class): ' .. def.name;
    end

    setmetatable(__class__, mt);
    return __class__;
end

--- @param definition ClassStructParameter|ChildClassStructParameter
--- @param outer StructDefinition?
function API.newClass(definition, outer)
    local locInfo = vm.struct.calcPathNamePackage(definition, outer);
    local _, file, folder = vm.scope.getRelativeFile();

    local path = locInfo.path;
    local name = locInfo.name;
    local pkg = locInfo.pkg;

    -- Make sure the class cannot be both final and abstract at the same time.
    if definition.final and definition.abstract then
        errorf(2, 'Class cannot be abstract AND final: %s', path);
        return;
    end

    -- Grab where the call came from.
    local callInfo = vm.scope.getRelativeCall();

    local super = definition.extends;
    if super and super.final then
        errorf(2, 'Class cannot extend final Super-Class: %s extends final %s',
            path, super.path
        );
        return;
    end

    -- Prepare & validate interfaces array.
    --- @type InterfaceStruct[]
    local interfaces = {};
    if definition.implements then
        if type(definition.implements) == 'table' then
            if definition.implements.__type__ == 'InterfaceStruct' then
                if not definition.implements.__readonly__ then
                    definition.implements:finalize();
                end

                -- Check and see if the calling code can access the interface.
                local scopeCalled = vm.scope.getScopeForCall(definition.implements, callInfo);
                if not vm.scope.canAccessScope(definition.implements.scope, scopeCalled) then
                    local sClass = path;
                    local sImplements = definition.implements.path;
                    local errMsg = string.format(
                        'IllegalAccessException: The class "%s" cannot implement "%s". (access is %s).' ..
                        ' (Access Level from call: "%s")\n%s',
                        sClass, sImplements,
                        definition.implements.scope, scopeCalled,
                        vm.stack.printStackTrace()
                    );
                    print(errMsg);
                    error(errMsg, 2);
                    return;
                end

                table.insert(interfaces, definition.implements);
            else
                if not isArray(definition.implements) then
                    error('Not interface array', 2);
                end

                for i = 1, #definition.implements do
                    local interface = definition.implements[i];
                    if interface.__type__ ~= 'InterfaceStruct' then
                        print('interface.__type__ = ', interface.__type__);
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

    -- Here we check to see if anything has referenced the class prior to initialization. We graft to that reference.
    local cd = vm.DEFINITIONS[path];

    if not cd then
        vm.DEFINITIONS[path] = cd;
    end

    cd = setmetatable({}, {
        __tostring = function(self)
            return vm.print.printClass(self);
        end
    });

    --- @cast cd any

    cd.__type__ = 'ClassStruct';

    -- * Struct Properties * --
    cd.pkg = pkg;
    cd.path = path;
    cd.file = file;
    cd.folder = folder;
    cd.name = name;

    cd.static = definition.static or false;
    cd.final = definition.final or false;

    -- * Scopable Properties * --
    cd.scope = definition.scope or 'package';

    -- * Hierarchical Properties * --
    cd.super = super;
    cd.sub = {};

    -- * Enclosurable Properties * --
    cd.outer = outer;
    cd.inner = {};
    cd.isChild = outer ~= nil;

    -- * Class-Specific Properties * --
    cd.abstract = definition.abstract or false;
    cd.interfaces = interfaces;

    -- * Method Properties * --
    cd.methods = {};
    cd.methodCache = {};

    cd.type = cd.path;
    cd.printHeader = string.format('class (%s):', cd.path);
    cd.declaredFields = {};
    cd.declaredMethods = {};
    cd.declaredConstructors = {};
    cd.__readonly__ = false;

    -- Compile the generic parameters for the class.
    cd.generics = vm.generic.compileGenericTypesDefinition(cd, definition.generics);

    cd.__middleConstructor = vm.executable.createMiddleConstructor(cd);

    if not cd.super and cd.path ~= 'lua.lang.Object' then
        cd.super = vm.forNameDef('lua.lang.Object');
        if not cd.super then
            errorf(2, '%s lua.lang.Object not defined!', cd.printHeader);
        end
    end

    if outer then
        outer.inner[cd.name] = cd;
        if cd.static then
            outer[cd.name] = cd;
        end
    end

    --- Set the class to be accessable from a global package reference.
    vm.stepIn();
    vm.package.addToPackageStruct(cd);
    vm.stepOut();

    if super then
        -- Check and see if the calling code can access the class.
        local scopeCalled = vm.scope.getScopeForCall(super, callInfo, cd);
        if not vm.scope.canAccessScope(super.scope, scopeCalled) then
            local sClass = path;
            local sSuper = super.path;
            local errMsg = string.format(
                'IllegalAccessException: The class "%s" cannot extend "%s". (access is %s).' ..
                ' (Access Level from call: "%s")\n%s',
                sClass, sSuper,
                super.scope, scopeCalled,
                vm.stack.printStackTrace()
            );
            print(errMsg);
            error(errMsg, 2);
            return;
        end
    end

    for i = 1, #cd.interfaces do
        local interface = cd.interfaces[i];

        -- Check and see if the calling code can access the interface.
        local scopeCalled = vm.scope.getScopeForCall(interface, callInfo, cd);
        if not vm.scope.canAccessScope(interface.scope, scopeCalled) then
            local sClass = path;
            local sImplements = interface.path;
            local errMsg = string.format(
                'IllegalAccessException: The class "%s" cannot implement "%s". (access is %s).' ..
                ' (Access Level from call: "%s")\n%s',
                sClass, sImplements,
                interface.scope, scopeCalled,
                vm.stack.printStackTrace()
            );
            print(errMsg);
            error(errMsg, 2);
            return;
        end
    end

    --- @cast cd ClassStruct

    -- MARK: - inner

    function cd:addStaticStruct(struct)
        if struct.outer then
            error('TODO: Document', 2);
        end
        struct.static = true;
        struct:setOuterStruct(self);
    end

    function cd:addInstanceStruct(struct)
        if struct.outer then
            error('TODO: Document', 2);
        end
        struct.static = false;
        struct:setOuterStruct(self);
    end

    function cd:setOuterStruct(outer)
        if self.__readonly__ then
            errorf(2, '%s Cannot set enclosing struct. (definition is finalized)');
        end

        if self.outer then
            self.outer.inner[self.name] = nil;
            if self.static then
                self.outer[self.name] = nil;
            end
            self.outer = nil;
        end

        local locInfo = vm.struct.calcPathNamePackage(definition, outer);
        self.path = locInfo.path;
        self.name = locInfo.name;
        self.pkg = locInfo.pkg;

        if outer then
            outer.inner[self.name] = self;
            if self.static then
                PrintPlus.printf('outer[%s] = %s', self.name, tostring(self));
                outer[self.name] = self;
            end
        end
    end

    -- MARK: - new()

    function cd.new(...)
        local errHeader = string.format('Class(%s):new():', cd.name);

        if not cd.__readonly__ then
            cd:finalize();
            -- errorf(2, '%s Cannot invoke constructor. (ClassStruct is not finalized!)', errHeader);
        end

        -- Check and see if the calling code can access the class.
        local callInfo = vm.scope.getRelativeCall();
        local scopeCalled = vm.scope.getScopeForCall(cd, callInfo);
        if not vm.scope.canAccessScope(cd.scope, scopeCalled) then
            local sClass = vm.print.printClass(cd);
            local errMsg = string.format(
                'IllegalAccessException: The class %s is set as "%s" access level. (Access Level from call: "%s")\n%s',
                sClass,
                cd.scope, scopeCalled,
                vm.stack.printStackTrace()
            );
            print(errMsg);
            error(errMsg, 2);
            return;
        end

        -- TODO: Check if package-class exists.

        local __class__;
        if cd.path ~= 'lua.lang.Class' then -- Prevent infinite loops.
            __class__ = vm.forName(path);
        else
            __class__ = createPseudoClassInstance(cd);
        end

        local o = {
            __type__ = 'ClassInstance',
            __class__ = __class__,
        };

        -- For native Lua table identity. Helps prevent infinite loops when checking self literally.
        o.__table_id__ = tostring(o);


        --- Assign the middle-functions to the object.
        for name, func in pairs(cd.__middleMethods) do
            --- @diagnostic disable-next-line
            o[name] = func;
        end

        o.getClass = function(self)
            if not self.__class__ then
                vm.stepIn();
                self.__class__ = vm.forName(cd.path);
                vm.stepOut();
            end
            return self.__class__;
        end

        -- Assign non-static default values of fields.
        local fields = cd:getFields();
        for i = 1, #fields do
            local fd = fields[i];
            if not fd.static then
                o[fd.name] = fd.value;
            end
        end

        local middleMethods = cd.__middleMethods;
        for name, func in pairs(middleMethods) do
            --- @diagnostic disable-next-line
            o[name] = func;
        end

        -- Set instanced inner structs for class instances.
        for iname, icd in pairs(cd.inner) do
            if not icd.static then
                o[name] = icd;
            end
        end

        vm.struct.createInstanceMetatable(cd, o);

        -- Invoke constructor context.
        local args = { ... };
        local result, errMsg = xpcall(function()
            cd.__middleConstructor(o, unpack(args));
        end, debug.traceback);

        if not result then error(errMsg, 2) end

        return o;
    end

    -- MARK: - Field

    --- @param fd FieldStructInput
    ---
    --- @return FieldStruct
    function cd:addField(fd)
        --- @type FieldStruct
        local args = {
            __type__ = 'FieldStruct',
            audited = false,
            class = cd,
            types = fd.types,
            type = fd.type,
            name = fd.name,
            scope = fd.scope or 'package',
            static = false,
            final = fd.final or false,
            value = fd.value or vm.constants.UNINITIALIZED_VALUE,
            get = fd.get,
            set = fd.set,
            assignedOnce = false,
        };

        vm.audit.auditField(self, args);

        self.declaredFields[args.name] = args;

        return args;
    end

    function cd:addStaticField(fd)
        --- @type FieldStruct
        local args = {
            __type__ = 'FieldStruct',
            audited = false,
            class = cd,
            types = fd.types,
            type = fd.type,
            name = fd.name,
            scope = fd.scope or 'package',
            static = true,
            final = fd.final or false,
            value = fd.value or vm.constants.UNINITIALIZED_VALUE,
            get = fd.get,
            set = fd.set,
            assignedOnce = false,
        };

        vm.audit.auditField(self, args);

        self.declaredFields[args.name] = args;

        return args;
    end

    --- Attempts to resolve a FieldStruct in the ClassStruct. If the field isn't declared for the class
    --- level, the super-class(es) are checked.
    ---
    --- @param name string
    ---
    --- @return FieldStruct? FieldStruct
    function cd:getField(name)
        local fd = cd:getDeclaredField(name);
        if not fd and cd.super then
            return cd.super:getField(name);
        end
        return fd;
    end

    --- Attempts to resolve a FieldStruct in the ClassStruct. If the field isn't defined in the class, nil
    --- is returned.
    ---
    --- @param name string
    ---
    --- @return FieldStruct? FieldStruct
    function cd:getDeclaredField(name)
        return cd.declaredFields[name];
    end

    function cd:getFields()
        --- @type FieldStruct[]
        local array = {};

        local next = cd;
        while next do
            for _, fd in pairs(next.declaredFields) do
                table.insert(array, fd);
            end
            next = next.super;
        end

        return array;
    end

    -- MARK: - Constructor

    --- @param ConstructorStruct ConstructorStructParameter
    ---
    --- @return ConstructorStruct
    function cd:addConstructor(ConstructorStruct)
        -- Some constructors are empty. Allow this to be optional.
        local body = ConstructorStruct.body;
        if not body then body = function() end end

        -- If the super-call is not there, then write
        local _super = ConstructorStruct.super;
        if not _super then _super = vm.executable.defaultSuperFunc end

        -- Friendly check for implementation.
        if not self or type(ConstructorStruct) == 'function' then
            error(
                'Improper method call. (Not instanced) Use MyClass:addConstructor() instead of MyClass.addConstructor()',
                2
            );
        end

        local errHeader = string.format('ClassStruct(%s):addConstructor():', cd.name);

        if not ConstructorStruct then
            error(
                string.format(
                    '%s The constructor definition is not provided.',
                    errHeader
                ),
                2
            );
        end

        local parameters = vm.executable.compile(ConstructorStruct);

        local args = {

            __type__ = 'ConstructorStruct',

            audited = false,
            class = cd,
            scope = ConstructorStruct.scope or 'package',
            parameters = parameters,

            -- * Function properties * --
            body = body,
            bodyInfo = vm.executable.getExecutableInfo(body),
            super = _super,
            superInfo = vm.executable.getExecutableInfo(_super),
        };

        args.signature = vm.executable.createSignature(args);

        --- @cast args ConstructorStruct

        --- Validate function.
        if not args.body then
            error(string.format('%s function not provided.', errHeader), 2);
        elseif type(args.body) ~= 'function' then
            error(
                string.format(
                    '%s property "func" provided is not a function. {type = %s, value = %s}',
                    errHeader,
                    vm.type.getType(args.body),
                    tostring(args.body)
                ), 2);
        end

        if vm.debug.constructor then
            debugf(vm.debug.constructor, '[CONSTRUCTOR] :: %s Adding class constructor: %s.%s', self.printHeader,
                self.name,
                args.signature);
        end

        table.insert(self.declaredConstructors, args);

        return args;
    end

    --- @param args any[]
    ---
    --- @return ConstructorStruct|nil ConstructorStruct
    function cd:getConstructor(args)
        local cons = self:getDeclaredConstructor(args);
        if not cons and self.super then
            cons = self.super:getConstructor(args);
        end
        return cons;
    end

    --- @param args any[]
    ---
    --- @return ConstructorStruct|nil ConstructorStruct
    function cd:getDeclaredConstructor(args)
        args = args or vm.constants.EMPTY_TABLE;
        return vm.executable.resolveConstructor(self.declaredConstructors, args);
    end

    -- MARK: - Method

    function cd:addStaticMethod(MethodStruct)
        local errHeader = string.format('ClassStruct(%s):addMethod():', cd.name);

        local body = MethodStruct.body;
        local bodyInfo = vm.executable.getExecutableInfo(body);

        local scope = vm.audit.auditStructPropertyScope(self.scope, MethodStruct.scope, errHeader);
        local name = vm.audit.auditMethodParamName(MethodStruct.name, errHeader);
        local types = vm.audit.auditMethodReturnsProperty(MethodStruct.returnTypes, errHeader);
        local parameters = vm.audit.auditParameters(MethodStruct.parameters, errHeader);

        local md = {

            __type__ = 'MethodStruct',

            -- Base properties. --
            class = cd,
            name = name,
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

            -- Always falsify interface flags in class method definitions. --
            interface = false,
            default = false,
        };

        md.signature = vm.executable.createSignature(md);

        --- @cast md MethodStruct

        if vm.debug.method then
            local callSyntax = ':';
            if md.static then callSyntax = '.' end
            debugf(vm.debug.method, '[METHOD] :: %s Adding static method: %s%s%s',
                self.printHeader,
                self.name, callSyntax, md.signature
            );
        end

        -- Add the definition to the cluster array for the method's name.
        local methodCluster = self.declaredMethods[md.name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[md.name] = methodCluster;
        end
        methodCluster[md.signature] = md;

        return md;
    end

    function cd:addAbstractMethod(MethodStruct)
        local errHeader = string.format('ClassStruct(%s):addAbstractMethod():', cd.name);

        local bodyInfo = vm.executable.getExecutableInfo();

        local scope = vm.audit.auditStructPropertyScope(self.scope, MethodStruct.scope, errHeader);
        local name = vm.audit.auditMethodParamName(MethodStruct.name, errHeader);
        local types = vm.audit.auditMethodReturnsProperty(MethodStruct.returnTypes, errHeader);
        local parameters = vm.audit.auditParameters(MethodStruct.parameters, errHeader);

        local md = {
            __type__ = 'MethodStruct',

            -- Base properties. --
            class = cd,
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

            -- Always falsify interface flags in class method definitions. --
            interface = false,
            default = false,
        };

        md.signature = vm.executable.createSignature(md);

        --- @cast md MethodStruct

        if vm.debug.method then
            local callSyntax = ':';
            if md.static then callSyntax = '.' end
            debugf(vm.debug.method, '[METHOD] :: %s Adding abstract method: %s%s%s',
                self.printHeader,
                self.name, callSyntax, md.signature
            );
        end

        -- Add the definition to the cluster array for the method's name.
        local methodCluster = self.declaredMethods[md.name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[md.name] = methodCluster;
        end
        methodCluster[md.signature] = md;

        return md;
    end

    function cd:addMethod(MethodStruct)
        local body = MethodStruct.body;
        local bodyInfo = vm.executable.getExecutableInfo(body);
        local errHeader = string.format('ClassStruct(%s):addMethod():', cd.name);
        local scope = vm.audit.auditStructPropertyScope(self.scope, MethodStruct.scope, errHeader);
        local name = vm.audit.auditMethodParamName(MethodStruct.name, errHeader);
        local types = vm.audit.auditMethodReturnsProperty(MethodStruct.returnTypes, errHeader);
        local parameters = vm.audit.auditParameters(MethodStruct.parameters, errHeader);

        local md = {

            __type__ = 'MethodStruct',

            -- Base properties. --
            class = cd,
            name = name,
            returnTypes = types,
            parameters = parameters,
            body = body,
            bodyInfo = bodyInfo,
            scope = scope,

            -- General method flags --
            static = false,
            final = MethodStruct.final or false,
            abstract = false,

            -- Compiled method flags --
            audited = false,
            override = false,
            super = nil,

            -- Always falsify interface flags in class method definitions. --
            interface = false,
            default = false,
        };

        md.signature = vm.executable.createSignature(md);

        --- @cast md MethodStruct

        if vm.debug.method then
            local callSyntax = ':';
            if md.static then callSyntax = '.' end
            debugf(vm.debug.method, '[METHOD] :: %s Adding instance method: %s%s%s',
                self.printHeader,
                self.name, callSyntax, md.signature
            );
        end

        -- Add the definition to the cluster array for the method's name.
        local methodCluster = self.declaredMethods[md.name];
        if not methodCluster then
            methodCluster = {};
            self.declaredMethods[md.name] = methodCluster;
        end
        methodCluster[md.signature] = md;

        return md;
    end

    --- Attempts to resolve a MethodStruct in the ClassStruct. If the method isn't defined in the class,
    --- `nil` is returned.
    ---
    --- @param name string
    ---
    --- @return MethodStruct[]? methods
    function cd:getDeclaredMethods(name)
        return cd.declaredMethods[name];
    end

    --- @param name string
    --- @param args any[]
    ---
    --- @return MethodStruct|nil MethodStruct
    function cd:getMethod(name, args)
        return vm.executable.resolveMethod(self, name, self.methods[name], args);
    end

    --- @param name string
    --- @param args any[]
    ---
    --- @return MethodStruct|nil MethodStruct
    function cd:getDeclaredMethod(name, args)
        return vm.executable.resolveMethod(self, name, self.declaredMethods[name], args);
    end

    -- MARK: - finalize()

    --- @return ClassStruct class
    function cd:finalize()
        local errHeader = string.format('Class(%s):finalize():', cd.path);

        if self.__readonly__ then
            errorf(2, '%s Cannot finalize. (Class is already finalized!)', errHeader);
        end

        -- Finalize superclass.
        if cd.super and not cd.super.__readonly__ then
            cd.super:finalize();
        end

        -- Finalize any interface(s).
        for i = 1, #cd.interfaces do
            if not cd.interfaces[i] then
                cd.interfaces[i]:finalize();
            end
        end

        -- If any auto-methods are defined for fields (get, set), create them before compiling class methods.
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
        self.addMethod = function() errorf(2, '%s Cannot add methods. (Class is final!)', errHeader) end
        self.addField = function() errorf(2, '%s Cannot add fields. (Class is final!)', errHeader) end
        self.addConstructor = function() errorf(2, '%s Cannot add constructors. (Class is final!)', errHeader) end

        -- Set default value(s) for classes.
        for iname, icd in pairs(cd.inner) do
            if icd.static then
                cd[name] = icd;
            end
        end

        -- Set default value(s) for static fields.
        for name, fd in pairs(cd.declaredFields) do
            if fd.static then
                cd[name] = fd.value;
            end
        end

        self.__supertable__ = vm.super.createSuperTable(cd);
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
        vm.DEFINITIONS[cd.path] = cd;

        -- Set class as child.
        if cd.super then
            table.insert(cd.super.sub, cd);
        end

        -- Add a reference for global package and static code.
        if outer then
            vm.stepIn();
            outer[cd.name] = cd;
            vm.stepOut();
        end

        return cd;
    end

    function cd:isSuperClass(class)
        --- @type Hierarchical|nil
        local next = self.super;
        while next do
            if next == class then return true end
            next = next.super;
        end
        return false;
    end

    --- (Handles recursively going through sub-classes to see if a class is a sub-class)
    ---
    --- @param subClass ClassStruct
    --- @param classToEval ClassStruct
    ---
    --- @return boolean result True if the class to evaluate is a super-class of the subClass.
    local function __recurseSubClass(subClass, classToEval)
        local subLen = #cd.sub;
        for i = 1, subLen do
            local next = cd.sub[i];
            if next:isAssignableFromType(classToEval) or __recurseSubClass(next, classToEval) then
                return true;
            end
        end
        return false;
    end

    function cd:isSubClass(class)
        if __recurseSubClass(cd, class) then
            return true;
        end
        return false;
    end

    --- @param superInterface InterfaceStruct
    ---
    --- @return boolean
    function cd:isSuperInterface(superInterface)
        for i = 1, #self.interfaces do
            local interface = self.interfaces[i];
            if superInterface == interface then
                return true;
            end
        end

        if cd.super then
            return cd.super:isSuperInterface(superInterface);
        end

        return false;
    end

    function cd:isAssignableFromType(superStruct)
        -- Enum super-structs fail on assignable check.
        if not superStruct or
            superStruct.__type__ == 'EnumStructDefinition' then
            return false;
        end

        if superStruct.__type__ == 'ClassStruct' then
            return self == superStruct or self:isSuperClass(superStruct);
        elseif superStruct.__type__ == 'InterfaceStruct' then
            return self:isSuperInterface(superStruct);
        end

        return false;
    end

    function cd:isFinalized()
        return self.__readonly__;
    end

    return cd;
end

return API;
