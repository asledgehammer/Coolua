---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

require 'LuaPlus';

local PrintPlus = require 'PrintPlus';
local errorf = PrintPlus.errorf;
local debugf = PrintPlus.debugf;

local dump = require 'dump'.any;

local LVM = require 'LVM';

local isArray = require 'LVMUtils'.isArray;

--- @type PublicFlag Structs with this flag are accessible to everything.
local public = 'public';
--- @type ProtectedFlag
local protected = 'protected';
--- @type PrivateFlag
local private = 'private';
--- @type AbstractFlag
local abstract = 'abstract';
--- @type FinalFlag
local final = 'final';
--- @type VoidType
local void = 'void';

-- MARK: - build

--- @type function, function, function
local buildClass, buildInterface, buildFlags;

--- @param self table
--- @param enclosingStruct StructDefinition?
---
--- @return ClassStructDefinition
buildClass = function(self, enclosingStruct)
    -- Build the class arguments. --

    if not self.name then
        errorf(2, 'Class doesn\'t have a name!');
    end

    local clsArgs = {
        name = self.name,
        extends = self.extends,
        implements = self.implements
    };

    -- Build class flags.
    buildFlags(self, clsArgs);

    local cls = LVM.class.newClass(clsArgs, enclosingStruct);

    -- Build constructors.
    if self.constructors then
        local constructorLen = #self.constructors;
        if constructorLen ~= 0 then
            for i = 1, constructorLen do
                local consArgs = self.constructors[i];
                buildFlags(consArgs, consArgs);
                cls:addConstructor(consArgs);
            end
        end
    end

    if self.instanced then
        -- Add instanced class(es).
        if self.instanced.classes then
            for name, innerCls in pairs(self.instanced.classes) do
                innerCls.static = false;
                cls:addInstanceStruct(innerCls);
            end
        end

        -- Add instanced interface(s).
        if self.instanced.interfaces then
            for name, innerInterface in pairs(self.instanced.interfaces) do
                innerInterface.static = false;
                cls:addInstanceStruct(innerInterface);
            end
        end

        -- Build instanced field(s).
        if self.instanced.fields then
            for name, field in pairs(self.instanced.fields) do
                buildFlags(field, field);
                cls:addField(field);
            end
        end

        -- Build instanced method(s).
        if self.instanced.methods then
            for name, method in pairs(self.instanced.methods) do
                buildFlags(method, method);
                if method.abstract then
                    cls:addAbstractMethod(method);
                else
                    cls:addMethod(method);
                end
            end
        end
    end

    if self.static then
        -- Build static class(es).
        if self.static.classes then
            for name, innerCls in pairs(self.static.classes) do
                if innerCls.__type__ == 'ClassTable' then
                    buildClass(innerCls, cls);
                elseif innerCls.__type__ == 'ClassStructDefinition' then
                    cls:addStaticStruct(innerCls);
                    -- innerCls:setOuterStruct(cls);
                end
            end
        end

        -- Build static interface(s).
        if self.static.interfaces then
            for name, innerInterface in pairs(self.static.interfaces) do
                if innerInterface.__type__ == 'InterfaceTable' then
                    buildInterface(innerInterface, cls);
                elseif innerInterface.__type__ == 'InterfaceStructDefinition' then
                    cls:addStaticStruct(innerInterface);
                    -- innerInterface:setOuterStruct(cls);
                end
            end
        end

        -- Build static field(s).
        if self.static.fields then
            for name, field in pairs(self.static.fields) do
                buildFlags(field, field);
                field.static = true;
                cls:addStaticField(field);
            end
        end

        -- Build static method(s).
        if self.static.methods then
            for name, method in pairs(self.static.methods) do
                buildFlags(method, method);
                method.static = true;
                cls:addStaticMethod(method);
            end
        end
    end

    debugf(LVM.debug.builder, '[BUILDER] :: Built class: %s', tostring(cls));

    return cls;
end

--- @param self table
--- @param outerStruct StructDefinition
---
--- @return InterfaceStructDefinition interfaceDef, any table
local function buildInterface(self, outerStruct)
    if not self.name then
        errorf(2, 'Interface doesn\'t have a name!');
    end

    --- @type InterfaceStructDefinitionParameter
    local intArgs = {
        name = self.name,
        extends = self.extends,
    };

    -- Build class flags.
    buildFlags(self, intArgs);

    local interface = LVM.interface.newInterface(intArgs, outerStruct);

    -- Build methods.
    for name, method in pairs(self.methods) do
        buildFlags(method, method, public);

        -- Check flags.
        if method.static then
            errorf(2, 'Invalid flag "static" for interface method: %s (Define this in a static block)', name);
        elseif method.abstract then
            errorf(2, 'Invalid flag "abstract" for interface method: %s', name);
        elseif method.default then
            errorf(2,
                'Invalid flag "default" for interface method: %s (For default interface method behavior, don\'t define a body)',
                name
            );
        end

        -- Set default flag based off of absense of body function.
        if not method.body then
            method.default = true;
        end

        -- print('adding method: ', name, dump(method, {pretty = true, label = true}));

        interface:addMethod(method);
    end

    if self.static then
        -- Build static class(es).
        if self.static.classes then
            for name, innerCls in pairs(self.static.classes) do
                if innerCls.__type__ == 'ClassTable' then
                    buildClass(innerCls, interface);
                elseif innerCls.__type__ == 'ClassStructDefinition' then
                    interface:addStaticStruct(innerCls);
                end
            end
        end

        -- Build static interface(s).
        if self.static.interfaces then
            for name, innerInterface in pairs(self.static.interfaces) do
                if innerInterface.__type__ == 'InterfaceTable' then
                    buildInterface(innerInterface, interface);
                elseif innerInterface.__type__ == 'InterfaceStructDefinition' then
                    interface:addStaticStruct(innerInterface);
                end
            end
        end

        -- Build static field(s).
        for name, field in pairs(self.static.fields) do
            buildFlags(field, field, public);

            -- Check flags.
            if field.static then
                errorf(2,
                    'Invalid flag "static" for interface field: %s. (It\'s in a static block so this isn\'t needed)',
                    name
                );
            elseif field.final then
                errorf(2, 'Invalid flag "final" for interface field: %s. (All interface fields are constants)', name);
            elseif field.scope == 'public' then
                errorf(2, 'Invalid flag "public" for interface field: %s. (All interface fields are public)', name);
            end

            -- All interface fields requires a value.
            if not field.value then
                errorf(2, 'No default value for interface field: %s.', name);
            end

            field.scope = 'public';
            field.static = true;
            field.final = true;

            interface:addStaticField(field);
        end

        -- Build static method(s).
        for name, method in pairs(self.static.methods) do
            if not method.body then
                errorf(2, 'body function missing for static interface method. (Static methods must have a body.)', 2);
            end

            buildFlags(method, method);

            -- Check flags.
            if method.static then
                errorf(2,
                    'Invalid flag "static" for interface method: %s. (It\'s in a static block so this isn\'t needed.)',
                    name
                );
            elseif method.abstract then
                errorf(2, 'Invalid flag "abstract" for interface method: %s (Interface methods cannot be abstract.)',
                    name
                );
            elseif method.default then
                errorf(2,
                    'Invalid flag "default" for static interface method: %s (Static interface methods must have a body.)',
                    name
                );
            end

            method.static = true;
            method.final = true;

            interface:addStaticMethod(method);
        end
    end

    -- TODO: Add inner classes.
    -- TODO: Add inner interfaces.
    -- TODO: Add inner enums.

    -- interface:finalize();

    debugf(LVM.debug.builder, '[BUILDER] :: Built interface: %s', tostring(interface));

    return interface, self;
end

--- @param struct table
--- @param appliedStruct table
--- @param defaultScope string? (Default: 'package')
buildFlags = function(struct, appliedStruct, defaultScope)
    local flags = struct.flags;
    defaultScope = defaultScope or 'package';

    -- if not flags then
    --     appliedStruct.flags = {};
    --     return;
    -- end

    for i = 1, #flags do
        local flag = flags[i];

        -- If scope, apply as such. Check if defined already.
        if flag == 'public' or flag == 'protected' or flag == 'private' then
            if appliedStruct.scope then
                errorf(2, 'Scope is already provided and cannot be redefined: %s (Given: %s)',
                    appliedStruct.scope, flag
                );
            end
            appliedStruct.scope = flag;
        elseif flag == 'static' then
            errorf(2, 'Static flags cannot be assigned. They must be defined in a "static {}" block.');
        else
            appliedStruct[flag] = true;
        end
    end

    if not appliedStruct.scope then
        appliedStruct.scope = defaultScope;
    end
end

--- @param e ClassStructDefinition|Class|table|string
local function processTypes(e)
    local types = {};

    local te = type(e);
    if te == 'string' then
        -- This is a one-type definition.
        table.insert(types, e);
    elseif te == 'table' then
        -- Cannot use dictionaries to define types.
        if not isArray(e) then
            error('Return types is not a table-array.', 2);
        end
        -- Copy contents into new array.
        for i = 1, #e do
            table.insert(types, e[i]);
        end
    elseif e.__type__ then
        if e.__type__ == 'ClassStructDefinition' then
            --- @cast e ClassStructDefinition
            table.insert(types, e.path);
        elseif e.getDefinition then
            -- Convert clas to its LVM definition and grab its path.
            table.insert(types, e:getDefinition().path);
        end
    end

    return types;
end

-- MARK: - meta

local mt_property_body = function(self, ...)
    local args = { ... };
    for i = 1, #args do
        local arg = args[i];
        for _, v2 in pairs(arg) do
            table.insert(self.body, v2);
        end
    end
    return self;
end;

local mt_tostring = function(self)
    return self.__type__;
end

local mt_property = {
    __call = function(self, ...)
        local args = { ... };
        for i = 1, #args do
            table.insert(self.flags, args[i]);
        end
        return setmetatable(self, {
            __call = mt_property_body,
            __tostring = mt_tostring
        });
    end,
    __tostring = mt_tostring
};

-- MARK: - Static

--- @param body table
local function static(body)
    local classes = {};
    local interfaces = {};
    local methods = {};
    local fields = {};
    for i = 1, #body do
        local entry = body[i];
        if type(entry) == 'table' then
            if not entry.__type__ then
                errorf(2, 'Entry #%i is not a struct. {value = %s}',
                    i, dump(entry)
                );
            end
            -- Set all valid bodies as static.
            if entry.__type__ == 'FieldTable' then
                fields[entry.name] = entry;
            elseif entry.__type__ == 'MethodTable' then
                methods[entry.name] = entry;
            elseif entry.__type__ == 'ClassTable' then
                classes[entry.name] = entry;
            elseif entry.__type__ == 'ClassStructDefinition' then
                classes[entry.name] = entry;
            elseif entry.__type__ == 'InterfaceStructDefinition' then
                interfaces[entry.name] = entry;
            else
                errorf(2, 'Entry #%i is an unknown struct. {type = %s, value = %s}',
                    i, entry.__type__, dump(entry)
                )
            end
        end
    end

    return {
        __type__ = 'StaticTable',
        classes = classes,
        interfaces = interfaces,
        fields = fields,
        methods = methods,
    };
end

-- MARK: - Class

--- @param self any
--- @param ... ClassTableBody
---
--- @return ClassStructDefinition
local mt_class_body = function(self, ...)
    local args = { ... };
    for i = 1, #args do
        local entry = args[i];

        for _, arg in pairs(entry) do
            if arg.__type__ == 'ExtendsTable' then
                --- @cast arg ExtendsTable
                if self.extends then
                    error('Cannot redefine class extensions.', 2);
                end
                self.extends = arg.value;
            elseif arg.__type__ == 'ImplementsTable' then
                --- @cast arg ImplementsTable
                if self.implements then
                    error('Cannot redefine class implementations.', 2);
                end
                self.implements = arg.value;
            elseif arg.__type__ == 'ClassStructDefinition' then
                --- @cast arg ClassStructDefinition
                self.instanced.classes[arg.name] = arg;
            elseif arg.__type__ == 'InterfaceStructDefinition' then
                --- @cast arg InterfaceStructDefinition
                self.instanced.interfaces[arg.name] = arg;
            elseif arg.__type__ == 'FieldTable' then
                --- @cast arg FieldTable
                self.instanced.fields[arg.name] = arg;
            elseif arg.__type__ == 'MethodTable' then
                --- @cast arg MethodTable
                self.instanced.methods[arg.name] = arg;
            elseif arg.__type__ == 'ConstructorTable' then
                table.insert(self.constructors, arg);
            elseif arg.__type__ == 'StaticTable' then
                --- @cast arg StaticTable
                -- Static inner class(es)
                for name, class in pairs(arg.classes) do
                    self.static.classes[name] = class;
                end
                -- Static inner interface(s)
                for name, interface in pairs(arg.interfaces) do
                    self.static.interfaces[name] = interface;
                end
                -- Static field(s)
                for name, field in pairs(arg.fields) do
                    self.static.fields[name] = field;
                end
                -- Static method(s)
                for name, method in pairs(arg.methods) do
                    self.static.methods[name] = method;
                end
            else
                error('Unknown type: ' .. tostring(arg.__type__), 2);
            end
        end
    end

    return buildClass(self);
end;

--- @type fun(flagsOrBody: ModifierFlag[]|TableBody)
local mt_class = {
    __call = function(self, ...)
        local args = { ... };
        local argLen = #args;

        -- This isn't a flag-argument. Move to body definition.
        if argLen == 1 and type(args[1]) == 'table' and isArray(args[1]) then
            mt_class_body(self, ...);
            return;
        end

        for i = 1, #args do
            table.insert(self.flags, args[i]);
        end
        return setmetatable(self, {
            __call = mt_class_body,
            __tostring = mt_tostring
        });
    end,
    __tostring = mt_tostring
};

--- @param name string
---
--- @return ClassStructDefinition
local function class(name)
    local t = {
        __type__ = 'ClassTable',
        name = name,
        flags = {},
        instanced = {
            classes = {},
            interfaces = {},
            fields = {},
            methods = {},
        },
        static = {
            classes = {},
            interfaces = {},
            fields = {},
            methods = {},
        },
        constructors = {},
    };
    return setmetatable(t, mt_class);
end

-- MARK: - Interface

--- @return InterfaceStructDefinition
local mt_interface_body = function(self, ...)
    local args = { ... };
    for i = 1, #args do
        local entry = args[i];

        for _, arg in pairs(entry) do
            -- print('[BUILDER][Interface] :: Parsing entry: ' .. dump(entry, { label = true, pretty = true }));

            if arg.__type__ == 'ExtendsTable' then
                if self.extends then
                    error('Cannot redefine interface extensions.', 2);
                end
                self.extends = arg.value;
            elseif arg.__type__ == 'MethodTable' then
                self.methods[arg.name] = arg;
            elseif arg.__type__ == 'StaticTable' then
                -- Static field(s)
                for k, method in pairs(arg.fields) do
                    self.static.fields[k] = method;
                end
                -- Static method(s)
                for k, method in pairs(arg.methods) do
                    self.static.methods[k] = method;
                end
                -- Static inner class(es)
                for k, method in pairs(arg.classes) do
                    self.static.classes[k] = method;
                end
                -- Static inner interface(s)
                for k, method in pairs(arg.interfaces) do
                    self.static.interfaces[k] = method;
                end
            else
                error('Unknown type: ' .. tostring(arg.__type__), 2);
            end
        end
    end

    -- Build the interface arguments. --

    return buildInterface(self, self.extends);
end;

local mt_interface = {
    --- @param ... ModifierFlag
    __call = function(self, ...)
        local args = { ... };
        local argLen = #args;

        -- This isn't a flag-argument. Move to body definition.
        if argLen == 1 and type(args[1]) == 'table' and isArray(args[1]) then
            mt_interface_body(self, ...);
            return;
        end

        for i = 1, #args do
            table.insert(self.flags, args[i]);
        end
        return setmetatable(self, {
            __call = mt_interface_body,
            __tostring = mt_tostring
        });
    end,
    __tostring = mt_tostring
};

--- @param name string
---
--- @return InterfaceStructDefinition
local function interface(name)
    return setmetatable({
        __type__ = 'InterfaceTable',
        name = name,
        flags = {},

        methods = {},

        static = {
            fields = {},
            methods = {},
        },
    }, mt_interface);
end

-- MARK: - Field

local mt_field_body = function(self, ...)
    local args = { ... };
    for i = 1, #args do
        local arg = args[i];
        for _, v2 in pairs(arg) do
            local tv2 = type(v2);
            if tv2 == 'table' then
                if v2.__type__ then
                    if v2.__type__ == 'GetterTable' then
                        self.get = {};
                        if v2.flags then
                            buildFlags(v2, self.get);
                        end
                        self.get.body = v2.body;
                    elseif v2.__type__ == 'SetterTable' then
                        self.set = {};
                        if v2.flags then
                            buildFlags(v2, self.set);
                        end
                        self.set.body = v2.body;
                    elseif v2.__type__ == 'PropertiesTable' then
                        -- TODO: Undo lazy-passthrough of types without audit. -Jab, 7/6/2025
                        if v2.value.type then
                            self.type = v2.value.type;
                        elseif v2.value.types then
                            self.types = v2.value.types;
                        end
                        -- TODO: Undo lazy-passthrough of values without audit. -Jab, 7/6/2025
                        if v2.value.value then
                            self.value = v2.value.value;
                        end
                    else
                        errorf(2, 'Unknown struct in field: %s {value = %s}',
                            v2.__type__, dump(v2)
                        );
                    end
                else
                    if isArray(v2) then
                        error('idk array', 3)
                    else
                        -- Extract from table.
                        for k3, v3 in pairs(v2) do
                            self[k3] = v3;
                        end
                    end
                end
            else
                error('Unknown field property type: ' .. tv2);
            end
        end
    end
    return self;
end;

local mt_field = {
    __call = function(self, ...)
        local args = { ... };
        local argLen = #args;

        -- Bypass the flags if this condition is met.
        if argLen == 1 and isArray(args[1]) then
            return mt_field_body(self, args[1]);
        end

        for i = 1, argLen do
            table.insert(self.flags, args[i]);
        end
        return setmetatable(self, {
            __call = mt_field_body,
            __tostring = mt_tostring
        });
    end,
    __tostring = mt_tostring
};

--- @param name string
---
--- @return FieldTable
local function field(name)
    return setmetatable({
        __type__ = 'FieldTable',
        name = name,
        flags = {},
    }, mt_field);
end

-- MARK: - Get / Set

local mt_getset = {
    __call = function(self, ...)
        local args = { ... };
        for i = 1, #args do
            local t = args[i];
            if type(t) ~= 'table' or not isArray(t) then
                error('getter/setter body is not a table-array', 2);
            elseif #t > 1 then
                error('geter/setter body can only contain one function', 2);
            end

            local func = t[1];

            -- Validate the function argument.
            if self.body then
                error('Cannot redefine body function for getter/setter.', 2);
            elseif type(func) ~= 'function' then
                errorf(2, 'Body argument for getter/setter is not a function. {type = %s, value = %s}',
                    type(func), tostring(func)
                );
            end

            self.body = func;
        end
        return setmetatable(self, {
            __call = nil,
            __tostring = mt_tostring
        });
    end,
    __tostring = mt_tostring
};

--- @param ... string|table Flags
local function get(...)
    return setmetatable({
        __type__ = 'GetterTable',
        flags = { ... },
    }, mt_getset);
end

--- @param ... string|table Flags
local function set(...)
    return setmetatable({
        __type__ = 'SetterTable',
        flags = { ... },
    }, mt_getset);
end

-- MARK: - Parameters

--- @param ... string[]|{name: string?, type: (string|table)?, types: (string|table)[]?}[]
local function parameters(...)
    local args = { ... };
    local argsLen = #args;

    local t = {
        __type__ = 'ParametersTable',
        value = {}
    };

    if argsLen == 0 then
        return t;
    end

    for i = 1, argsLen do
        local paramDef = args[i];
        local tParamDef = type(paramDef);
        if tParamDef == 'string' then
            if paramDef == '' then
                errorf(2, 'First parameter string is empty.');
            end
            -- One-arg array type.
            local name = 'param_1';
            table.insert(t.value, { name = name, types = { paramDef } });
        elseif tParamDef == 'table' then
            if type(paramDef) ~= 'table' or not isArray(paramDef) then
                errorf(2, 'Parameters is not an array.');
            end

            for j = 1, #paramDef do
                local subParam = paramDef[j];
                local tSubParam = type(subParam);

                if tSubParam == 'string' then
                    if subParam == '' then
                        errorf(2, 'First parameter string is empty.');
                    end
                    -- One-arg array type.
                    local name = string.format('param_%i', j);
                    table.insert(t.value, { name = name, types = { subParam } });
                elseif tParamDef == 'table' then
                    if isArray(subParam) then
                        errorf(2, 'Parameter #%i cannot be an array.', j);
                    end

                    local name = subParam.name or string.format('param_%i', j);
                    local type = subParam.type;
                    local types = subParam.types;

                    if types and type then
                        errorf(2, 'Parameter #%i cannot define both "type" and "types".', j);
                    elseif not type and types then
                        errorf(2, 'Parameter #%i has no defined types.', j);
                    elseif type then
                        types = { type };
                    elseif types then
                        if not isArray(types) then
                            errorf(2, "Parameter #%i is not an array.", j);
                        end
                    end

                    table.insert(t.value, { name = name, types = types });
                end
            end

            -- Process array here.
        else
            errorf(2, 'Parameters is not a proper definition.');
        end
    end

    return t;
end

-- MARK: - Returns

--- @param e ClassStructDefinition|Class|table|string
local function returns(e)
    return {
        __type__ = 'ReturnsTable',
        value = processTypes(e)
    };
end

-- MARK: - Method

local function processMethodArgs(self, args)
    for i = 1, #args do
        local arg = args[i];
        local targ = type(arg);

        if targ == 'table' then
            if not arg.__type__ then
                errorf(2, 'Property #%i in method is not a struct. {value = %s}',
                    i, dump(arg)
                );
            end

            if arg.__type__ == 'ReturnsTable' then
                self.returns = arg.value;
            elseif arg.__type__ == 'PropertiesTable' then
                -- TODO: Implement method properties. - Jab
                error('Properties block in methods is not supported.', 2);
            elseif arg.__type__ == 'ParametersTable' then
                self.parameters = arg.value;
            else
                errorf(2, 'Property #%i is an unknown struct: %s {type = %s, value = %s}',
                    i, arg.__type__, dump(arg)
                );
            end
        elseif targ == 'function' then
            if self.body then
                error('Cannot define method body more than once.', 2);
            end
            self.body = arg;
        end

        -- for _, v2 in pairs(arg) do
        --     table.insert(self.body, v2);
        -- end
    end

    if not self.parameters then
        self.parameters = {};
    end

    if not self.returns then
        self.returns = { void };
    end

    return self;
end

local mt_method_body = function(self, args)
    return processMethodArgs(self, args);
end;

local mt_method = {
    __call = function(self, ...)
        local args = { ... };
        local argLen = #args;

        -- Bypass the flags if this condition is met.
        if argLen == 1 and isArray(args[1]) then
            return processMethodArgs(self, args[1]);
        end

        -- If the method has no flags, a table is passed. Skip to the table definition.
        if argLen == 1 and type(args[1]) == 'table' then
            mt_method_body(self, args);
            return;
        end

        for i = 1, #args do
            table.insert(self.flags, args[i]);
        end
        return setmetatable(self, {
            __call = mt_method_body,
            __tostring = mt_tostring
        });
    end,
    __tostring = mt_tostring
};

local mt_method_preset = {
    __call = mt_method_body,
    __tostring = mt_tostring
};

--- @param name string
---
--- @return MethodTable
local function method(name)
    return setmetatable({
        __type__ = 'MethodTable',
        name = name,
        flags = {},
    }, mt_method);
end

--- @return function
local function getPresetMethodBody(funcName, t)
    if not isArray(t) then
        errorf(3, 'The %s definition isn\'t a function[] array.', funcName);
    else
        local tLen = #t;
        if tLen == 0 then
            errorf(2, 'The %s definition has no function.', funcName);
        elseif tLen > 1 then
            errorf(2, 'The %s definition has two or more functions.', funcName);
        end
    end

    return t[1];
end

--- @return fun(t: MethodTableBody): MethodTable
local function createMethodTemplate(name, flags, properties)
    return function(t)
        local t2 = {
            __type__ = 'MethodTable',
            name = name,
            flags = flags,
            body = getPresetMethodBody(name, t)
        };
        processMethodArgs(t2, properties);
        return setmetatable(t2, mt_method_preset);
    end
end

--- @return MethodTable
local equals = createMethodTemplate('equals', { public }, {
    parameters {
        { name = 'other', type = 'any' }
    },
    returns = 'boolean',
});

local toString = createMethodTemplate('toString', { public }, {
    parameters = {},
    returns = 'string',
});

-- MARK: - constructor

local mt_constructor_body = function(self, args)
    for k, method in pairs(args) do
        if k == 'body' then
            local tv = type(method);
            if tv ~= 'function' then
                errorf(2, 'Property "body" of constructor is not a function. {type = %s, value = %s}',
                    type(method),
                    dump(method)
                );
            end
            self.body = method;
        elseif k == 'super' then
            local tv = type(method);
            if tv ~= 'function' then
                errorf(2, 'Property "super" of constructor is not a function. {type = %s, value = %s}',
                    type(method),
                    dump(method)
                );
            end
            self.super = method;
        elseif type(k) == 'string' then
            errorf(2, 'Unknown property of constructor: %s {type = %s, value = %s}',
                k,
                type(method),
                dump(method)
            );
        end
    end

    for i = 1, #args do
        local arg = args[i];
        local targ = type(arg);

        --Enforce strict struct arguments.
        if targ == 'table' then
            if not arg.__type__ then
                errorf(2, 'Table entry for constructor is not a struct. {type = %s, value = %s}',
                    targ, dump(arg)
                );
            end
            -- Apply parameters.
            if arg.__type__ == 'ParametersTable' then
                self.parameters = arg;
            else
                errorf(2, 'Unknown Table entry for constructor. {type = %s, value = %s}',
                    arg.__type__, dump(arg)
                );
            end
        else
            errorf(2, 'Table entry #%i for constructor is unknown. {type = %s, value = %s}',
                i,
                targ, dump(arg)
            );
        end
    end

    return setmetatable(self, { __tostring = mt_tostring });
end;

local mt_constructor = {
    __call = mt_constructor_body,
    __tostring = mt_tostring
};

--- @return ConstructorTable
local function constructor(...)
    local t = {
        __type__ = 'ConstructorTable',
        flags = {}
    };

    local args = { ... };

    if args and type(args) == 'table' and isArray(args) and #args ~= 0 and type(args[1]) == 'string' then
        t.flags = args;
    end

    -- Bypass the flags if this condition is met.
    if not args or (#args == 1 and type(args[1]) == 'table') then
        if not args then
            return setmetatable(t, mt_constructor);
        else
            return mt_constructor_body(t, args[1]);
        end
    end

    return setmetatable(t, mt_constructor);
end

-- MARK: - Extends

--- @param cls StructDefinition|StructReference|Class|string
local function extends(cls)
    return {
        __type__ = 'ExtendsTable',
        value = cls
    };
end

-- MARK: - Implements

--- @param ... StructDefinition|StructReference
local function implements(...)
    return {
        __type__ = 'ImplementsTable',
        value = { ... }
    };
end

--- @generic T: table Defines the type of properties to expect in the scope.
--- @param t T
---
--- @return T t
local function properties(t)
    local t2 = { __type__ = 'PropertiesTable', value = t };
    return t2;
end

return {

    import = LVM.import,

    class = class,
    interface = interface,
    extends = extends,
    implements = implements,
    static = static,
    field = field,
    constructor = constructor,
    method = method,
    properties = properties,
    parameters = parameters,
    returns = returns,
    get = get,
    set = set,

    -- * Preset Methods * --
    equals = equals,
    toString = toString,

    -- * Element Flags * --
    private = private,
    protected = protected,
    public = public,
    final = final,
    abstract = abstract,
};
