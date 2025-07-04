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
local readonly = LVMUtils.readonly;

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

    cd.__middleConstructor = LVM.constructor.createMiddleConstructor(cd);

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
            __type__ = cd.type,
            __class__ = __class__,
        };

        --- Assign the middle-functions to the object.
        for name, func in pairs(cd.__middleMethods) do
            o[name] = func;
        end

        LVM.flags.canSetSuper = true;
        o.__super__ = LVM.super.createSuperTable(cd, o);
        LVM.flags.canSetSuper = false;

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
                -- TODO: Make unique.
                o[fd.name] = fd.value;
                -- print(string.format('Field: o[%s] = %s', fd.name, tostring(fd.value)));
            end
        end

        local middleMethods = cd.__middleMethods;
        for name, func in pairs(middleMethods) do
            o[name] = func;
            -- print(string.format('Method: o[%s] = %s', name, tostring(func)));
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

        -- Validate get:
        local tGet = type(args.get);
        if tGet ~= 'nil' then
            local mGetDef = {
                name = 'get' .. funcName,
                scope = args.scope, -- NOTE: We can only assume the same scope without further info.
                returns = args.types
            };

            if tGet == 'boolean' then

            elseif tGet == 'table' then
                --- @type FieldGetDefinition
                local getDef = args.get;

                if mGetDef.scope then
                    mGetDef.scope = getDef.scope;
                end
            end

            cd:addMethod(mGetDef,
                function(ins)
                    return ins[args.name];
                end
            );
        end

        self.declaredFields[args.name] = args;

        return args;
    end

    function cd:compileFieldAutoMethods()
        for name, fieldDef in pairs(cd.declaredFields) do
            local funcName = firstCharToUpper(fieldDef.name);
            local tGet = type(fieldDef.get);
            local tSet = type(fieldDef.set);

            --- @type function
            local fGet;
            --- @type function
            local fSet;

            if tGet ~= 'nil' then
                local mGetDef = {
                    name = 'get' .. funcName,
                    scope = fieldDef.scope,
                    returns = fieldDef.types
                };

                if tGet == 'boolean' then

                elseif tGet == 'table' then
                    if fieldDef.get.scope then
                        mGetDef.scope = fieldDef.get.scope;
                    end
                    if fieldDef.get.func then
                        if type(fieldDef.get.func) ~= 'function' then
                            errorf(2,
                                '%s The getter method definition for field "%s" is not a function; {type = %s, value = %s}',
                                cd.printHeader,
                                name,
                                LVM.type.getType(fieldDef.get.func),
                                tostring(fieldDef.get.func)
                            );
                        end

                        fGet = fieldDef.get.func;
                    else
                        fGet = function(ins)
                            return ins[name];
                        end;
                    end
                end

                debugf(LVM.debug.method, '%s Creating auto-method: %s:%s()',
                    self.printHeader,
                    self.name, mGetDef.name
                );

                cd:addMethod(mGetDef, fGet);
            end

            if tSet ~= 'nil' then
                local mSetDef = {
                    name = 'set' .. funcName,
                    scope = fieldDef.scope,
                    parameters = {
                        { name = 'value', types = fieldDef.types }
                    }
                };

                if tSet == 'table' then
                    if fieldDef.set.scope then
                        mSetDef.scope = fieldDef.set.scope;
                    end
                    if fieldDef.set.func then
                        if type(fieldDef.get.func) ~= 'function' then
                            errorf(2,
                                '%s The setter method definition for field "%s" is not a function; {type = %s, value = %s}',
                                cd.printHeader,
                                name,
                                LVM.type.getType(fieldDef.get.func),
                                tostring(fieldDef.get.func)
                            );
                        end
                        fSet = fieldDef.set.func;
                    else
                        fSet = function(ins, value)
                            ins[name] = value;
                        end;
                    end
                end

                debugf(LVM.debug.method, '%s Creating auto-method: %s:%s',
                    self.printHeader,
                    self.name, mSetDef.signature
                );

                cd:addMethod(mSetDef, fSet);
            end
        end
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

    --- @return FieldDefinition[]
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
    --- @param func function?
    ---
    --- @return ConstructorDefinition
    function cd:addConstructor(constructorDefinition, func)
        -- Some constructors are empty. Allow this to be optional.
        if not func then func = function() end end

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

        local parameters = LVM.parameter.compile(constructorDefinition.parameters);

        local args = {

            __type__ = 'ConstructorDefinition',

            audited = false,
            class = cd,
            scope = constructorDefinition.scope or 'package',
            parameters = parameters,
            func = func
        };

        args.signature = LVM.constructor.createSignature(args);

        --- @cast args ConstructorDefinition

        --- Validate function.
        if not args.func then
            error(string.format('%s function not provided.', errHeader), 2);
        elseif type(args.func) ~= 'function' then
            error(
                string.format(
                    '%s property "func" provided is not a function. {type = %s, value = %s}',
                    errHeader,
                    LVM.type.getType(args.func),
                    tostring(args.func)
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
        return LVM.constructor.resolveConstructor(self.declaredConstructors, args);
    end

    --- @param line integer
    ---
    --- @return ConstructorDefinition|nil method
    function cd:getConstructorFromLine(line)
        --- @type ConstructorDefinition
        local cons;
        for i = 1, #self.declaredConstructors do
            cons = self.declaredConstructors[i];
            if line >= cons.lineRange.start and line <= cons.lineRange.stop then
                return cons;
            end
        end
        return nil;
    end

    -- MARK: - Method

    function cd:addMethod(methodDefinition, func)
        -- Friendly check for implementation.
        if not self or type(methodDefinition) == 'function' then
            error(
                'Improper method call. (Not instanced) Use MyClass:addMethod() instead of MyClass.addMethod()',
                2
            );
        end

        local errHeader = string.format('ClassStructDefinition(%s):addMethod():', cd.name);

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

        local parameters = LVM.parameter.compile(methodDefinition.parameters);

        -- Validate return type(s).
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
            if not cd.abstract then
                errorf(2, '%s The method cannot be abstract when the class is not: %s.%s',
                    errHeader, cd.name, methodDefinition.name
                );
                return;
            elseif func then
                errorf(2, '%s The method cannot be abstract and have a defined function block: %s.%s',
                    errHeader, cd.name, methodDefinition.name
                );
                return;
            end
        end

        -- TODO: Implement all definition property checks.
        local lineStart, lineStop = -1, -1;
        if func then
            lineStart, lineStop = DebugUtils.getFuncRange(func);
        end

        local md = {

            __type__ = 'MethodDefinition',

            -- Base properties. --
            class = cd,
            name = methodDefinition.name,
            returns = types,
            parameters = parameters,
            func = func,

            -- Used for scope-visibility analysis. --
            scope = methodDefinition.scope or 'package',
            lineRange = { start = lineStart, stop = lineStop },

            -- General method flags --
            static = methodDefinition.static or false,
            final = methodDefinition.final or false,
            abstract = methodDefinition.abstract or false,

            -- Compiled method flags --
            audited = false,
            override = false,
            super = nil,

            -- Always falsify interface flags in class method definitions. --
            interface = false,
            default = false,
        };

        md.signature = LVM.method.createSignature(md);

        --- @cast md MethodDefinition

        if LVM.debug.method then
            local callSyntax = ':';
            if md.static then callSyntax = '.' end
            debugf(LVM.debug.method, '%s Adding class method: %s%s%s',
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

    --- @param def ClassStructDefinition
    --- @param name string
    --- @param comb table<string, table<string, MethodDefinition>>?
    ---
    --- @return table<string, table<string, MethodDefinition>>
    local function combineAllMethods(def, name, comb)
        comb = comb or {};

        -- Grab all the super-context methods first.
        if def.super then
            combineAllMethods(def.super, name, comb);
        end

        -- Copy any interface method array.
        local interfaceLen = #def.interfaces;
        if interfaceLen ~= 0 then
            for i = 1, interfaceLen do
                local interface = def.interfaces[i];
                if interface.methods[name] then
                    local mCluster = interface.methods[name];
                    local defCluster = comb[name];
                    if not defCluster then
                        defCluster = {};
                        comb[name] = mCluster;
                    end
                    for mSignature, md in pairs(mCluster) do
                        -- Here we ignore re-applied interface methods since they're already applied.
                        if not defCluster[mSignature] then
                            debugf(LVM.debug.method, '%s IGNORING re-applied interface method in hierarchy: %s',
                                def.printHeader,
                                LVM.print.printMethod(md)
                            );
                        else
                            debugf(LVM.debug.method, '%s applying interface method in hierarchy: %s',
                                def.printHeader,
                                LVM.print.printMethod(md)
                            );
                            defCluster[mSignature] = md;
                        end
                    end
                end
            end
        end

        local combCluster = comb[name];
        if not combCluster then
            combCluster = {};
            comb[name] = combCluster;
        end

        local combCluster = comb[name];
        if not combCluster then
            combCluster = {};
            comb[name] = combCluster;
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

    function cd:compileMethods()
        debugf(LVM.debug.method, '%s Compiling method(s)..', self.printHeader);

        self.methods = {};

        local methodNames = LVM.method.getMethodNames(cd);
        for i = 1, #methodNames do
            local mName = methodNames[i];
            combineAllMethods(self, mName, self.methods);
        end

        local count = 0;

        -- Make sure that all methods exposed are not abstract in non-abstract classes.
        if not cd.abstract then
            for mName, methodCluster in pairs(self.methods) do
                for mSignature, method in pairs(methodCluster) do
                    if method.abstract then
                        local errMsg = string.format('%s Abstract method not implemented: %s',
                            cd.printHeader, LVM.print.printMethod(method)
                        );
                        print(errMsg);
                        error(errMsg, 3);
                    elseif (method.interface and not method.default) then
                        local errMsg = string.format('%s Interface method not implemented: %s',
                            cd.printHeader, LVM.print.printMethod(method)
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
        return LVM.method.resolveMethod(self, name, self.methods[name], args);
    end

    --- @param name string
    --- @param args any[]
    ---
    --- @return MethodDefinition|nil methodDefinition
    function cd:getDeclaredMethod(name, args)
        return LVM.method.resolveMethod(self, name, self.declaredMethods[name], args);
    end

    --- @param line integer
    ---
    --- @return MethodDefinition|nil method
    function cd:getMethodFromLine(line)
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
    function cd:finalize()
        local errHeader = string.format('Class(%s):finalize():', cd.path);

        if self.lock then
            errorf(2, '%s Cannot finalize. (Class is already finalized!)', errHeader);
        elseif cd.super and (cd.super.__type__ == 'ClassStructDefinition' and not cd.super.lock) then
            errorf(2, '%s Cannot finalize. (Super-Class %s is not finalized!)', errHeader, path);
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
        for name, fd in pairs(cd.declaredFields) do
            if fd.static then
                cd[name] = fd.value;
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
            self.__middleMethods[mName] = LVM.method.createMiddleMethod(cd, mName, methodCluster);
        end

        local mt = getmetatable(cd) or {};
        local __properties = {};
        for k, v in pairs(cd) do __properties[k] = v end
        mt.__metatable = false;
        mt.__index = __properties;
        mt.__tostring = function() return LVM.print.printClass(cd) end

        mt.__index = __properties;

        mt.__newindex = function(tbl, field, value)
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

                -- print('setting inner-class: ', field, tostring(value));
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

    --- @param line integer
    ---
    --- @return ConstructorDefinition|MethodDefinition|nil method
    function cd:getExecutableFromLine(line)
        return self:getMethodFromLine(line) or self:getConstructorFromLine(line) or nil;
    end

    --- @param class Hierarchical?
    ---
    --- @return boolean
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

    --- @param class ClassStructDefinition The class to evaulate.
    ---
    --- @return boolean result True if the class to evaluate is a super-class of the subClass.
    function cd:isSubClass(class)
        if __recurseSubClass(cd, class) then
            return true;
        end
        return false;
    end

    --- @param class ClassStructDefinition
    ---
    --- @return boolean
    function cd:isAssignableFromType(class)
        -- TODO: Implement interfaces.
        return self == class or self:isSuperClass(class);
    end

    return cd;
end

return API;
