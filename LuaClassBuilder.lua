local dump = require 'dump';

local LVM = require 'LVM';
local LVMUtils = require 'LVMUtils';
local errorf = LVMUtils.errorf;
local isArray = LVMUtils.isArray;

local Object = require 'lua/lang/Object';

local public = 'public';
local protected = 'protected';
local private = 'private';
local abstract = 'abstract';
local final = 'final';

--- @class FieldProperties
--- @field type string
--- @field types string[]
--- @field value any

local function merge(...)
    local result = {};
    for _, t in ipairs({ ... }) do
        for k, v in pairs(t) do
            result[k] = v;
        end
    end
    return result;
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

local mt_method_preset = {
    __call = mt_property_body,
    __tostring = mt_tostring
};

-- MARK: - Static

local function static(t)
    return {
        __type__ = 'StaticTable',
        body = t
    };
end

-- MARK: - Class

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
    return self;
end;

local mt_class = {
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

--- @param name string
---
--- @return table
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
                        self.get = v2;
                    elseif v2.__type__ == 'SetterTable' then
                        self.set = v2;
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

-- MARK: - Method

--- @param name string
---
--- @return table
local function method(name)
    return setmetatable({
        __type__ = 'MethodTable',
        name = name,
        flags = {},
        body = {},
    }, mt_property);
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
        local body = properties;
        body.body = getPresetMethodBody(name, t);

        return setmetatable({
            __type__ = 'MethodTable',
            name = name,
            flags = flags,
            body = body,
        }, mt_method_preset);
    end
end

local equals = createMethodTemplate('equals', { public }, {
    parameters = {
        { name = 'any', type = Object }
    },
    returns = { 'boolean' },
});

local toString = createMethodTemplate('toString', { public }, {
    parameters = {},
    returns = { 'string' },
});

-- MARK: - constructor

local mt_constructor = {
    __call = function(self, ...)
        local args = { ... };
        for i = 1, #args do
            table.insert(self.body, args[i]);
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
    return setmetatable({
        __type__ = 'ConstructorTable',
        flags = { ... },
        body = {},
    }, mt_constructor);
end

-- MARK: - Parameters

--- @param sOrT string|table
local function parameters(sOrT)

end

-- MARK: - Returns

--- @param e ClassStructDefinition|Class|table|string
local function returns(e)
    return {
        __type__ = 'ReturnsTable',
        types = processTypes(e)
    };
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
    local t2 = { __type__ = 'PropertiesTable' };
    return merge(t, t2);
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
};
