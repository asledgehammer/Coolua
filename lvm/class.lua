---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local DebugUtils = require 'DebugUtils';

local LVMUtils = require 'LVMUtils';
local anyToString = LVMUtils.anyToString;
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

--- @type LVMClassModule
local API = {

    __type__ = 'LVMModule',

    --- @param lvm LVM
    setLVM = function(lvm) LVM = lvm end
};

--- @type table<string, Class>
---
--- Classes are stored as their path.
local CLASSES = {};

--- @type table<string, LVMClassDefinition>
---
--- Class Definitions are stored as their path.
local CLASS_DEFS = {};

--- @param path string
---
--- @return LVMClassDefinition|nil
function API.forNameDef(path)
    return CLASS_DEFS[path];
end

function API.forName(path)
    --- @type Class?
    local class = CLASSES[path];

    if not class then
        --- @type LVMClassDefinition
        local def = CLASS_DEFS[path];
        if def then

            LVM.stepIn();
            class = _G.lua.lang.Class.new(def);
            LVM.stepOut();

            CLASSES[path] = class;
        end
    end

    return class;
end

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

--- @param definition LVMClassDefinitionParameter|LVMChildClassDefinitionParameter
--- @param enclosingClass LVMClassDefinition?
function API.newClass(definition, enclosingClass)
    local path;
    local name;
    local package;

    if enclosingClass then
        path = enclosingClass.path .. '$' .. enclosingClass.name;

        package = definition.pkg or enclosingClass.package;

        if not definition.name then
            error('Name not defined for child class.', 2);
        end
        name = definition.name;
    else
        -- Generate the path to use.
        path = DebugUtils.getPath(3, LVM.ROOT_PATH, true);
        local split = path:split('.');
        name = table.remove(split, #split);
        package = table.join(split, '.');

        if definition.pkg then
            package = definition.pkg;
        end

        if definition.name then
            name = definition.name;
        end

        path = package .. '.' .. name;
    end


    local superClass = definition.superClass;
    if superClass and superClass.__type__ == 'lua.lang.Class' then
        --- @cast superClass Class<Object>
        superClass = superClass:getDefinition();
    end

    local cd = {
        __type__ = 'ClassDefinition',
        package = package,
        name = name,
        scope = definition.scope,
        superClass = superClass,
        subClasses = {},
        static = definition.static or false,
        isChild = enclosingClass ~= nil,
        enclosingClass = enclosingClass,
        children = {}
    };

    cd.path = path;

    -- Make sure that no class is made twice.
    if LVM.class.forName(cd.path) then
        errorf(2, 'Class is already defined: %s', cd.path);
        return cd; -- NOTE: Useless return. Makes sure the method doesn't say it'll define something as nil.
    end

    cd.type = 'class:' .. cd.path;
    cd.printHeader = string.format('Class(%s):', cd.path);
    cd.declaredFields = {};
    cd.declaredMethods = {};
    cd.declaredConstructors = {};
    cd.lock = false;

    -- Compile the generic parameters for the class.
    cd.generics = LVM.generic.compileGenericTypesDefinition(cd, definition.generics);

    cd.__middleConstructor = LVM.constructor.createMiddleConstructor(cd);

    if not cd.superClass and cd.path ~= 'lua.lang.Object' then
        cd.superClass = API.forNameDef('lua.lang.Object');
        if not cd.superClass then
            errorf(2, '%s lua.lang.Object not defined!', cd.printHeader);
        end
    end

    CLASS_DEFS[cd.path] = cd;

    if enclosingClass then
        enclosingClass.children[cd.name] = cd;
    end

    -- MARK: - new()

    function cd.new(...)
        local errHeader = string.format('Class(%s):new():', cd.name);

        if not cd.lock then
            errorf(2, '%s Cannot invoke constructor. (ClassDefinition is not finalized!)', errHeader);
        end

        -- TODO: Check if package-class exists.

        local __class__;
        if cd.path ~= 'lua.lang.Class' then -- Prevent infinite loops.
            __class__ = API.forName(path);
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
                self.__class__ = API.forName(cd.path);
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

                debugf(LVM.debug.method, 'Creating auto-method: ', cd.name .. '.' .. mGetDef.name);

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

                debugf(LVM.debug.method, 'Creating auto-method: ', cd.name .. '.' .. mSetDef.name);

                cd:addMethod(mSetDef, fSet);
            end
        end
    end

    --- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't declared for the class level, the
    --- super-class(es) are checked.
    ---
    --- @param name string
    ---
    --- @return FieldDefinition? fieldDefinition
    function cd:getField(name)
        local fd = cd:getDeclaredField(name);
        if not fd and cd.superClass then
            return cd.superClass:getField(name);
        end
        return fd;
    end

    --- Attempts to resolve a FieldDefinition in the ClassDefinition. If the field isn't defined in the class, nil
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
            next = next.superClass;
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

        local errHeader = string.format('ClassDefinition(%s):addConstructor():', cd.name);

        if not constructorDefinition then
            error(
                string.format(
                    '%s The constructor definition is not provided.',
                    errHeader
                ),
                2
            );
        end

        --- @type ConstructorDefinition
        local args = {
            __type__ = 'ConstructorDefinition',
            audited = false,
            class = cd,
            scope = constructorDefinition.scope or 'package',
            parameters = constructorDefinition.parameters or {},
            func = func
        };

        if args.parameters then
            if type(args.parameters) ~= 'table' or not isArray(args.parameters) then
                error(
                    string.format(
                        '%s property "parameters" is not a ParameterDefinition[]. {type=%s, value=%s}',
                        errHeader,
                        LVM.type.getType(args.parameters),
                        anyToString(args.parameters)
                    ),
                    2
                );
            end

            -- Convert any simplified type declarations.
            local paramLen = #args.parameters;
            if paramLen then
                for i = 1, paramLen do
                    local param = args.parameters[i];

                    -- Validate parameter name.
                    if not param.name then
                        error(
                            string.format(
                                '%s Parameter #%i doesn\'t have a defined name string.',
                                errHeader,
                                i
                            ), 2
                        );
                    elseif param.name == '' then
                        error(
                            string.format(
                                '%s Parameter #%i has an empty name string.',
                                errHeader,
                                i
                            ),
                            2
                        );
                    end

                    -- Validate parameter type(s).
                    if not param.type and not param.types then
                        error(
                            string.format(
                                '%s Parameter #%i doesn\'t have a defined type string or types string[]. (name = %s)',
                                errHeader,
                                i,
                                param.name
                            ),
                            2
                        );
                    else
                        if param.type and not param.types then
                            param.types = { param.type };
                            --- @diagnostic disable-next-line
                            param.type = nil;
                        end
                    end
                end
            end
        else
            args.parameters = {};
        end

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

        table.insert(self.declaredConstructors, args);

        return args;
    end

    --- @param args any[]
    ---
    --- @return ConstructorDefinition|nil constructorDefinition
    function cd:getConstructor(args)
        local cons = self:getDeclaredConstructor(args);
        if not cons and self.superClass then
            cons = self.superClass:getConstructor(args);
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

    --- @param methodDefinition MethodDefinitionParameter
    --- @param func function
    function cd:addMethod(methodDefinition, func)
        -- Friendly check for implementation.
        if not self or type(methodDefinition) == 'function' then
            error(
                'Improper method call. (Not instanced) Use MyClass:addMethod() instead of MyClass.addMethod()',
                2
            );
        end

        local errHeader = string.format('Class(%s):addMethod():', cd.name);

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

        local lineStart, lineStop = DebugUtils.getFuncRange(func);

        --- @type MethodDefinition
        local args = {
            __type__ = 'MethodDefinition',
            audited = false,
            class = cd,
            scope = methodDefinition.scope or 'package',
            static = methodDefinition.static or false,
            final = methodDefinition.final or false,
            parameters = methodDefinition.parameters or {},
            name = methodDefinition.name,
            returns = types,
            override = false,
            super = nil,
            func = func,
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

    function cd:compileMethods()
        debugf(LVM.debug.method, '%s Compiling method(s)..', self.printHeader);

        --- @type table<string, MethodDefinition[]>
        self.methods = {};

        local methodNames = LVM.method.getMethodNames(cd);
        for i = 1, #methodNames do
            self:compileMethod(methodNames[i]);
        end

        local keysCount = 0;
        for _, _ in pairs(self.methods) do
            keysCount = keysCount + 1;
        end

        debugf(LVM.debug.method, '%s Compiled %i method(s).', self.printHeader, keysCount);
    end

    function cd:compileMethod(name)
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
        if not cd.superClass.methods[name] then
            debugf(LVM.debug.method, '%s \tUsing class declaration array: %s', self.printHeader, debugName);
            self.methods[name] = LVMUtils.copyArray(decMethods);
            return;
        end

        local methods = LVMUtils.copyArray(cd.superClass.methods[name]);

        if decMethods then
            for i = 1, #decMethods do
                local decMethod = decMethods[i];

                local isOverride = false;

                -- Go through each super-class method.
                for j = 1, #methods do
                    local method = methods[j];

                    if LVM.parameter.areCompatable(decMethod.parameters, method.parameters) then
                        debugf(LVM.debug.method, '%s \t\t@override detected: %s', self.printHeader, debugName);
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

    --- Attempts to resolve a MethodDefinition in the ClassDefinition. If the method isn't defined in the class, nil
    --- is returned.
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
    function cd:getDeclaredMethod(name, args)
        local argsLen = #args;
        local methods = cd.declaredMethods[name];

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

    --- @return LVMClassDefinition class
    function cd:finalize()
        local errHeader = string.format('Class(%s):finalize():', cd.path);

        if self.lock then
            errorf(2, '%s Cannot finalize. (Class is already finalized!)', errHeader);
        elseif cd.superClass and (cd.superClass.__type__ == 'ClassDefinition' and not cd.superClass.lock) then
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
            self.__middleMethods[name] = LVM.method.createMiddleMethod(cd, name, methods);
        end

        local mt = getmetatable(cd) or {};
        local __properties = {};
        for k, v in pairs(cd) do __properties[k] = v end
        mt.__metatable = false;
        mt.__index = __properties;
        mt.__tostring = function() return 'Class ' .. cd.path end

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

            -- Inner class invocation.
            if cd.children[field] then
                if LVM.isOutside() then
                    errorf(2, 'Cannot set inner class explicitly. Use the API.');
                end

                print('setting inner-class: ', field, tostring(value));
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
        CLASS_DEFS[cd.path] = cd;

        -- Set class as child.
        if cd.superClass then
            table.insert(cd.superClass.subClasses, cd);
        end

        --- Set the class to be accessable from a global package reference.
        LVM.flags.allowPackageStructModifications = true;
        LVM.package.addToPackageStruct(cd);
        LVM.flags.allowPackageStructModifications = false;

        -- Add a reference for global package and static code.
        if enclosingClass then
            LVM.stepIn();
            enclosingClass[cd.name] = cd;
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

    --- @param class LVMClassDefinition
    ---
    --- @return boolean
    function cd:isSuperClass(class)
        local next = self.superClass;
        while next do
            if next == class then return true end
            next = next.superClass;
        end
        return false;
    end

    --- (Handles recursively going through sub-classes to see if a class is a sub-class)
    ---
    --- @param subClass LVMClassDefinition
    --- @param classToEval LVMClassDefinition
    ---
    --- @return boolean result True if the class to evaluate is a super-class of the subClass.
    local function __recurseSubClass(subClass, classToEval)
        local subLen = #cd.subClasses;
        for i = 1, subLen do
            local next = cd.subClasses[i];
            if next:isAssignableFromType(classToEval) or __recurseSubClass(next, classToEval) then
                return true;
            end
        end
        return false;
    end

    --- @param class LVMClassDefinition The class to evaulate.
    ---
    --- @return boolean result True if the class to evaluate is a super-class of the subClass.
    function cd:isSubClass(class)
        if __recurseSubClass(cd, class) then
            return true;
        end
        return false;
    end

    --- @param class LVMClassDefinition
    ---
    --- @return boolean
    function cd:isAssignableFromType(class)
        -- TODO: Implement interfaces.
        return self == class or self:isSuperClass(class);
    end

    return cd;
end

return API;
