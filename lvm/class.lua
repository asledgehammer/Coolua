---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local DebugUtils = require 'DebugUtils';

local LVMUtils = require 'LVMUtils';
-- local anyToString = LVMUtils.anyToString;
local arrayContainsDuplicates = LVMUtils.arrayContainsDuplicates;
local arrayToString = LVMUtils.arrayToString;
local debugf = LVMUtils.debugf;
local errorf = LVMUtils.errorf;
local isArray = LVMUtils.isArray;
local isValidName = LVMUtils.isValidName;
local firstCharToUpper = LVMUtils.firstCharToUpper;

--- @type LVM
local LVM;

local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm)
        LVM = lvm;
        LVM.moduleCount = LVM.moduleCount + 1;
    end
};

--- @cast API LVMClassModule

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

--- @param definition ClassStructDefinitionParameter|ChildClassStructDefinitionParameter
--- @param outer StructDefinition?
function API.newClass(definition, outer)
    local locInfo = LVM.struct.calcPathNamePackage(definition, outer);
    local path = locInfo.path;
    local name = locInfo.name;
    local pkg = locInfo.pkg;

    -- Make sure the class cannot be both final and abstract at the same time.
    if definition.final and definition.abstract then
        errorf(2, 'Class cannot be abstract AND final: %s', path);
        return;
    end

    local super = definition.extends;
    if super and super.final then
        errorf(2, 'Class cannot extend final Super-Class: %s extends final %s',
            path, super.path
        );
        return;
    end

    -- Prepare & validate interfaces array.
    --- @type InterfaceStructDefinition[]
    local interfaces = {};
    if definition.implements then
        if type(definition.implements) == 'table' then
            if definition.implements.__type__ == 'InterfaceStructDefinition' then
                table.insert(interfaces, definition.implements);
            else
                if not isArray(definition.implements) then
                    error('Not interface array', 2);
                end

                for i = 1, #definition.implements do
                    local interface = definition.implements[i];
                    if interface.__type__ ~= 'InterfaceStructDefinition' then
                        errorf(2, '%s Implements argument #%i is not a Interface.');
                    end
                    table.insert(interfaces, interface);
                end
            end
        end
    end

    local cd = {

        __type__ = 'ClassStructDefinition',

        -- * Struct Properties * --
        pkg = pkg,
        path = path,
        name = name,

        static = definition.static or false,
        final = definition.final or false,

        -- * Scopable Properties * --
        scope = definition.scope or 'package',

        -- * Hierarchical Properties * --
        super = super,
        sub = {},

        -- * Enclosurable Properties * --
        outer = outer,
        inner = {},
        isChild = outer ~= nil,

        -- * Class-Specific Properties * --
        abstract = definition.abstract or false,
        interfaces = interfaces,

        -- * Method Properties * --
        methods = {},
        methodCache = {},
    };

    -- Make sure that no class is made twice.
    if LVM.forNameDef(cd.path) then
        errorf(2, 'Struct is already defined: %s', cd.path);
        return cd; -- NOTE: Useless return. Makes sure the method doesn't say it'll define something as nil.
    end

    LVM.DEFINITIONS[cd.path] = cd;

    cd.type = cd.path;
    cd.printHeader = string.format('class (%s):', cd.path);
    cd.declaredFields = {};
    cd.declaredMethods = {};
    cd.declaredConstructors = {};
    cd.lock = false;

    -- Compile the generic parameters for the class.
    cd.generics = LVM.generic.compileGenericTypesDefinition(cd, definition.generics);

    cd.__middleConstructor = LVM.executable.createMiddleConstructor(cd);

    if not cd.super and cd.path ~= 'lua.lang.Object' then
        cd.super = LVM.forNameDef('lua.lang.Object');
        if not cd.super then
            errorf(2, '%s lua.lang.Object not defined!', cd.printHeader);
        end
    end

    --- @cast cd ClassStructDefinition

    if outer then
        outer.inner[cd.name] = cd;
    end

    -- MARK: - new()

    function cd.new(...)
        local errHeader = string.format('Class(%s):new():', cd.name);

        if not cd.lock then
            errorf(2, '%s Cannot invoke constructor. (ClassStructDefinition is not finalized!)', errHeader);
        end

        -- TODO: Check if package-class exists.

        local __class__;
        if cd.path ~= 'lua.lang.Class' then -- Prevent infinite loops.
            __class__ = LVM.forName(path);
        else
            __class__ = createPseudoClassInstance(cd);
        end

        local o = {
            __type__ = 'ClassInstance',
            __class__ = __class__,
        };

        --- Assign the middle-functions to the object.
        for name, func in pairs(cd.__middleMethods) do
            --- @diagnostic disable-next-line
            o[name] = func;
        end

        o.getClass = function(self)
            if not self.__class__ then
                LVM.stepIn();
                self.__class__ = LVM.forName(cd.path);
                LVM.stepOut();
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

        LVM.meta.createInstanceMetatable(cd, o);

        -- Invoke constructor context.
        local args = { ... };
        local result, errMsg = xpcall(function()
            cd.__middleConstructor(o, unpack(args));
        end, debug.traceback);

        if not result then error(errMsg, 2) end

        return o;
    end

    -- MARK: - Field

    --- @param fd FieldDefinitionParameter
    ---
    --- @return FieldDefinition
    function cd:addField(fd)
        -- Friendly check for implementation.
        if not self or not fd then
            error(
                'Improper method call. (Not instanced) Use MyClass:addField() instead of MyClass.addField()',
                2
            );
        end

        --- @type FieldDefinition
        local args = {
            __type__ = 'FieldDefinition',
            audited = false,
            class = cd,
            types = fd.types,
            type = fd.type,
            name = fd.name,
            scope = fd.scope or 'package',
            static = fd.static or false,
            final = fd.final or false,
            value = fd.value or LVM.constants.UNINITIALIZED_VALUE,
            get = fd.get,
            set = fd.set,
            assignedOnce = false,
        };

        local errHeader = string.format('Class(%s):addField():', cd.name);

        -- Validate name.
        if not args.name then
            errorf(2, '%s string property "name" is not provided.', errHeader);
        elseif type(args.name) ~= 'string' then
            errorf(2, '%s property "name" is not a valid string. {type=%s, value=%s}',
                errHeader, type(args.name), tostring(args.name)
            );
        elseif args.name == '' then
            errorf(2, '%s property "name" is an empty string.', errHeader);
        elseif not isValidName(args.name) then
            errorf(2,
                '%s property "name" is invalid. (value = %s) (Should only contain A-Z, a-z, 0-9, _, or $ characters)',
                errHeader, args.name
            );
        elseif self.declaredFields[args.name] then
            errorf(2, '%s field already exists: %s', errHeader, args.name);
        end

        -- Validate types:
        if not args.types and not args.type then
            errorf(2, '%s array property "types" or simplified string property "type" are not provided.', errHeader);
        elseif args.types then
            if type(args.types) ~= 'table' or not isArray(args.types) then
                errorf(2, 'types is not an array. {type=%s, value=%s}',
                    errHeader, type(args.types), tostring(args.types)
                );
            elseif #args.types == 0 then
                errorf(2, '%s types is empty. (min=1)', errHeader);
            elseif arrayContainsDuplicates(args.types) then
                errorf(2, '%s types contains duplicate types.', errHeader);
            end

            for i = 1, #args.types do
                local tType = type(args.types[i]);
                if tType == 'table' then
                    if not args.type['__type__'] then
                        errorf(2, '%s types[%i] is a table without a "string __type__" property.', errHeader, i);
                    elseif type(args.type['__type__']) ~= 'string' then
                        errorf(2, '%s types[%i].__type__ is not a string.');
                    end
                    args.types[i] = type['__type__'];
                elseif tType == 'string' then
                    if args.types[i] == '' then
                        errorf(2, '%s types[%i] is an empty string.', errHeader, i);
                    end
                else
                    errorf(2, '%s: types[%i] is not a string or { __type__: string }. {type=%s, value=%s}',
                        errHeader, i, type(args.type), tostring(args.type)
                    );
                end
            end
        else
            local tType = type(args.type);
            if tType == 'table' then
                if not args.type['__type__'] then
                    errorf(2, '%s property "type" is a table without a "string __type__" property.', errHeader);
                elseif type(args.type['__type__']) ~= 'string' then
                    errorf(2, '%s type.__type__ is not a string.');
                end
                args.type = args.type['__type__'];
            elseif tType == 'string' then
                if args.type == '' then
                    errorf(2, '%s property "type" is an empty string.', errHeader);
                end
            else
                errorf(2, '%s: property "type" is not a string. {type=%s, value=%s}',
                    errHeader, type(args.type), tostring(args.type)
                );
            end

            -- Set the types array and remove the simplified form.
            args.types = { args.type };
            args.type = nil;
        end

        -- Validate value:
        if args.value ~= LVM.constants.UNINITIALIZED_VALUE then
            if not LVM.type.isAssignableFromType(args.value, args.types) then
                errorf(2,
                    '%s property "value" is not assignable from "types". {types = %s, value = {type = %s, value = %s}}',
                    errHeader, arrayToString(args.types), type(args.value), tostring(args.value)
                );
            end
            args.assignedOnce = true;
        else
            args.assignedOnce = false;
        end

        -- Validate scope:
        if args.scope ~= 'private' and args.scope ~= 'protected' and args.scope ~= 'package' and args.scope ~= 'public' then
            errorf(2,
                '%s The property "scope" given invalid: %s (Can only be: "private", "protected", "package", or "public")',
                errHeader, args.scope
            );
        end

        -- Validate final:
        if type(args.final) ~= 'boolean' then
            errorf(2, '%s property "final" is not a boolean. {type = %s, value = %s}',
                errHeader, LVM.type.getType(args.final), tostring(args.final)
            );
        end

        -- Validate static:
        if type(args.static) ~= 'boolean' then
            errorf(2, '%s property "static" is not a boolean. {type = %s, value = %s}',
                errHeader, LVM.type.getType(args.static), tostring(args.static)
            );
        end

        local funcName = firstCharToUpper(args.name);

        -- -- Validate get:
        -- local tGet = type(args.get);
        -- if tGet ~= 'nil' then
        --     local mGetDef = {
        --         name = 'get' .. funcName,
        --         scope = args.scope, -- NOTE: We can only assume the same scope without further info.
        --         returns = args.types,
        --         body = function(ins)
        --             return ins[args.name];
        --         end
        --     };
        --
        --     if tGet == 'boolean' then
        --
        --     elseif tGet == 'table' then
        --         --- @type FieldGetDefinition
        --         local getDef = args.get;
        --
        --         if mGetDef.scope then
        --             mGetDef.scope = getDef.scope;
        --         end
        --
        --         if mGetDef.body then
        --             mGetDef.body = getDef.body;
        --         end
        --     end
        --
        --     cd:addMethod(mGetDef);
        -- end

        self.declaredFields[args.name] = args;

        return args;
    end

    --- Attempts to resolve a FieldDefinition in the ClassStructDefinition. If the field isn't declared for the class
    --- level, the super-class(es) are checked.
    ---
    --- @param name string
    ---
    --- @return FieldDefinition? fieldDefinition
    function cd:getField(name)
        local fd = cd:getDeclaredField(name);
        if not fd and cd.super then
            return cd.super:getField(name);
        end
        return fd;
    end

    --- Attempts to resolve a FieldDefinition in the ClassStructDefinition. If the field isn't defined in the class, nil
    --- is returned.
    ---
    --- @param name string
    ---
    --- @return FieldDefinition? fieldDefinition
    function cd:getDeclaredField(name)
        return cd.declaredFields[name];
    end

    function cd:getFields()
        --- @type FieldDefinition[]
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

    --- @param constructorDefinition ConstructorDefinitionParameter
    ---
    --- @return ConstructorDefinition
    function cd:addConstructor(constructorDefinition)
        -- Some constructors are empty. Allow this to be optional.
        local body = constructorDefinition.body;
        if not body then body = function() end end

        -- If the super-call is not there, then write
        local _super = constructorDefinition.super;
        if not _super then _super = LVM.executable.defaultSuperFunc end

        -- Friendly check for implementation.
        if not self or type(constructorDefinition) == 'function' then
            error(
                'Improper method call. (Not instanced) Use MyClass:addConstructor() instead of MyClass.addConstructor()',
                2
            );
        end

        local errHeader = string.format('ClassStructDefinition(%s):addConstructor():', cd.name);

        if not constructorDefinition then
            error(
                string.format(
                    '%s The constructor definition is not provided.',
                    errHeader
                ),
                2
            );
        end

        local parameters = LVM.executable.compile(constructorDefinition.parameters);

        local args = {

            __type__ = 'ConstructorDefinition',

            audited = false,
            class = cd,
            scope = constructorDefinition.scope or 'package',
            parameters = parameters,

            -- * Function properties * --
            body = body,
            bodyInfo = LVM.executable.getExecutableInfo(body),
            super = _super,
            superInfo = LVM.executable.getExecutableInfo(_super),
        };

        args.signature = LVM.executable.createSignature(args);

        --- @cast args ConstructorDefinition

        --- Validate function.
        if not args.body then
            error(string.format('%s function not provided.', errHeader), 2);
        elseif type(args.body) ~= 'function' then
            error(
                string.format(
                    '%s property "func" provided is not a function. {type = %s, value = %s}',
                    errHeader,
                    LVM.type.getType(args.body),
                    tostring(args.body)
                ), 2);
        end

        if LVM.debug.constructor then
            debugf(LVM.debug.constructor, '%s Adding class constructor: %s.%s', self.printHeader, self.name,
                args.signature);
        end

        table.insert(self.declaredConstructors, args);

        return args;
    end

    --- @param args any[]
    ---
    --- @return ConstructorDefinition|nil constructorDefinition
    function cd:getConstructor(args)
        local cons = self:getDeclaredConstructor(args);
        if not cons and self.super then
            cons = self.super:getConstructor(args);
        end
        return cons;
    end

    --- @param args any[]
    ---
    --- @return ConstructorDefinition|nil constructorDefinition
    function cd:getDeclaredConstructor(args)
        args = args or LVM.constants.EMPTY_TABLE;
        return LVM.executable.resolveConstructor(self.declaredConstructors, args);
    end

    -- MARK: - Method

    function cd:addStaticMethod(methodDefinition)
        local errHeader = string.format('ClassStructDefinition(%s):addMethod():', cd.name);

        local body = methodDefinition.body;
        local bodyInfo = LVM.executable.getExecutableInfo(body);

        local scope = LVM.audit.auditStructPropertyScope(self.scope, methodDefinition.scope, errHeader);
        local name = LVM.audit.auditMethodParamName(methodDefinition.name, errHeader);
        local types = LVM.audit.auditMethodReturnsProperty(methodDefinition.returns, errHeader);
        local parameters = LVM.audit.auditParameters(methodDefinition.parameters, errHeader);

        local md = {

            __type__ = 'MethodDefinition',

            -- Base properties. --
            class = cd,
            name = name,
            returns = types,
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

        md.signature = LVM.executable.createSignature(md);

        --- @cast md MethodDefinition

        if LVM.debug.method then
            local callSyntax = ':';
            if md.static then callSyntax = '.' end
            debugf(LVM.debug.method, '%s Adding static method: %s%s%s',
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

    function cd:addAbstractMethod(methodDefinition)
        local errHeader = string.format('ClassStructDefinition(%s):addAbstractMethod():', cd.name);

        local bodyInfo = LVM.executable.getExecutableInfo();

        local scope = LVM.audit.auditStructPropertyScope(self.scope, methodDefinition.scope, errHeader);
        local name = LVM.audit.auditMethodParamName(methodDefinition.name, errHeader);
        local types = LVM.audit.auditMethodReturnsProperty(methodDefinition.returns, errHeader);
        local parameters = LVM.audit.auditParameters(methodDefinition.parameters, errHeader);

        local md = {
            __type__ = 'MethodDefinition',

            -- Base properties. --
            class = cd,
            name = name,
            returns = types,
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

        md.signature = LVM.executable.createSignature(md);

        --- @cast md MethodDefinition

        if LVM.debug.method then
            local callSyntax = ':';
            if md.static then callSyntax = '.' end
            debugf(LVM.debug.method, '%s Adding abstract method: %s%s%s',
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

    function cd:addMethod(methodDefinition)
        local body = methodDefinition.body;
        local bodyInfo = LVM.executable.getExecutableInfo(body);
        local errHeader = string.format('ClassStructDefinition(%s):addMethod():', cd.name);
        local scope = LVM.audit.auditStructPropertyScope(self.scope, methodDefinition.scope, errHeader);
        local name = LVM.audit.auditMethodParamName(methodDefinition.name, errHeader);
        local types = LVM.audit.auditMethodReturnsProperty(methodDefinition.returns, errHeader);
        local parameters = LVM.audit.auditParameters(methodDefinition.parameters, errHeader);

        local md = {

            __type__ = 'MethodDefinition',

            -- Base properties. --
            class = cd,
            name = name,
            returns = types,
            parameters = parameters,
            body = body,
            bodyInfo = bodyInfo,
            scope = scope,

            -- General method flags --
            static = false,
            final = methodDefinition.final or false,
            abstract = false,

            -- Compiled method flags --
            audited = false,
            override = false,
            super = nil,

            -- Always falsify interface flags in class method definitions. --
            interface = false,
            default = false,
        };

        md.signature = LVM.executable.createSignature(md);

        --- @cast md MethodDefinition

        if LVM.debug.method then
            local callSyntax = ':';
            if md.static then callSyntax = '.' end
            debugf(LVM.debug.method, '%s Adding instance method: %s%s%s',
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

    --- Attempts to resolve a MethodDefinition in the ClassStructDefinition. If the method isn't defined in the class,
    --- `nil` is returned.
    ---
    --- @param name string
    ---
    --- @return MethodDefinition[]? methods
    function cd:getDeclaredMethods(name)
        return cd.declaredMethods[name];
    end

    --- @param name string
    --- @param args any[]
    ---
    --- @return MethodDefinition|nil methodDefinition
    function cd:getMethod(name, args)
        return LVM.executable.resolveMethod(self, name, self.methods[name], args);
    end

    --- @param name string
    --- @param args any[]
    ---
    --- @return MethodDefinition|nil methodDefinition
    function cd:getDeclaredMethod(name, args)
        return LVM.executable.resolveMethod(self, name, self.declaredMethods[name], args);
    end

    -- MARK: - finalize()

    --- @return ClassStructDefinition class
    function cd:finalize()
        local errHeader = string.format('Class(%s):finalize():', cd.path);

        if self.lock then
            errorf(2, '%s Cannot finalize. (Class is already finalized!)', errHeader);
        elseif cd.super and (cd.super.__type__ == 'ClassStructDefinition' and not cd.super.lock) then
            errorf(2, '%s Cannot finalize. (Super-Class %s is not finalized!)', errHeader, path);
        end

        -- If any auto-methods are defined for fields (get, set), create them before compiling class methods.
        LVM.field.compileFieldAutoMethods(self);

        -- TODO: Audit everything.

        --- @type table<string, MethodDefinition[]>
        LVM.executable.compileMethods(self);

        -- Change add methods.
        self.addMethod = function() errorf(2, '%s Cannot add methods. (Class is final!)', errHeader) end
        self.addField = function() errorf(2, '%s Cannot add fields. (Class is final!)', errHeader) end
        self.addConstructor = function() errorf(2, '%s Cannot add constructors. (Class is final!)', errHeader) end

        -- Set default value(s) for static fields.
        for name, fd in pairs(cd.declaredFields) do
            if fd.static then
                cd[name] = fd.value;
            end
        end

        self.__supertable__ = LVM.super.createSuperTable(cd);

        -- - @type table<ParameterDefinition[], function>
        -- self.__constructors = {};

        -- Set all definitions as read-only.
        -- local constructorsLen = #self.declaredConstructors;
        -- if constructorsLen ~= 0 then
        --     for i = 1, constructorsLen do
        --         --- @type ConstructorDefinition
        --         local constructor = self.declaredConstructors[i];
        --         self.__constructors[constructor.parameters] = constructor.func;
        --         -- Set read-only.
        --         self.declaredConstructors[i] = readonly(constructor);
        --     end
        -- end

        self.__middleMethods = {};

        -- Insert boilerplate method invoker function.
        for mName, methodCluster in pairs(self.methods) do
            for _, md in pairs(methodCluster) do
                if md.override then
                    -- RULE: Cannot override method if super-method is final.
                    if md.super.final then
                        local sMethod = LVM.print.printMethod(md);
                        errorf(2, '%s Method cannot override final method in super-class: %s',
                            errHeader,
                            md.super.class.name,
                            sMethod
                        );
                        return cd;
                        -- RULE: Cannot reduce scope of overrided super-method.
                    elseif not LVM.scope.canAccessScope(md.scope, md.super.scope) then
                        local sMethod = LVM.print.printMethod(md);
                        errorf(2, '%s Method cannot reduce scope of super-class: %s (super-scope = %s, class-scope = %s)',
                            errHeader,
                            sMethod, md.super.scope, md.scope
                        );
                        return cd;
                        -- RULE: override Methods must either be consistently static (or not) with their super-method(s).
                    elseif md.static ~= md.super.static then
                        local sMethod = LVM.print.printMethod(md);
                        errorf(2,
                            '%s All method(s) with identical signatures must either be static or not: %s (super.static = %s, class.static = %s)',
                            errHeader,
                            sMethod, tostring(md.super.static), tostring(md.static)
                        );
                        return cd;
                    end
                end
            end
            self.__middleMethods[mName] = LVM.executable.createMiddleMethod(cd, mName, methodCluster);
        end

        local mt = getmetatable(cd) or {};
        local __properties = {};
        for k, v in pairs(cd) do __properties[k] = v end
        mt.__metatable = false;
        mt.__index = __properties;
        mt.__tostring = function() return LVM.print.printClass(cd) end

        mt.__index = __properties;

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
            if LVM.isInside() then
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
            if cd.sub[field] then
                if LVM.isOutside() then
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

            local level, relPath = LVM.scope.getRelativePath();

            LVM.stack.pushContext({
                class = cd,
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
                    cd.name, fd.name,
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
                    cd.printHeader, field, LVM.stack.printStackTrace()
                );
                LVM.stack.popContext();
                error(errMsg, 2);
                return;
            end

            if fd.final then
                local ste = LVM.stack.getContext();
                if not ste then
                    errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                    return;
                end

                local context = ste:getContext();
                local class = ste:getCallingClass();
                if class ~= cd then
                    errorf(2, '%s Attempt to assign final field %s outside of Class scope.', cd.printHeader, field);
                elseif context ~= 'constructor' then
                    errorf(2, '%s Attempt to assign final field %s outside of constructor scope.', cd.printHeader, field);
                elseif fd.assignedOnce then
                    errorf(2, '%s Attempt to assign final field %s. (Already defined)', cd.printHeader, field);
                end
            end

            -- Set the value.
            __properties[field] = value;

            -- Apply forward the value metrics.
            fd.assignedOnce = true;
            fd.value = value;
        end

        setmetatable(cd, mt);

        self.lock = true;
        LVM.DEFINITIONS[cd.path] = cd;

        -- Set class as child.
        if cd.super then
            table.insert(cd.super.sub, cd);
        end

        --- Set the class to be accessable from a global package reference.
        LVM.flags.allowPackageStructModifications = true;
        LVM.package.addToPackageStruct(cd);
        LVM.flags.allowPackageStructModifications = false;

        -- Add a reference for global package and static code.
        if outer then
            LVM.stepIn();
            outer[cd.name] = cd;
            LVM.stepOut();
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
    --- @param subClass ClassStructDefinition
    --- @param classToEval ClassStructDefinition
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

    --- @param superInterface InterfaceStructDefinition
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

        if superStruct.__type__ == 'ClassStructDefinition' then
            return self == superStruct or self:isSuperClass(superStruct);
        elseif superStruct.__type__ == 'InterfaceStructDefinition' then
            return self:isSuperInterface(superStruct);
        end

        return false;
    end

    return cd;
end

return API;
