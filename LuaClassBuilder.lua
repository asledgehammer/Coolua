---[[
--- @author asledgehammer, JabDoesThings 2025
---]]

local dump = require 'dump';

local LVM = require 'LVM';
local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;
local debugf = LVMUtils.debugf;
local isArray = LVMUtils.isArray;

local public = 'public';
local protected = 'protected';
local private = 'private';
local abstract = 'abstract';
local final = 'final';
local default = 'default';
local void = 'void';

--- @class FieldProperties
--- @field type string
--- @field types string[]
--- @field value any

--- @param struct table
local function compileFlags(struct, appliedStruct)
    local flags = struct.flags;

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
            appliedStruct[flags[i]] = true;
        end
    end

    -- (Default scope)
    if not appliedStruct.scope then
        appliedStruct.scope = 'package';
    end

    appliedStruct.flags = nil;
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
    for i = 1, #body do
        local entry = body[i];
        if type(entry) == 'table' then
            if not entry.__type__ then
                errorf(2, 'Entry #%i is not a struct. {value = %s}',
                    i, dump.any(entry)
                );
            end
            -- Set all valid bodies as static.
            if entry.__type__ == 'FieldTable' then
                table.insert(entry.flags, 'static');
            elseif entry.__type__ == 'MethodTable' then
                table.insert(entry.flags, 'static');
            elseif entry.__type__ == 'ClassTable' then
                table.insert(entry.flags, 'static');
            elseif entry.__type__ == 'InterfaceTable' then
                table.insert(entry.flags, 'static');
            elseif entry.__type__ == 'EnumTable' then
                table.insert(entry.flags, 'static');
            else
                errorf(2, 'Entry #%i is an unknown struct. {type = %s, value = %s}',
                    i, entry.__type__, dump.any(entry)
                )
            end
        end
    end

    return {
        __type__ = 'StaticTable',
        body = body
    };
end

-- MARK: - Class

--- @generic T: ClassDefinition
---
--- @return T, table
local mt_class_body = function(self, ...)
    local args = { ... };
    for i = 1, #args do
        local entry = args[i];

        for _, arg in pairs(entry) do
            if arg.__type__ == 'ExtendsTable' then
                if self.extends then
                    error('Cannot redefine class extensions.', 2);
                end
                self.extends = arg.value;
            elseif arg.__type__ == 'ImplementsTable' then
                if self.implements then
                    error('Cannot redefine class implementations.', 2);
                end
                self.implements = arg.value;
            elseif arg.__type__ == 'FieldTable' then
                self.fields[arg.name] = arg;
            elseif arg.__type__ == 'MethodTable' then
                self.methods[arg.name] = arg;
            elseif arg.__type__ == 'ConstructorTable' then
                table.insert(self.constructors, arg);
            elseif arg.__type__ == 'StaticTable' then
                for j = 1, #arg.body do
                    local staticArg = arg.body[j];

                    if staticArg.__type__ == 'StaticTable' then
                        error('Cannot nest static blocks.', 2);
                    elseif staticArg.__type__ == 'FieldTable' then
                        self.static.fields[staticArg.name] = staticArg;
                    elseif staticArg.__type__ == 'MethodTable' then
                        self.static.methods[staticArg.name] = staticArg;
                    end
                end
            else
                error('Unknown type: ' .. tostring(arg.__type__), 2);
            end
        end
    end

    -- Build the class arguments. --

    if not self.name then
        errorf(2, 'Class doesn\'t have a name!');
    end

    --- @type ClassStructDefinitionParameter
    local clsArgs = {
        name = self.name,
        extends = self.extends,
    };

    -- Build class flags.
    compileFlags(self, clsArgs);

    local cls = LVM.class.newClass(clsArgs);

    -- Build fields.
    for name, field in pairs(self.fields) do
        compileFlags(field, field);
        cls:addField(field);
    end

    -- Build constructors.
    local constructorLen = #self.constructors;
    if constructorLen ~= 0 then
        for i = 1, constructorLen do
            local consArgs = self.constructors[i];
            compileFlags(consArgs, consArgs);
            cls:addConstructor(consArgs);
        end
    end

    -- Build methods.
    for name, method in pairs(self.methods) do
        compileFlags(method, method);
        local md;
        if method.abstract then
            cls:addAbstractMethod(method);
        else
            cls:addMethod(method);
        end
    end

    -- Build static field(s).
    for name, field in pairs(self.static.fields) do
        cls:addStaticField(field);
    end

    -- Build static method(s).
    for name, method in pairs(self.static.methods) do
        cls:addStaticMethod(method);
    end

    -- TODO: Add inner classes.
    -- TODO: Add inner interfaces.
    -- TODO: Add inner enums.

    cls:finalize();

    debugf(LVM.debug.builder, '[BUILDER] :: Built class: %s', tostring(cls));

    return cls, self;
end;

local mt_class = {
    --- @generic T: ClassDefinition
    __call = function(self, ...)
        local args = { ... };
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

--- @generic T: ClassDefinition
--- @param name string
---
--- @return T
local function class(name)
    return setmetatable({
        __type__ = 'ClassTable',
        name = name,
        flags = {},

        fields = {},
        methods = {},

        static = {
            fields = {},
            methods = {},
        },

        constructors = {},
    }, mt_class);
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
                            compileFlags(v2, self.get);
                        end
                        self.get.body = v2.body;
                    elseif v2.__type__ == 'SetterTable' then
                        self.set = {};
                        if v2.flags then
                            compileFlags(v2, self.set);
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
                            v2.__type__, dump.any(v2)
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
        for i = 1, #args do
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
--- @return table
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
            if not isArray(paramDef) then
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
                        print(dump.any(subParam));
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
                    i, dump.any(arg)
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
                    i, arg.__type__, dump.any(arg)
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
end

local mt_method_body = function(self, args)
    processMethodArgs(self, args);
    return self;
end;

local mt_method = {
    __call = function(self, ...)
        local args = { ... };
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
--- @return table
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

local mt_constructor = {
    __call = function(self, args)
        for k, v in pairs(args) do
            if k == 'body' then
                local tv = type(v);
                if tv ~= 'function' then
                    errorf(2, 'Property "body" of constructor is not a function. {type = %s, value = %s}',
                        type(v),
                        dump.any(v)
                    );
                end
                self.body = v;
            elseif k == 'super' then
                local tv = type(v);
                if tv ~= 'function' then
                    errorf(2, 'Property "super" of constructor is not a function. {type = %s, value = %s}',
                        type(v),
                        dump.any(v)
                    );
                end
                self.super = v;
            elseif type(k) == 'string' then
                errorf(2, 'Unknown property of constructor: %s {type = %s, value = %s}',
                    k,
                    type(v),
                    dump.any(v)
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
                        targ, dump.any(arg)
                    );
                end
                -- Apply parameters.
                if arg.__type__ == 'ParametersTable' then
                    self.parameters = arg;
                else
                    errorf(2, 'Unknown Table entry for constructor. {type = %s, value = %s}',
                        arg.__type__, dump.any(arg)
                    );
                end
            else
                errorf(2, 'Table entry #%i for constructor is unknown. {type = %s, value = %s}',
                    i,
                    targ, dump.any(arg)
                );
            end
        end

        return setmetatable(self, {
            -- __call = mt_property_body,
            __tostring = mt_tostring
        });
    end,
    __tostring = mt_tostring
};

--- @return table
local function constructor(...)
    local flags = { ... };
    return setmetatable({
        __type__ = 'ConstructorTable',
        flags = flags,
    }, mt_constructor);
end

-- MARK: - Extends

--- @param cls ClassStructDefinition|Class|string
local function extends(cls)
    return {
        __type__ = 'ExtendsTable',
        value = cls
    };
end

-- MARK: - Implements

--- @param ... InterfaceStructDefinition
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
    class = class,
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
    default = default
};
